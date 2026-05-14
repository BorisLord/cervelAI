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

# ─── paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/install"
CONFIGS_DIR="${SCRIPT_DIR}/configs"

# Shared env file: mise shims PATH + API keys + ntfy config. Sourced by
# ~/.bashrc, ~/.zshenv and ai-run — available in interactive and
# non-interactive shells. Mode 600.
ENV_FILE_REL=".config/cervelAI/env"

# ─── dev_mode ─────────────────────────────────────────────────────────────────
DEV_MODE="${dev_mode:-}"
in_dev_mode() { [[ ",${DEV_MODE}," == *",$1,"* ]]; }

in_dev_mode trace && set -x
DRY_RUN=0; in_dev_mode dryrun && DRY_RUN=1
NO_MENU=0;  in_dev_mode nomenu  && NO_MENU=1
# non-blocking failure counter (tool installs) — honest verdict at end of main()
SETUP_ERRORS=0

# ─── logging ──────────────────────────────────────────────────────────────────
_color() { printf '\033[%sm' "$1"; }
log_info()  { printf '%s[ INFO ]%s %s\n' "$(_color '1;34')" "$(_color 0)" "$*"; }
log_ok()    { printf '%s[  OK  ]%s %s\n' "$(_color '1;32')" "$(_color 0)" "$*"; }
log_skip()  { printf '%s[ SKIP ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*"; }
log_warn()  { printf '%s[ WARN ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*" >&2; }
log_err()   { printf '%s[ ERR  ]%s %s\n' "$(_color '1;31')" "$(_color 0)" "$*" >&2; }
log_step()  { printf '\n%s━━━ %s ━━━%s\n' "$(_color '1;36')" "$*" "$(_color 0)"; }

# run <cmd...> — execute (or print in dryrun). A failing command is logged and
# counted in SETUP_ERRORS; non-blocking here, the verdict lands at the end of
# main(). Prerequisites (base, user) are blocking — see main().
run() {
    if (( DRY_RUN )); then
        printf '%s[DRYRUN]%s %s\n' "$(_color '1;35')" "$(_color 0)" "$*"
        return 0
    fi
    if "$@"; then
        return 0
    fi
    local rc=$?
    log_warn "failed ($rc): $*"
    SETUP_ERRORS=$(( SETUP_ERRORS + 1 ))
    return "$rc"
}

# soft <cmd...> — run a command whose failure is deliberately tolerated (a
# fallback follows). Does NOT increment SETUP_ERRORS, even if the child went
# through run(). Returns the child's exit code.
soft() {
    local before=$SETUP_ERRORS
    "$@"
    local rc=$?
    SETUP_ERRORS=$before
    return "$rc"
}

# ─── guards ───────────────────────────────────────────────────────────────────
require_root() {
    [[ $EUID -eq 0 ]] || { log_err "must run as root"; exit 1; }
}

require_debian13() {
    [[ -r /etc/os-release ]] || { log_err "/etc/os-release missing"; exit 1; }
    . /etc/os-release
    [[ "${ID:-}" == "debian" ]] || { log_err "not Debian (ID=$ID)"; exit 1; }
    [[ "${VERSION_ID:-}" =~ ^13 ]] || log_warn "expected Debian 13, got $VERSION_ID — continuing anyway"
}

# idempotence helpers — used by every install/*.sh
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

# ─── mise helpers ─────────────────────────────────────────────────────────────
# mise lives in the agent user's home (installed by install/runtimes.sh).
# These helpers always invoke it as that user via an interactive login shell so
# PATH/mise activate are loaded.

_user() { printf '%s' "${CERVELAI_USER:-agent}"; }
_user_bash() {
    sudo -u "$(_user)" -i bash -c "$*"
}

mise_present() {
    [[ -x "/home/$(_user)/.local/bin/mise" ]]
}

# mise_use <backend>:<package> [version]
#   mise_use aqua:BurntSushi/ripgrep
#   mise_use npm:tokscale  latest
mise_use() {
    local pkg="$1" ver="${2:-latest}"
    if ! mise_present; then
        log_warn "mise not present — skip mise_use $pkg (install runtimes first)"
        return 1
    fi
    # Skip if the tool name (after `/`) is already on PATH for the user shell.
    local name="${pkg##*/}"; name="${name##*:}"
    if _user_bash "command -v $name" &>/dev/null; then
        log_skip "mise: $name already on PATH"
        return 0
    fi
    log_info "mise use -g $pkg@$ver"
    run _user_bash "\$HOME/.local/bin/mise use -g $pkg@$ver" \
        || { log_warn "mise install failed for $pkg — fallback to caller"; return 1; }
}

mise_npm() { mise_use "npm:$1" "${2:-latest}"; }
mise_aqua() { mise_use "aqua:$1" "${2:-latest}"; }
mise_cargo() { mise_use "cargo:$1" "${2:-latest}"; }

# ─── connectivity check ───────────────────────────────────────────────────────
check_connectivity() {
    local host="${1:-https://github.com}"
    if (( DRY_RUN )); then
        log_skip "connectivity check (dryrun)"
        return 0
    fi
    log_info "checking connectivity to $host"
    if curl -fsS --max-time 5 -o /dev/null "$host" 2>/dev/null; then
        log_ok "online"
        return 0
    fi
    log_err "no connectivity to $host — this script needs internet"
    log_err "  - check Proxmox bridge / DHCP"
    log_err "  - check firewall / NAT on host"
    log_err "  - try: pct exec $(hostname) -- curl -v https://github.com"
    return 1
}

# ─── parse args ───────────────────────────────────────────────────────────────
while (( $# )); do
    case "$1" in
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        *) log_warn "unknown arg: $1" ;;
    esac
    shift
done

# Categories shown in the menu and installed by the Step 4 loop. base (Step 1)
# and runtimes/mise (Step 3) are infrastructure — always installed.
ALL_CATEGORIES=(
    shell
    search
    editor
    git-tools
    python-tools
    agents
)
# Opt-in categories: pre-unchecked in the menu (or via CERVELAI_SELECTED).
# Single source of truth — menu.sh derives _MENU_DEFAULT_OFF from this.
OPTIONAL_CATEGORIES=(
    node-tools
    token-savers
    usage-trackers
    ide-web
    containers
)

# ─── orchestration ────────────────────────────────────────────────────────────
main() {
    local selected=() cat err_before

    require_root
    require_debian13
    check_connectivity || exit 1

    log_step "cervelAI setup"

    # Load menu.sh in interactive mode (needed for the selection sub-menus).
    if (( ! NO_MENU )); then
        if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
            log_err "interactive setup needs a TTY (whiptail) — not available via 'pct exec' without a pty"
            log_err "→ run via 'pct enter <CTID>', or use dev_mode=nomenu with CERVELAI_SELECTED"
            exit 1
        fi
        source_menu || { log_err "menu.sh required for interactive setup"; exit 1; }
    fi

    # Step 1: base + user — PREREQUISITES, blocking on failure.
    source_install base || { log_err "install/base.sh not found"; exit 1; }
    err_before=$SETUP_ERRORS
    install_base_all
    create_user
    if (( SETUP_ERRORS > err_before )); then
        log_err "failure during base/user — aborting (continuing would produce a broken LXC)"
        exit 1
    fi

    # Step 2: resolve which categories and items to install.
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
        if menu_select selected; then
            log_info "selected: ${selected[*]:-(none)}"
            # Runtimes sub-menu always runs (mise is always installed).
            local rt_sel=()
            if menu_runtimes_select rt_sel; then
                CERVELAI_RUNTIMES="$(IFS=,; echo "${rt_sel[*]}")"
                export CERVELAI_RUNTIMES
            fi
            # Per-category sub-menus.
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
        else
            log_warn "menu cancelled — installing nothing beyond base + mise + default runtimes"
            selected=()
        fi
    fi

    # Step 3: mise + language runtimes (infrastructure — many tools depend on it).
    log_step "mise + runtimes"
    source_install runtimes
    install_runtimes_all

    # Step 4: install the selected categories.
    for cat in "${selected[@]}"; do
        [[ "$cat" == "base" || "$cat" == "runtimes" ]] && continue
        log_step "category: $cat"
        if source_install "$cat"; then
            "install_${cat//-/_}_all"
        else
            log_warn "no install script for category: $cat"
        fi
    done

    # Step 5: deploy configs / dotfiles.
    install_configs

    # Step 6: env file (mise shims PATH + ntfy), then API keys.
    ensure_env_file
    prompt_api_keys

    # Step 7: finalize (default shell, motd).
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
        run install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
    fi
    # sudo NOPASSWD
    local sudoers="/etc/sudoers.d/90-${u}"
    if [[ ! -f "$sudoers" ]]; then
        run bash -c "echo '${u} ALL=(ALL) NOPASSWD:ALL' > '$sudoers' && chmod 440 '$sudoers'"
        log_ok "sudo NOPASSWD configured for $u"
    fi
    # SSH key if provided
    if [[ -n "${CERVELAI_SSH_KEY:-}" ]]; then
        local ak="/home/$u/.ssh/authorized_keys"
        if ! grep -qF "${CERVELAI_SSH_KEY}" "$ak" 2>/dev/null; then
            run bash -c "echo '${CERVELAI_SSH_KEY}' >> '$ak' && chmod 600 '$ak' && chown ${u}:${u} '$ak'"
            log_ok "SSH key added for $u"
        fi
    fi
}

install_configs() {
    local u; u="$(_user)"
    local h="/home/$u"
    [[ -d "$CONFIGS_DIR" ]] || { log_warn "configs/ missing, skipping"; return 0; }
    log_step "deploying configs/ → $h"

    # Explicit source (in configs/) → destination (relative to $h) mapping.
    # Copy, not symlink: a re-run redeploys the repo version so updates propagate.
    local -A files=(
        ["bash/.bashrc"]=".bashrc"
        ["bash/.bash_profile"]=".bash_profile"
        ["zsh/.zshrc"]=".zshrc"
        ["zsh/.zshenv"]=".zshenv"
        ["tmux/.tmux.conf"]=".tmux.conf"
        ["mise/config.toml"]=".config/mise/config.toml"
    )
    local src
    for src in "${!files[@]}"; do
        [[ -r "$CONFIGS_DIR/$src" ]] || { log_skip "configs/$src missing"; continue; }
        run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/$src" "$h/${files[$src]}"
        log_ok "${files[$src]}"
    done

    # Executable commands → ~/.local/bin (e.g. ai-run)
    if [[ -d "$CONFIGS_DIR/bin" ]]; then
        local b
        for b in "$CONFIGS_DIR"/bin/*; do
            [[ -f "$b" ]] || continue
            run install -D -m 755 -o "$u" -g "$u" "$b" "$h/.local/bin/$(basename "$b")"
            log_ok ".local/bin/$(basename "$b")"
        done
    fi

    # snip filters (YAML dir) → ~/.config/snip/filters/
    if compgen -G "$CONFIGS_DIR/snip/filters/*" >/dev/null 2>&1; then
        run install -d -m 755 -o "$u" -g "$u" "$h/.config/snip/filters"
        run cp -r "$CONFIGS_DIR/snip/filters/." "$h/.config/snip/filters/"
        run chown -R "$u:$u" "$h/.config/snip"
    fi
}

# Creates ~/.config/cervelAI/env (mise shims PATH + ntfy config) if missing.
# Sourced by ~/.bashrc, ~/.zshenv and ai-run — carries the PATH fix for
# non-interactive shells (so a detached agent sees the mise runtimes).
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
    local topic
    topic="cervelAI-$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 8)"
    cat > "$f" <<EOF
# cervelAI — shared environment (bash, zsh, ai-run). Mode 600.
# mise shims PATH: runtimes stay visible even in a non-interactive shell.
export PATH="\$HOME/.local/share/mise/shims:\$HOME/.local/bin:\$PATH"
# ntfy — ai-run notifications (change the topic if you want)
export NTFY_SERVER="https://ntfy.sh"
export NTFY_TOPIC="${topic}"
EOF
    chmod 600 "$f"
    chown "$u:$u" "$f"
    log_ok "env file created: $f"
    log_info "ntfy topic: ${topic} — subscribe at https://ntfy.sh/${topic}"
}

prompt_api_keys() {
    local u; u="$(_user)"
    local envfile="/home/$u/${ENV_FILE_REL}"

    if [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || (( DRY_RUN )); then
        log_skip "API keys prompt (CERVELAI_NO_PROMPT=1 or dryrun)"
        return 0
    fi
    [[ -e "$envfile" ]] || { log_warn "env file missing — skip API keys"; return 0; }

    # No TTY (launched via 'pct exec' without a pty) → read would fail silently.
    if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
        log_warn "no TTY — skipping API key entry"
        log_warn "→ add them manually to $envfile, or re-run setup.sh via 'pct enter'"
        return 0
    fi

    log_step "API keys (optional, leave empty to skip)"
    local keys=(
        "ANTHROPIC_API_KEY"
        "OPENAI_API_KEY"
        "GEMINI_API_KEY"
        "OPENROUTER_API_KEY"
        "GROQ_API_KEY"
    )
    local k val
    for k in "${keys[@]}"; do
        if grep -q "^export ${k}=" "$envfile" 2>/dev/null; then
            log_skip "${k} already present"
            continue
        fi
        read -r -p "  ${k}: " val < /dev/tty || val=""
        if [[ -n "$val" ]]; then
            printf "export %s='%s'\n" "$k" "$val" >> "$envfile"
            log_ok "${k} written"
        else
            log_skip "${k} skipped"
        fi
    done
}

finalize() {
    local u="${CERVELAI_USER:-agent}"
    local desired="${CERVELAI_SHELL:-bash}"

    # Change the default shell only if the user explicitly picked != bash.
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

    # MOTD
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

MOTD
        log_ok "MOTD set"
    fi
}

main "$@"
