#!/usr/bin/env bash
# setup.sh: cervelAI phase 2. Run as root on Debian/Ubuntu.
# Usage:
#   bash setup.sh                    # interactive
#   dev_mode=nomenu bash setup.sh    # installs everything
#   dev_mode=trace,dryrun bash setup.sh
# Env vars: see README.md (CERVELAI_*).

set -uo pipefail
export LC_ALL=C # silences perl locale warnings
# Kernel delivers SIGINT to the entire foreground pgid (children included). Just mark and exit.
trap 'printf "\n[ ABORT ] interrupted (Ctrl+C)\n" >&2; exit 130' INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/install"
CONFIGS_DIR="${SCRIPT_DIR}/configs"

# shellcheck disable=SC2034  # used only by sourced install/*.sh
ENV_FILE_REL=".config/cervelAI/env"

# Agent runtime PATH, single source for _user_bash + the env file. Literal $HOME (expanded by
# the agent shell, not here). Includes ~/.bun/bin for bun-global tools.
# shellcheck disable=SC2016
CERVELAI_AGENT_PATH='$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/.bun/bin:$PNPM_HOME:$PNPM_HOME/bin:$PATH'

DEV_MODE="${dev_mode:-}"
in_dev_mode() { [[ ",${DEV_MODE}," == *",$1,"* ]]; }

in_dev_mode trace && set -x
DRY_RUN=0
in_dev_mode dryrun && DRY_RUN=1
NO_MENU=0
in_dev_mode nomenu && NO_MENU=1
SETUP_ERRORS=0

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

require_debian_family() {
    [[ -r /etc/os-release ]] || {
        log_err "/etc/os-release missing"
        exit 1
    }
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "debian" && "${ID:-}" != "ubuntu" && "${ID_LIKE:-}" != *"debian"* ]]; then
        log_err "not a Debian-family distro (ID=${ID:-?}, ID_LIKE=${ID_LIKE:-})"
        exit 1
    fi
    log_info "distro: ${PRETTY_NAME:-$ID $VERSION_ID}"
}

# /run/systemd/system catches WSL/containers where systemctl exists but init isn't systemd.
require_systemd() {
    ((DRY_RUN)) && {
        log_skip "systemd check (dryrun)"
        return 0
    }
    [[ -d /run/systemd/system ]] || {
        log_err "systemd not running as init (no /run/systemd/system)"
        log_err "→ Devuan / sysvinit / WSL without systemd=true are unsupported"
        exit 1
    }
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

_user() { printf '%s' "${CERVELAI_USER:-agent}"; }
_user_bash() {
    # Run via a temp script, not `bash -c "...$*"`: inlining lets the root shell pre-expand the
    # user command's $vars/$(…) before the agent shell sees them (silently broke find/$src).
    local u tmp rc
    u="$(_user)"
    tmp="$(mktemp /tmp/cervelai-userbash.XXXXXX)"
    {
        # literal $HOME/$PATH: written to the script, expanded by the agent shell at run time.
        # shellcheck disable=SC2016
        printf '%s\n' 'export PNPM_HOME="$HOME/.local/share/pnpm"'
        printf 'export PATH="%s"\n' "$CERVELAI_AGENT_PATH"
        printf '%s\n' 'export npm_config_update_notifier=false'
        [[ -n "${GITHUB_TOKEN:-}" ]] && printf 'export GITHUB_TOKEN=%q\n' "$GITHUB_TOKEN"
        printf '%s\n' "$*"
    } >"$tmp"
    chmod 600 "$tmp"
    chown "$u" "$tmp"
    sudo -u "$u" -i bash "$tmp"
    rc=$?
    rm -f "$tmp"
    return "$rc"
}

# Copy configs/libexec/* into <dest>/ at mode 755; pass an owner to chown (omit for /etc/skel).
_deploy_libexec() {
    local dest="$1" owner="${2:-}" b
    local -a own=()
    [[ -n "$owner" ]] && own=(-o "$owner" -g "$owner")
    for b in "$CONFIGS_DIR"/libexec/*; do
        [[ -f "$b" ]] || continue
        run install -D -m 755 "${own[@]}" "$b" "$dest/$(basename "$b")"
    done
}

mise_present() { [[ -x /usr/local/bin/mise ]]; }

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

# Dispatch a CSV (or "all" → full-list) to install_<cat>_<choice>. Skips none/empty, warns unknown.
# Usage: _dispatch_csv <category> <env-var-name> <full-list-csv>
_dispatch_csv() {
    local cat="$1" envname="$2" all="$3"
    local csv="${!envname:-}"
    [[ "$csv" == "all" ]] && csv="$all"
    IFS=',' read -r -a list <<<"$csv"
    local x
    for x in "${list[@]}"; do
        x="${x// /}"
        if [[ -z "$x" || "$x" == "none" ]]; then
            log_skip "no $cat requested"
        elif [[ ",${all}," == *",$x,"* ]]; then
            "install_${cat//-/_}_${x//-/_}"
        else
            log_warn "unknown $cat in $envname: $x (valid: $all,none)"
        fi
    done
}

# /dev/tcp because curl isn't installed yet at this stage.
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

# Opt-in only — mandatory baseline (base, runtimes core, lsp, search-core, gh) is called directly in main().
CATEGORIES=(
    agents
    token-savers
    agent-memory
    usage-trackers
    ai-tools
    editor
    ide-web
    runtimes
    workflow-tools
    containers
    k8s-stack
    iac-stack
    cloud-stack
    data-stack
    cli-extras
    security-tools
    git-forges
    blockchain
)

# shellcheck disable=SC1091
source "${INSTALL_DIR}/_user.sh"
# shellcheck disable=SC1091
source "${INSTALL_DIR}/_prompts.sh"
# shellcheck disable=SC1091
source "${INSTALL_DIR}/_finalize.sh"

main() {
    local selected=() cat err_before

    require_root
    require_debian_family
    require_systemd
    check_connectivity || exit 1
    prompt_github_token

    log_step "cervelAI setup"

    if ((!NO_MENU)); then
        if ! (: </dev/tty) 2>/dev/null; then
            log_err "interactive setup needs a TTY, not available via 'pct exec' without a pty"
            log_err "→ run via 'pct enter <CTID>', or use dev_mode=nomenu with CERVELAI_SELECTED"
            exit 1
        fi
        source_menu || {
            log_err "menu.sh required for interactive setup"
            exit 1
        }
    fi

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
            : "${CERVELAI_EDITOR:=all}"
            : "${CERVELAI_GIT_FORGES:=all}"
            : "${CERVELAI_RUNTIMES:=all}"
            : "${CERVELAI_AGENT_MEMORY:=all}"
            : "${CERVELAI_AI_TOOLS:=all}"
            : "${CERVELAI_CLOUD_STACK:=all}"
            : "${CERVELAI_BLOCKCHAIN:=all}"
            : "${CERVELAI_DATA_STACK:=all}"
            : "${CERVELAI_CONTAINERS:=all}"
            : "${CERVELAI_K8S_STACK:=all}"
            : "${CERVELAI_CLI_EXTRAS:=all}"
            : "${CERVELAI_SECURITY_TOOLS:=all}"
            : "${CERVELAI_TOKEN_SAVERS:=snip}"
            : "${CERVELAI_MULTIPLEXER:=tmux+aoe}"
            export CERVELAI_AGENTS CERVELAI_EDITOR CERVELAI_GIT_FORGES CERVELAI_RUNTIMES \
                CERVELAI_AGENT_MEMORY CERVELAI_AI_TOOLS CERVELAI_CLOUD_STACK CERVELAI_BLOCKCHAIN \
                CERVELAI_DATA_STACK CERVELAI_CONTAINERS CERVELAI_K8S_STACK \
                CERVELAI_CLI_EXTRAS CERVELAI_SECURITY_TOOLS CERVELAI_TOKEN_SAVERS \
                CERVELAI_MULTIPLEXER
        else
            IFS=',' read -r -a selected <<<"$CERVELAI_SELECTED"
        fi
        log_info "selected: ${selected[*]:-(none)}"
    else
        # Always-asked workspace prompts (single-select) — even if user picks zero categories.
        local sh_sel="" mp_sel=""
        if menu_shell_select sh_sel; then
            CERVELAI_SHELL="$sh_sel"
            export CERVELAI_SHELL
        fi
        if menu_multiplexer_select mp_sel; then
            CERVELAI_MULTIPLEXER="$mp_sel"
            export CERVELAI_MULTIPLEXER
        fi

        while :; do
            if menu_select selected; then
                log_info "selected: ${selected[*]:-(none)}"
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
                            if menu_editor_select ed_sel; then
                                CERVELAI_EDITOR="$(
                                    IFS=,
                                    echo "${ed_sel[*]}"
                                )"
                                export CERVELAI_EDITOR
                            fi
                            ;;
                        token-savers)
                            local ts_sel=""
                            menu_token_savers_select ts_sel && {
                                CERVELAI_TOKEN_SAVERS="$ts_sel"
                                export CERVELAI_TOKEN_SAVERS
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
                        ai-tools)
                            local at_sel=()
                            if menu_ai_tools_select at_sel; then
                                CERVELAI_AI_TOOLS="$(
                                    IFS=,
                                    echo "${at_sel[*]}"
                                )"
                                export CERVELAI_AI_TOOLS
                            fi
                            ;;
                        runtimes)
                            local rt_sel=()
                            if menu_runtimes_select rt_sel; then
                                CERVELAI_RUNTIMES="$(
                                    IFS=,
                                    echo "${rt_sel[*]}"
                                )"
                                export CERVELAI_RUNTIMES
                            fi
                            ;;
                        containers)
                            local ct_sel=()
                            if menu_containers_select ct_sel && ((${#ct_sel[@]})); then
                                CERVELAI_CONTAINERS="$(
                                    IFS=,
                                    echo "${ct_sel[*]}"
                                )"
                                export CERVELAI_CONTAINERS
                            fi
                            ;;
                        k8s-stack)
                            local k8_sel=()
                            if menu_k8s_stack_select k8_sel && ((${#k8_sel[@]})); then
                                CERVELAI_K8S_STACK="$(
                                    IFS=,
                                    echo "${k8_sel[*]}"
                                )"
                                export CERVELAI_K8S_STACK
                            fi
                            ;;
                        data-stack)
                            local ds_sel=()
                            if menu_data_stack_select ds_sel && ((${#ds_sel[@]})); then
                                CERVELAI_DATA_STACK="$(
                                    IFS=,
                                    echo "${ds_sel[*]}"
                                )"
                                export CERVELAI_DATA_STACK
                            fi
                            ;;
                        cloud-stack)
                            local cs_sel=()
                            if menu_cloud_stack_select cs_sel && ((${#cs_sel[@]})); then
                                CERVELAI_CLOUD_STACK="$(
                                    IFS=,
                                    echo "${cs_sel[*]}"
                                )"
                                export CERVELAI_CLOUD_STACK
                            fi
                            ;;
                        blockchain)
                            local bc_sel=()
                            if menu_blockchain_select bc_sel && ((${#bc_sel[@]})); then
                                CERVELAI_BLOCKCHAIN="$(
                                    IFS=,
                                    echo "${bc_sel[*]}"
                                )"
                                export CERVELAI_BLOCKCHAIN
                            fi
                            ;;
                        cli-extras)
                            local ce_sel=()
                            if menu_cli_extras_select ce_sel && ((${#ce_sel[@]})); then
                                CERVELAI_CLI_EXTRAS="$(
                                    IFS=,
                                    echo "${ce_sel[*]}"
                                )"
                                export CERVELAI_CLI_EXTRAS
                            fi
                            ;;
                        security-tools)
                            local st_sel=()
                            if menu_security_tools_select st_sel && ((${#st_sel[@]})); then
                                CERVELAI_SECURITY_TOOLS="$(
                                    IFS=,
                                    echo "${st_sel[*]}"
                                )"
                                export CERVELAI_SECURITY_TOOLS
                            fi
                            ;;
                        git-forges)
                            local gf_sel=()
                            if menu_git_forges_select gf_sel && ((${#gf_sel[@]})); then
                                CERVELAI_GIT_FORGES="$(
                                    IFS=,
                                    echo "${gf_sel[*]}"
                                )"
                                export CERVELAI_GIT_FORGES
                            fi
                            ;;
                    esac
                done
                menu_summary_confirm && break
                log_info "redoing selection…"
                unset CERVELAI_RUNTIMES CERVELAI_GIT_FORGES CERVELAI_AGENTS \
                    CERVELAI_EDITOR CERVELAI_TOKEN_SAVERS CERVELAI_AGENT_MEMORY \
                    CERVELAI_AI_TOOLS CERVELAI_CLOUD_STACK CERVELAI_BLOCKCHAIN \
                    CERVELAI_DATA_STACK CERVELAI_CONTAINERS CERVELAI_K8S_STACK \
                    CERVELAI_CLI_EXTRAS CERVELAI_SECURITY_TOOLS
            else
                log_warn "menu cancelled, installing only mandatory baseline"
                selected=()
                break
            fi
        done
    fi

    # --- Mandatory baseline (runs regardless of category selection) ---

    log_step "mise + runtimes core (node/python/pnpm/uv)"
    source_install runtimes
    install_runtimes_mandatory

    log_step "language servers (LSP core — runtime-gated LSPs run later)"
    source_install lsp && install_lsp_core

    log_step "search-core (AI-critical: rg/fd/jq/yq/bat/...)"
    source_install search && install_search_all

    log_step "git core (gh + delta)"
    source_install git-tools && install_git_tools_core

    log_step "shell + multiplexer"
    source_install shell && install_shell_all

    # --- Opt-in categories ---

    # token-savers must run AFTER agents (hooks init reads agent binaries); CATEGORIES order enforces this.
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
        log_step "category: $cat"
        if source_install "$cat"; then
            "install_${cat//-/_}_all"
        else
            log_warn "no install script for category: $cat"
        fi
    done

    # runtime-gated LSPs (rust-analyzer, zls, lua-LSP, kotlin-LSP, ruby-lsp) need opt-in runtimes installed first.
    log_step "language servers (runtime-gated)"
    source_install lsp && install_lsp_runtime_gated

    # aoe gated on ≥1 agent installed — must run AFTER agents category.
    log_step "aoe orchestrator (post-dispatch)"
    install_shell_aoe_post_dispatch

    install_configs
    source_install agents && install_agents_md_links
    ensure_env_file
    prompt_api_keys
    finalize
    lock_pnpm_release_age
    run_final_topgrade

    if ((SETUP_ERRORS > 0)); then
        log_warn "$SETUP_ERRORS command(s) failed during install, see the [WARN] lines above"
    fi
    print_final_summary
    ((SETUP_ERRORS == 0))
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

main "$@"
