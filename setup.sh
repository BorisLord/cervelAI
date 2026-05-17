#!/usr/bin/env bash
# setup.sh: cervelAI phase 2 (guest LXC). Run as root in Debian 13.
#
# Usage:
#   bash setup.sh                    # interactive, pick tools in a menu
#   dev_mode=nomenu bash setup.sh    # non-interactive, installs everything
#   dev_mode=trace,dryrun bash setup.sh
#
# See README.md for the full env var table (CERVELAI_*).

set -uo pipefail
export LC_ALL=C # deterministic output; silences perl locale warnings

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/install"
CONFIGS_DIR="${SCRIPT_DIR}/configs"

ENV_FILE_REL=".config/cervelAI/env"

DEV_MODE="${dev_mode:-}"
in_dev_mode() { [[ ",${DEV_MODE}," == *",$1,"* ]]; }

in_dev_mode trace && set -x
DRY_RUN=0
in_dev_mode dryrun && DRY_RUN=1
NO_MENU=0
in_dev_mode nomenu && NO_MENU=1
SETUP_ERRORS=0 # non-blocking failure counter; verdict at the end of main()

_color() { printf '\033[%sm' "$1"; }
log_info() { printf '%s[ INFO ]%s %s\n' "$(_color '1;34')" "$(_color 0)" "$*"; }
log_ok() { printf '%s[  OK  ]%s %s\n' "$(_color '1;32')" "$(_color 0)" "$*"; }
log_skip() { printf '%s[ SKIP ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*"; }
log_warn() { printf '%s[ WARN ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*" >&2; }
log_err() { printf '%s[ ERR  ]%s %s\n' "$(_color '1;31')" "$(_color 0)" "$*" >&2; }
log_step() { printf '\n%s━━━ %s ━━━%s\n' "$(_color '1;36')" "$*" "$(_color 0)"; }

# gum theme (inherits to all child gum calls): cyan=step, green=ok, yellow=focus, gray=dim.
export GUM_CHOOSE_HEADER_FOREGROUND="14"
export GUM_CHOOSE_CURSOR_FOREGROUND="11"
export GUM_CHOOSE_SELECTED_FOREGROUND="10"
export GUM_CONFIRM_PROMPT_FOREGROUND="14"
export GUM_CONFIRM_SELECTED_BACKGROUND="10"
export GUM_CONFIRM_SELECTED_FOREGROUND="0"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="8"
export GUM_INPUT_PROMPT_FOREGROUND="14"
export GUM_INPUT_CURSOR_FOREGROUND="11"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="8"

run() {
    if ((DRY_RUN)); then
        printf '%s[DRYRUN]%s %s\n' "$(_color '1;35')" "$(_color 0)" "$*"
        return 0
    fi
    local rc=0
    "$@" || rc=$?
    if ((rc != 0)); then
        log_warn "failed ($rc) at ${BASH_SOURCE[1]##*/}:${BASH_LINENO[0]} : $*"
        SETUP_ERRORS=$((SETUP_ERRORS + 1))
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
    [[ $EUID -eq 0 ]] || {
        log_err "must run as root"
        exit 1
    }
}

require_debian13() {
    [[ -r /etc/os-release ]] || {
        log_err "/etc/os-release missing"
        exit 1
    }
    . /etc/os-release
    [[ "${ID:-}" == "debian" ]] || {
        log_err "not Debian (ID=$ID)"
        exit 1
    }
    [[ "${VERSION_ID:-}" =~ ^13 ]] || log_warn "expected Debian 13, got $VERSION_ID, continuing anyway"
}

has_cmd() { command -v "$1" &>/dev/null; }
has_pkg() { dpkg -s "$1" &>/dev/null; }

apt_install() {
    local missing=()
    for p in "$@"; do has_pkg "$p" || missing+=("$p"); done
    if ((${#missing[@]} == 0)); then
        log_skip "apt: ${*} already installed"
        return 0
    fi
    log_info "apt install: ${missing[*]}"
    run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
}

# mise at /usr/local/bin/mise (system-wide) so its npm backend and shims always resolve.
_user() { printf '%s' "${CERVELAI_USER:-agent}"; }
# Runs as agent user with mise shims on PATH; preserves GITHUB_TOKEN for mise's GitHub backend.
_user_bash() {
    sudo -u "$(_user)" --preserve-env=GITHUB_TOKEN -i bash -c \
        "export PATH=\"\$HOME/.local/share/mise/shims:\$HOME/.local/bin:\$PATH\"; $*"
}

mise_present() {
    [[ -x /usr/local/bin/mise ]]
}

# mise_use <backend>:<pkg> [version] [cmd_name]
# cmd_name is needed when the binary differs from the package name.
mise_use() {
    local pkg="$1" ver="${2:-latest}" name="${3:-}"
    if ! mise_present; then
        log_warn "mise not present, skip mise_use $pkg (install runtimes first)"
        return 1
    fi
    if [[ -z "$name" ]]; then
        name="${pkg##*/}"
        name="${name##*:}"
    fi
    if _user_bash "command -v $name" &>/dev/null; then
        log_skip "mise: $name already on PATH"
        return 0
    fi
    log_info "mise use -g $pkg@$ver"
    run _user_bash "mise use -g $pkg@$ver" ||
        {
            log_warn "mise install failed for $pkg, fallback to caller"
            return 1
        }
}

mise_npm() { mise_use "npm:$1" "${2:-latest}"; }
mise_aqua() { mise_use "aqua:$1" "${2:-latest}"; }

# DNS + TCP test via bash's /dev/tcp (curl isn't installed yet).
check_connectivity() {
    local host="${1:-github.com}" port="${2:-443}"
    if ((DRY_RUN)); then
        log_skip "connectivity check (dryrun)"
        return 0
    fi
    log_info "checking connectivity to ${host}:${port}"
    if timeout 5 bash -c "exec 3<>/dev/tcp/${host}/${port}" 2>/dev/null; then
        log_ok "online"
        return 0
    fi
    log_err "no connectivity to ${host}:${port}; this script needs internet"
    log_err "  - check Proxmox bridge / DHCP"
    log_err "  - check firewall / NAT on host"
    return 1
}

while (($#)); do
    case "$1" in
        -h | --help)
            sed -n '2,13p' "$0"
            exit 0
            ;;
        *) log_warn "unknown arg: $1" ;;
    esac
    shift
done

# Categories in menu/install order. base + runtimes + lsp always run, excluded here. Nothing pre-checked.
CATEGORIES=(
    shell
    search
    editor
    git-tools
    agents
    orchestrator
    token-savers
    usage-trackers
    ide-web
    containers
    db
    http
    data
    agent-memory
)

main() {
    local selected=() cat err_before

    require_root
    require_debian13
    check_connectivity || exit 1
    prompt_github_token

    log_step "cervelAI setup"

    if ((!NO_MENU)); then
        if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
            log_err "interactive setup needs a TTY, not available via 'pct exec' without a pty"
            log_err "→ run via 'pct enter <CTID>', or use dev_mode=nomenu with CERVELAI_SELECTED"
            exit 1
        fi
        source_menu || {
            log_err "menu.sh required for interactive setup"
            exit 1
        }
    fi

    # base + user are prerequisites, abort the whole run if they fail.
    source_install base || {
        log_err "install/base.sh not found"
        exit 1
    }
    err_before=$SETUP_ERRORS
    install_base_all
    create_user
    if ((SETUP_ERRORS > err_before)); then
        log_err "failure during base/user, aborting (continuing would produce a broken LXC)"
        exit 1
    fi

    if ((NO_MENU)); then
        if [[ "${CERVELAI_SELECTED:-all}" == "all" ]]; then
            selected=("${CATEGORIES[@]}")
            : "${CERVELAI_AGENTS:=all}"
            : "${CERVELAI_EDITORS:=all}"
            : "${CERVELAI_GIT_FORGES:=all}"
            : "${CERVELAI_RUNTIMES:=all}"
            : "${CERVELAI_AGENT_MEMORY:=all}"
            export CERVELAI_AGENTS CERVELAI_EDITORS CERVELAI_GIT_FORGES CERVELAI_RUNTIMES CERVELAI_AGENT_MEMORY
        else
            IFS=',' read -r -a selected <<<"$CERVELAI_SELECTED"
        fi
        log_info "selected: ${selected[*]:-(none)}"
    else
        # Loop until the summary is confirmed, lets the user redo any selection.
        while :; do
            if menu_select selected; then
                log_info "selected: ${selected[*]:-(none)}"
                local rt_sel=()
                if menu_runtimes_select rt_sel; then
                    CERVELAI_RUNTIMES="$(
                        IFS=,
                        echo "${rt_sel[*]}"
                    )"
                    export CERVELAI_RUNTIMES
                fi
                for cat in "${selected[@]}"; do
                    case "$cat" in
                        agents)
                            local ag_sel=()
                            if menu_agents_select ag_sel; then
                                CERVELAI_AGENTS="$(
                                    IFS=,
                                    echo "${ag_sel[*]}"
                                )"
                                export CERVELAI_AGENTS
                            fi
                            ;;
                        editor)
                            local ed_sel=()
                            if menu_editors_select ed_sel; then
                                CERVELAI_EDITORS="$(
                                    IFS=,
                                    echo "${ed_sel[*]}"
                                )"
                                export CERVELAI_EDITORS
                            fi
                            ;;
                        git-tools)
                            local gf_sel=()
                            if menu_git_forges_select gf_sel; then
                                CERVELAI_GIT_FORGES="$(
                                    IFS=,
                                    echo "${gf_sel[*]}"
                                )"
                                export CERVELAI_GIT_FORGES
                            fi
                            ;;
                        shell)
                            local sh_sel="" mx_sel=""
                            menu_shell_select sh_sel && {
                                CERVELAI_SHELL="$sh_sel"
                                export CERVELAI_SHELL
                            }
                            menu_multiplexer_select mx_sel && {
                                CERVELAI_MULTIPLEXER="$mx_sel"
                                export CERVELAI_MULTIPLEXER
                            }
                            ;;
                        token-savers)
                            local ts_sel=""
                            menu_token_saver_select ts_sel && {
                                CERVELAI_TOKEN_SAVER="$ts_sel"
                                export CERVELAI_TOKEN_SAVER
                            }
                            ;;
                        agent-memory)
                            local am_sel=()
                            if menu_agent_memory_select am_sel; then
                                CERVELAI_AGENT_MEMORY="$(
                                    IFS=,
                                    echo "${am_sel[*]}"
                                )"
                                export CERVELAI_AGENT_MEMORY
                            fi
                            ;;
                    esac
                done
                menu_summary_confirm && break
                log_info "redoing selection…"
                unset CERVELAI_RUNTIMES CERVELAI_AGENTS CERVELAI_EDITORS \
                    CERVELAI_GIT_FORGES CERVELAI_SHELL CERVELAI_MULTIPLEXER \
                    CERVELAI_TOKEN_SAVER CERVELAI_AGENT_MEMORY
            else
                log_warn "menu cancelled, installing nothing beyond base + mise + default runtimes"
                selected=()
                break
            fi
        done
    fi

    log_step "mise + runtimes"
    source_install runtimes
    install_runtimes_all

    log_step "language servers (LSP)"
    source_install lsp && install_lsp_all

    # Canonical order matters: token-savers must run AFTER agents (its hook init needs the binaries).
    local -a ordered=()
    local s
    for cat in "${CATEGORIES[@]}"; do
        for s in "${selected[@]}"; do
            [[ "$s" == "$cat" ]] && {
                ordered+=("$cat")
                break
            }
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
    prompt_final_topgrade

    log_step "done"
    if ((SETUP_ERRORS > 0)); then
        log_warn "$SETUP_ERRORS command(s) failed, see the [WARN] lines above"
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
    [[ -r "$f" ]] || {
        log_err "menu.sh missing"
        return 1
    }
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
    # `install -d` doesn't -o intermediate dirs; list each level. Idempotent.
    run install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.config"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.cache"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/bin"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/share"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/state"
    local sudoers="/etc/sudoers.d/90-${u}"
    if [[ ! -f "$sudoers" ]]; then
        if ((DRY_RUN)); then
            log_info "(dryrun) would write $sudoers"
        else
            printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$u" >"$sudoers"
            chmod 440 "$sudoers"
            log_ok "sudo NOPASSWD configured for $u"
        fi
    fi
    if [[ -n "${CERVELAI_SSH_KEY:-}" ]]; then
        local ak="/home/$u/.ssh/authorized_keys"
        if ! grep -qF "${CERVELAI_SSH_KEY}" "$ak" 2>/dev/null; then
            if ((DRY_RUN)); then
                log_info "(dryrun) would append SSH key to $ak"
            else
                printf '%s\n' "${CERVELAI_SSH_KEY}" >>"$ak"
                chmod 600 "$ak"
                chown "$u:$u" "$ak"
                log_ok "SSH key added for $u"
            fi
        fi
    fi
}

install_configs() {
    local u
    u="$(_user)"
    local h="/home/$u"
    [[ -d "$CONFIGS_DIR" ]] || {
        log_warn "configs/ missing, skipping"
        return 0
    }
    log_step "deploying configs/ → $h"

    # mise/config.toml absent on purpose: install_runtimes_mise owns it (avoid clobbering [tools]).
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
        [[ -r "$CONFIGS_DIR/$src" ]] || {
            log_skip "configs/$src missing"
            continue
        }
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

# ~/.config/cervelAI/env: PATH + ntfy, carries mise shims to non-interactive shells.
ensure_env_file() {
    local u
    u="$(_user)"
    local f="/home/$u/${ENV_FILE_REL}"
    if [[ -e "$f" ]]; then
        log_skip "env file already exists: $f"
        return 0
    fi
    if ((DRY_RUN)); then
        log_info "(dryrun) would create $f"
        return 0
    fi
    install -d -m 700 -o "$u" -g "$u" "$(dirname "$f")"
    local topic suffix
    suffix="$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 16)"
    if [[ ${#suffix} -ne 16 ]]; then
        log_err "could not generate ntfy topic suffix (urandom unavailable?), aborting env file"
        return 1
    fi
    topic="cervelAI-${suffix}"
    cat >"$f" <<EOF
# cervelAI, shared environment (bash, zsh, ai-run). Mode 600.
# mise shims PATH: runtimes stay visible even in a non-interactive shell.
export PATH="\$HOME/.local/share/mise/shims:\$HOME/.local/bin:\$PATH"
# ntfy, ai-run notifications (change the topic if you want)
export NTFY_SERVER="https://ntfy.sh"
export NTFY_TOPIC="${topic}"
EOF
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        printf 'export GITHUB_TOKEN=%q\n' "$GITHUB_TOKEN" >>"$f"
    fi
    chmod 600 "$f"
    chown "$u:$u" "$f"
    log_ok "env file created: $f"
    log_info "ntfy topic: ${topic}, subscribe at https://ntfy.sh/${topic}"
}

# GITHUB_TOKEN lifts the 60→5000 req/h rate limit that mise + installers hit mid-run.
prompt_github_token() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log_skip "GITHUB_TOKEN already set, used for mise + GitHub API"
        export GITHUB_TOKEN
        return 0
    fi
    if [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || ((DRY_RUN)); then
        log_skip "GITHUB_TOKEN prompt (CERVELAI_NO_PROMPT=1 or dryrun)"
        return 0
    fi
    if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
        log_warn "no TTY, skipping GITHUB_TOKEN prompt (installs may hit the GitHub rate limit)"
        return 0
    fi
    log_step "GitHub token (recommended, lifts the GitHub API rate limit during install)"
    log_info "create one with no scopes at https://github.com/settings/tokens"
    local val
    read -r -p "  GITHUB_TOKEN (leave empty to skip): " val </dev/tty || val=""
    if [[ -n "$val" ]]; then
        export GITHUB_TOKEN="$val"
        log_ok "GITHUB_TOKEN set"
    else
        log_skip "GITHUB_TOKEN skipped, installs may hit the GitHub rate limit"
    fi
}

_agent_keys() {
    case "$1" in
        claude-code | pi) echo "ANTHROPIC_API_KEY" ;;
        codex) echo "OPENAI_API_KEY" ;;
        gemini-cli) echo "GEMINI_API_KEY" ;;
        opencode | aider | crush | goose | continue)
            echo "ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY"
            ;;
    esac
}

prompt_api_keys() {
    local u
    u="$(_user)"
    local envfile="/home/$u/${ENV_FILE_REL}"

    if [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || ((DRY_RUN)); then
        log_skip "API keys prompt (CERVELAI_NO_PROMPT=1 or dryrun)"
        return 0
    fi
    [[ -e "$envfile" ]] || {
        log_warn "env file missing, skip API keys"
        return 0
    }

    local agents="${CERVELAI_AGENTS:-}"
    [[ "$agents" == "all" ]] && agents="claude-code,codex,opencode,pi,aider,crush,gemini-cli,goose,continue"
    if [[ -z "$agents" ]]; then
        log_skip "no AI agents installed, skipping API key prompt"
        return 0
    fi

    # Union of the keys the installed agents use (deduped, stable order).
    local -a want=() agent_list kv
    local a k val
    IFS=',' read -r -a agent_list <<<"$agents"
    for a in "${agent_list[@]}"; do
        a="${a// /}"
        read -r -a kv <<<"$(_agent_keys "$a")"
        for k in "${kv[@]}"; do
            [[ " ${want[*]} " == *" $k "* ]] || want+=("$k")
        done
    done
    ((${#want[@]})) || {
        log_skip "no provider keys to prompt"
        return 0
    }

    if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
        log_warn "no TTY, skipping API key entry"
        log_warn "→ add them manually to $envfile, or re-run setup.sh via 'pct enter'"
        return 0
    fi

    log_step "API keys for the agents you installed (optional, leave empty to skip)"
    for k in "${want[@]}"; do
        if grep -q "^export ${k}=" "$envfile" 2>/dev/null; then
            log_skip "${k} already present"
            continue
        fi
        # gum input --password masks the key (gum guaranteed installed at this point).
        if has_cmd gum; then
            val="$(gum input --password --prompt="  ${k}: " --placeholder="leave empty to skip" </dev/tty)" || val=""
        else
            read -r -s -p "  ${k}: " val </dev/tty || val=""
            printf '\n'
        fi
        if [[ -n "$val" ]]; then
            printf 'export %s=%q\n' "$k" "$val" >>"$envfile"
            log_ok "${k} written"
        else
            log_skip "${k} skipped"
        fi
    done
}

# Catches apt security updates the Debian template missed; mise/npm tools are no-ops here.
prompt_final_topgrade() {
    [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || ((DRY_RUN)) && {
        log_skip "final topgrade (nomprompt/dryrun)"
        return 0
    }
    { [ -r /dev/tty ] && [ -w /dev/tty ]; } || {
        log_skip "final topgrade (no TTY)"
        return 0
    }
    log_step "final refresh (topgrade): catches apt security updates"
    if has_cmd gum; then
        if gum confirm --default=Yes "Run topgrade now to ensure everything is current?" </dev/tty; then
            soft _user_bash "topgrade --yes"
        else
            log_skip "topgrade skipped (run later: cervelai-menu → update)"
        fi
    else
        local ans
        read -r -p "  run topgrade now? [Y/n]: " ans </dev/tty || ans=""
        case "${ans:-Y}" in
            n | N | no | NO | No) log_skip "topgrade skipped" ;;
            *) soft _user_bash "topgrade --yes" ;;
        esac
    fi
}

finalize() {
    local u="${CERVELAI_USER:-agent}"
    local desired="${CERVELAI_SHELL:-bash}"

    # `install -d` ran as root leaves parent dirs root-owned; fix recursively.
    run chown -R "$u:$u" "/home/$u"

    if [[ "$desired" != "bash" && "$desired" != "none" ]]; then
        local target
        target="$(command -v "$desired" 2>/dev/null || true)"
        if [[ -z "$target" ]]; then
            log_warn "default shell $desired requested but not installed, skipping chsh"
        else
            local cur
            cur="$(getent passwd "$u" | cut -d: -f7)"
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
    elif ((DRY_RUN)); then
        log_info "(dryrun) would write $motd"
    else
        cat >"$motd" <<MOTD

  cervelAI, LXC ready for AI coding agents

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
