#!/usr/bin/env bash
# setup.sh — cervelAI phase 2 (guest LXC).
# Installs the tools and AI agents inside a fresh Debian 13 LXC. Run as root.
#
# Usage:
#   bash setup.sh                    # interactive — pick tools in a menu
#   dev_mode=nomenu bash setup.sh    # non-interactive, installs everything
#   dev_mode=trace,dryrun bash setup.sh
#
# Env vars:
#   CERVELAI_USER       (default: agent) — user to create
#   CERVELAI_SSH_KEY    (default: empty) — public SSH key to add
#   CERVELAI_SELECTED   (default: all)   — CSV category list for nomenu mode

set -uo pipefail
export LC_ALL=C  # deterministic output; silences perl locale warnings

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/install"
CONFIGS_DIR="${SCRIPT_DIR}/configs"

ENV_FILE_REL=".config/cervelAI/env"

DEV_MODE="${dev_mode:-}"
in_dev_mode() { [[ ",${DEV_MODE}," == *",$1,"* ]]; }

in_dev_mode trace && set -x
DRY_RUN=0; in_dev_mode dryrun && DRY_RUN=1
NO_MENU=0;  in_dev_mode nomenu  && NO_MENU=1
SETUP_ERRORS=0  # non-blocking failure counter; verdict at the end of main()

_color() { printf '\033[%sm' "$1"; }
log_info()  { printf '%s[ INFO ]%s %s\n' "$(_color '1;34')" "$(_color 0)" "$*"; }
log_ok()    { printf '%s[  OK  ]%s %s\n' "$(_color '1;32')" "$(_color 0)" "$*"; }
log_skip()  { printf '%s[ SKIP ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*"; }
log_warn()  { printf '%s[ WARN ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*" >&2; }
log_err()   { printf '%s[ ERR  ]%s %s\n' "$(_color '1;31')" "$(_color 0)" "$*" >&2; }
log_step()  { printf '\n%s━━━ %s ━━━%s\n' "$(_color '1;36')" "$*" "$(_color 0)"; }

run() {
    if (( DRY_RUN )); then
        printf '%s[DRYRUN]%s %s\n' "$(_color '1;35')" "$(_color 0)" "$*"
        return 0
    fi
    local rc=0
    "$@" || rc=$?
    if (( rc != 0 )); then
        log_warn "failed ($rc) at ${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]} : $*"
        SETUP_ERRORS=$(( SETUP_ERRORS + 1 ))
    fi
    return "$rc"
}

# Run a command without counting its failure in SETUP_ERRORS.
soft() {
    local before=$SETUP_ERRORS
    "$@"
    local rc=$?
    SETUP_ERRORS=$before
    return "$rc"
}

require_root() {
    [[ $EUID -eq 0 ]] || { log_err "must run as root"; exit 1; }
}

require_debian13() {
    [[ -r /etc/os-release ]] || { log_err "/etc/os-release missing"; exit 1; }
    . /etc/os-release
    [[ "${ID:-}" == "debian" ]] || { log_err "not Debian (ID=$ID)"; exit 1; }
    [[ "${VERSION_ID:-}" =~ ^13 ]] || log_warn "expected Debian 13, got $VERSION_ID — continuing anyway"
}

has_cmd() { command -v "$1" &>/dev/null; }
has_pkg() { dpkg -s "$1" &>/dev/null; }

apt_install() {
    local missing=()
    for p in "$@"; do has_pkg "$p" || missing+=("$p"); done
    if (( ${#missing[@]} == 0 )); then
        log_skip "apt: ${*} already installed"
        return 0
    fi
    log_info "apt install: ${missing[*]}"
    run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
}

# mise lives at /usr/local/bin/mise (system-wide, on the default PATH) so its
# npm backend and shims — which shell out to a bare `mise` — always resolve it.
# These helpers run it as the agent user so data/config land in that user's home.
_user() { printf '%s' "${CERVELAI_USER:-agent}"; }
# Run a command as the agent user. PATH carries the mise shims explicitly (the
# dotfiles that'd set it are only deployed later); GITHUB_TOKEN is preserved so
# mise's aqua/github backends authenticate past the 60-req/h rate limit.
_user_bash() {
    sudo -u "$(_user)" --preserve-env=GITHUB_TOKEN -i bash -c \
        "export PATH=\"\$HOME/.local/share/mise/shims:\$HOME/.local/bin:\$PATH\"; $*"
}

mise_present() {
    [[ -x /usr/local/bin/mise ]]
}

# mise_use <backend>:<pkg> [version] [cmd_name] — cmd_name when the binary
# differs from the package (e.g. mise_use npm:opencode-ai latest opencode).
mise_use() {
    local pkg="$1" ver="${2:-latest}" name="${3:-}"
    if ! mise_present; then
        log_warn "mise not present — skip mise_use $pkg (install runtimes first)"
        return 1
    fi
    if [[ -z "$name" ]]; then
        name="${pkg##*/}"; name="${name##*:}"
    fi
    if _user_bash "command -v $name" &>/dev/null; then
        log_skip "mise: $name already on PATH"
        return 0
    fi
    log_info "mise use -g $pkg@$ver"
    run _user_bash "mise use -g $pkg@$ver" \
        || { log_warn "mise install failed for $pkg — fallback to caller"; return 1; }
}

mise_npm() { mise_use "npm:$1" "${2:-latest}"; }
mise_aqua() { mise_use "aqua:$1" "${2:-latest}"; }

# Tests DNS + TCP via bash's /dev/tcp — curl isn't installed yet at this point.
check_connectivity() {
    local host="${1:-github.com}" port="${2:-443}"
    if (( DRY_RUN )); then
        log_skip "connectivity check (dryrun)"
        return 0
    fi
    log_info "checking connectivity to ${host}:${port}"
    if timeout 5 bash -c "exec 3<>/dev/tcp/${host}/${port}" 2>/dev/null; then
        log_ok "online"
        return 0
    fi
    log_err "no connectivity to ${host}:${port} — this script needs internet"
    log_err "  - check Proxmox bridge / DHCP"
    log_err "  - check firewall / NAT on host"
    return 1
}

while (( $# )); do
    case "$1" in
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        *) log_warn "unknown arg: $1" ;;
    esac
    shift
done

# Categories for the menu + install loop. base + runtimes are infrastructure
# (always installed); menu.sh derives its defaults from these two arrays.
ALL_CATEGORIES=(
    shell
    search
    editor
    git-tools
    agents
)
OPTIONAL_CATEGORIES=(  # pre-unchecked in the menu
    token-savers
    usage-trackers
    ide-web
    containers
    db
    http
    data
)

main() {
    local selected=() cat err_before

    require_root
    require_debian13
    check_connectivity || exit 1
    prompt_github_token

    log_step "cervelAI setup"

    if (( ! NO_MENU )); then
        if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
            log_err "interactive setup needs a TTY — not available via 'pct exec' without a pty"
            log_err "→ run via 'pct enter <CTID>', or use dev_mode=nomenu with CERVELAI_SELECTED"
            exit 1
        fi
        source_menu || { log_err "menu.sh required for interactive setup"; exit 1; }
    fi

    # base + user are prerequisites — abort the whole run if they fail.
    source_install base || { log_err "install/base.sh not found"; exit 1; }
    err_before=$SETUP_ERRORS
    install_base_all
    create_user
    if (( SETUP_ERRORS > err_before )); then
        log_err "failure during base/user — aborting (continuing would produce a broken LXC)"
        exit 1
    fi

    if (( NO_MENU )); then
        if [[ "${CERVELAI_SELECTED:-all}" == "all" ]]; then
            selected=("${ALL_CATEGORIES[@]}" "${OPTIONAL_CATEGORIES[@]}")
            : "${CERVELAI_AGENTS:=all}"
            : "${CERVELAI_EDITORS:=all}"
            : "${CERVELAI_GIT_FORGES:=all}"
            : "${CERVELAI_RUNTIMES:=all}"
            export CERVELAI_AGENTS CERVELAI_EDITORS CERVELAI_GIT_FORGES CERVELAI_RUNTIMES
        else
            IFS=',' read -r -a selected <<< "$CERVELAI_SELECTED"
        fi
        log_info "selected: ${selected[*]:-(none)}"
    else
        # Loop until the summary is confirmed — lets the user redo any selection.
        while :; do
            if menu_select selected; then
                log_info "selected: ${selected[*]:-(none)}"
                local rt_sel=()
                if menu_runtimes_select rt_sel; then
                    CERVELAI_RUNTIMES="$(IFS=,; echo "${rt_sel[*]}")"
                    export CERVELAI_RUNTIMES
                fi
                for cat in "${selected[@]}"; do
                    case "$cat" in
                        agents)
                            local ag_sel=()
                            if menu_agents_select ag_sel; then
                                CERVELAI_AGENTS="$(IFS=,; echo "${ag_sel[*]}")"
                                export CERVELAI_AGENTS
                            fi ;;
                        editor)
                            local ed_sel=()
                            if menu_editors_select ed_sel; then
                                CERVELAI_EDITORS="$(IFS=,; echo "${ed_sel[*]}")"
                                export CERVELAI_EDITORS
                            fi ;;
                        git-tools)
                            local gf_sel=()
                            if menu_git_forges_select gf_sel; then
                                CERVELAI_GIT_FORGES="$(IFS=,; echo "${gf_sel[*]}")"
                                export CERVELAI_GIT_FORGES
                            fi ;;
                        shell)
                            local sh_sel="" mx_sel=""
                            menu_shell_select sh_sel       && { CERVELAI_SHELL="$sh_sel"; export CERVELAI_SHELL; }
                            menu_multiplexer_select mx_sel && { CERVELAI_MULTIPLEXER="$mx_sel"; export CERVELAI_MULTIPLEXER; }
                            ;;
                        token-savers)
                            local ts_sel=""
                            menu_token_saver_select ts_sel && { CERVELAI_TOKEN_SAVER="$ts_sel"; export CERVELAI_TOKEN_SAVER; }
                            ;;
                    esac
                done
                menu_summary_confirm && break
                log_info "redoing selection…"
                unset CERVELAI_RUNTIMES CERVELAI_AGENTS CERVELAI_EDITORS \
                      CERVELAI_GIT_FORGES CERVELAI_SHELL CERVELAI_MULTIPLEXER \
                      CERVELAI_TOKEN_SAVER
            else
                log_warn "menu cancelled — installing nothing beyond base + mise + default runtimes"
                selected=()
                break
            fi
        done
    fi

    log_step "mise + runtimes"
    source_install runtimes
    install_runtimes_all

    # Re-order selected[] to follow the canonical category order: token-savers
    # must run AFTER agents (its hook init needs the agent binaries installed).
    # CERVELAI_SELECTED is user-supplied (nomenu) so its order can't be trusted.
    local -a ordered=()
    local s
    for cat in "${ALL_CATEGORIES[@]}" "${OPTIONAL_CATEGORIES[@]}"; do
        for s in "${selected[@]}"; do
            [[ "$s" == "$cat" ]] && { ordered+=("$cat"); break; }
        done
    done
    selected=("${ordered[@]}")

    for cat in "${selected[@]}"; do
        [[ "$cat" == "base" || "$cat" == "runtimes" ]] && continue
        log_step "category: $cat"
        if source_install "$cat"; then
            "install_${cat//-/_}_all"
        else
            log_warn "no install script for category: $cat"
        fi
    done

    install_configs
    ensure_env_file
    prompt_api_keys
    finalize

    log_step "done"
    if (( SETUP_ERRORS > 0 )); then
        log_warn "$SETUP_ERRORS command(s) failed — see the [WARN] lines above"
        log_warn "cervelAI partially installed for user=$(_user)"
        exit 1
    fi
    log_ok "cervelAI ready at user=$(_user)"
}

source_install() {
    local f="${INSTALL_DIR}/${1}.sh"
    [[ -r "$f" ]] || return 1
    # shellcheck disable=SC1090
    source "$f"
}

source_menu() {
    local f="${SCRIPT_DIR}/menu.sh"
    [[ -r "$f" ]] || { log_err "menu.sh missing"; return 1; }
    # shellcheck disable=SC1090
    source "$f"
}

create_user() {
    local u="${CERVELAI_USER:-agent}"
    if id "$u" &>/dev/null; then
        log_skip "user $u already exists"
    else
        log_info "creating user $u"
        run useradd -m -s /bin/bash -G sudo "$u"
    fi
    # Pre-create XDG dirs as the agent user. `install -d` does NOT propagate
    # -o to intermediate dirs it creates on the way, so each level is listed
    # explicitly. Idempotent: install -d re-applies -o on existing dirs.
    run install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.config"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.cache"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/bin"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/share"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/state"
    local sudoers="/etc/sudoers.d/90-${u}"
    if [[ ! -f "$sudoers" ]]; then
        if (( DRY_RUN )); then
            log_info "(dryrun) would write $sudoers"
        else
            printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$u" > "$sudoers"
            chmod 440 "$sudoers"
            log_ok "sudo NOPASSWD configured for $u"
        fi
    fi
    if [[ -n "${CERVELAI_SSH_KEY:-}" ]]; then
        local ak="/home/$u/.ssh/authorized_keys"
        if ! grep -qF "${CERVELAI_SSH_KEY}" "$ak" 2>/dev/null; then
            if (( DRY_RUN )); then
                log_info "(dryrun) would append SSH key to $ak"
            else
                printf '%s\n' "${CERVELAI_SSH_KEY}" >> "$ak"
                chmod 600 "$ak"
                chown "$u:$u" "$ak"
                log_ok "SSH key added for $u"
            fi
        fi
    fi
}

install_configs() {
    local u; u="$(_user)"
    local h="/home/$u"
    [[ -d "$CONFIGS_DIR" ]] || { log_warn "configs/ missing, skipping"; return 0; }
    log_step "deploying configs/ → $h"

    # source (configs/) → dest (relative to $h). Copy not symlink: a re-run
    # redeploys the repo version. mise/config.toml is absent on purpose —
    # install_runtimes_mise owns it; re-copying here would clobber [tools].
    local -A files=(
        ["bash/.bashrc"]=".bashrc"
        ["bash/.bash_profile"]=".bash_profile"
        ["zsh/.zshrc"]=".zshrc"
        ["zsh/.zshenv"]=".zshenv"
        ["tmux/.tmux.conf"]=".tmux.conf"
        ["agents/AGENTS.md"]="AGENTS.md"
    )
    local src
    for src in "${!files[@]}"; do
        [[ -r "$CONFIGS_DIR/$src" ]] || { log_skip "configs/$src missing"; continue; }
        run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/$src" "$h/${files[$src]}"
        log_ok "${files[$src]}"
    done

    if [[ -d "$CONFIGS_DIR/bin" ]]; then
        local b
        for b in "$CONFIGS_DIR"/bin/*; do
            [[ -f "$b" ]] || continue
            run install -D -m 755 -o "$u" -g "$u" "$b" "$h/.local/bin/$(basename "$b")"
            log_ok ".local/bin/$(basename "$b")"
        done
    fi
}

# Creates ~/.config/cervelAI/env (mise PATH + ntfy) if missing — it carries the
# PATH fix into non-interactive shells so a detached agent sees the runtimes.
ensure_env_file() {
    local u; u="$(_user)"
    local f="/home/$u/${ENV_FILE_REL}"
    if [[ -e "$f" ]]; then
        log_skip "env file already exists: $f"
        return 0
    fi
    if (( DRY_RUN )); then
        log_info "(dryrun) would create $f"
        return 0
    fi
    install -d -m 700 -o "$u" -g "$u" "$(dirname "$f")"
    local topic suffix
    suffix="$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 16)"
    if [[ ${#suffix} -ne 16 ]]; then
        log_err "could not generate ntfy topic suffix (urandom unavailable?) — aborting env file"
        return 1
    fi
    topic="cervelAI-${suffix}"
    cat > "$f" <<EOF
# cervelAI — shared environment (bash, zsh, ai-run). Mode 600.
# mise shims PATH: runtimes stay visible even in a non-interactive shell.
export PATH="\$HOME/.local/share/mise/shims:\$HOME/.local/bin:\$PATH"
# ntfy — ai-run notifications (change the topic if you want)
export NTFY_SERVER="https://ntfy.sh"
export NTFY_TOPIC="${topic}"
EOF
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        printf 'export GITHUB_TOKEN=%q\n' "$GITHUB_TOKEN" >> "$f"
    fi
    chmod 600 "$f"
    chown "$u:$u" "$f"
    log_ok "env file created: $f"
    log_info "ntfy topic: ${topic} — subscribe at https://ntfy.sh/${topic}"
}

# prompt_github_token — a token lifts the GitHub API rate limit (60→5000 req/h)
# that mise + agent installers otherwise hit mid-install. Already set or no TTY → skip.
prompt_github_token() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log_skip "GITHUB_TOKEN already set — used for mise + GitHub API"
        export GITHUB_TOKEN
        return 0
    fi
    if [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || (( DRY_RUN )); then
        log_skip "GITHUB_TOKEN prompt (CERVELAI_NO_PROMPT=1 or dryrun)"
        return 0
    fi
    if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
        log_warn "no TTY — skipping GITHUB_TOKEN prompt (installs may hit the GitHub rate limit)"
        return 0
    fi
    log_step "GitHub token (recommended — lifts the GitHub API rate limit during install)"
    log_info "create one with no scopes at https://github.com/settings/tokens"
    local val
    read -r -p "  GITHUB_TOKEN (leave empty to skip): " val < /dev/tty || val=""
    if [[ -n "$val" ]]; then
        export GITHUB_TOKEN="$val"
        log_ok "GITHUB_TOKEN set"
    else
        log_skip "GITHUB_TOKEN skipped — installs may hit the GitHub rate limit"
    fi
}

_agent_keys() {
    case "$1" in
        claude-code|pi) echo "ANTHROPIC_API_KEY" ;;
        codex)          echo "OPENAI_API_KEY" ;;
        gemini-cli)     echo "GEMINI_API_KEY" ;;
        opencode|aider|crush|goose|continue)
                        echo "ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY" ;;
    esac
}

prompt_api_keys() {
    local u; u="$(_user)"
    local envfile="/home/$u/${ENV_FILE_REL}"

    if [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || (( DRY_RUN )); then
        log_skip "API keys prompt (CERVELAI_NO_PROMPT=1 or dryrun)"
        return 0
    fi
    [[ -e "$envfile" ]] || { log_warn "env file missing — skip API keys"; return 0; }

    local agents="${CERVELAI_AGENTS:-}"
    [[ "$agents" == "all" ]] && agents="claude-code,codex,opencode,pi,aider,crush,gemini-cli,goose,continue"
    if [[ -z "$agents" ]]; then
        log_skip "no AI agents installed — skipping API key prompt"
        return 0
    fi

    # Union of the keys the installed agents use (deduped, stable order).
    local -a want=() agent_list kv
    local a k val
    IFS=',' read -r -a agent_list <<< "$agents"
    for a in "${agent_list[@]}"; do
        a="${a// /}"
        read -r -a kv <<< "$(_agent_keys "$a")"
        for k in "${kv[@]}"; do
            [[ " ${want[*]} " == *" $k "* ]] || want+=("$k")
        done
    done
    (( ${#want[@]} )) || { log_skip "no provider keys to prompt"; return 0; }

    if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
        log_warn "no TTY — skipping API key entry"
        log_warn "→ add them manually to $envfile, or re-run setup.sh via 'pct enter'"
        return 0
    fi

    log_step "API keys for the agents you installed (optional, leave empty to skip)"
    for k in "${want[@]}"; do
        if grep -q "^export ${k}=" "$envfile" 2>/dev/null; then
            log_skip "${k} already present"
            continue
        fi
        read -r -p "  ${k}: " val < /dev/tty || val=""
        if [[ -n "$val" ]]; then
            printf 'export %s=%q\n' "$k" "$val" >> "$envfile"
            log_ok "${k} written"
        else
            log_skip "${k} skipped"
        fi
    done
}

finalize() {
    local u="${CERVELAI_USER:-agent}"
    local desired="${CERVELAI_SHELL:-bash}"

    # `install -d`/`install -D` ran as root leave some parent dirs (notably
    # ~/.config) root-owned, breaking tools that mkdir under them. Fix ownership.
    run chown -R "$u:$u" "/home/$u"

    if [[ "$desired" != "bash" && "$desired" != "none" ]]; then
        local target; target="$(command -v "$desired" 2>/dev/null || true)"
        if [[ -z "$target" ]]; then
            log_warn "default shell $desired requested but not installed — skipping chsh"
        else
            local cur; cur="$(getent passwd "$u" | cut -d: -f7)"
            if [[ "$cur" == "$target" ]]; then
                log_skip "$desired already default for $u"
            else
                run chsh -s "$target" "$u"
                log_ok "default shell $desired set for $u"
            fi
        fi
    fi

    local motd="/etc/motd"
    if grep -q "cervelAI" "$motd" 2>/dev/null; then
        log_skip "MOTD already set"
    elif (( DRY_RUN )); then
        log_info "(dryrun) would write $motd"
    else
        cat > "$motd" <<MOTD

  cervelAI — LXC ready for AI coding agents

  Shell:    ${desired}    Multiplexer: ${CERVELAI_MULTIPLEXER:-tmux}
  Connect:  ssh ${u}@<this-ip>  |  mosh ${u}@<this-ip>
  Env/keys: ~/.config/cervelAI/env
  Notify:   ai-run <cmd>
  Tools:    cat ~/AGENTS.md

MOTD
        log_ok "MOTD set"
    fi
}

main "$@"
