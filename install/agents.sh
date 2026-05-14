#!/usr/bin/env bash
# install/agents.sh — terminal AI agents (BYOK).
# CERVELAI_AGENTS=<csv>  (default: empty — installs nothing; "all" = every agent)
#   claude-code codex opencode pi aider crush gemini-cli goose continue
# npm agents via mise:npm, the rest via their official curl installers.

install_agents_claude_code() {
    if _user_bash 'command -v claude' &>/dev/null; then
        log_skip "Claude Code already installed"; return 0
    fi
    log_info "installing Claude Code (Anthropic, curl installer)"
    run _user_bash 'curl -fsSL https://claude.ai/install.sh | bash'
}

install_agents_codex() {
    mise_npm "@openai/codex"
}

install_agents_opencode() {
    if _user_bash 'command -v opencode' &>/dev/null; then
        log_skip "opencode already installed"; return 0
    fi
    log_info "installing opencode (curl installer)"
    run _user_bash 'curl -fsSL https://opencode.ai/install | bash'
}

install_agents_pi() {
    if _user_bash 'command -v pi' &>/dev/null; then
        log_skip "pi.dev already installed"; return 0
    fi
    log_info "installing Pi (Earendil, curl installer)"
    run _user_bash 'curl -fsSL https://pi.dev/install.sh | sh'
}

install_agents_aider() {
    if _user_bash 'command -v aider' &>/dev/null; then
        log_skip "Aider already installed"; return 0
    fi
    log_info "installing Aider via uv tool"
    run _user_bash 'uv tool install aider-chat' \
        || log_warn "aider install failed (uv missing? see python-tools.sh)"
}

install_agents_crush() {
    if _user_bash 'command -v crush' &>/dev/null; then
        log_skip "Crush already installed"; return 0
    fi
    log_info "installing Crush (Charm, curl installer)"
    run _user_bash 'curl -fsSL https://charm.sh/crush/install.sh | bash' \
        || log_warn "crush install failed — check upstream URL"
}

install_agents_gemini_cli() {
    mise_npm "@google/gemini-cli"
}

install_agents_goose() {
    if _user_bash 'command -v goose' &>/dev/null; then
        log_skip "Goose already installed"; return 0
    fi
    log_info "installing Goose (Block, curl installer)"
    run _user_bash 'curl -fsSL https://block.github.io/goose/install.sh | bash'
}

install_agents_continue() {
    mise_npm "@continuedev/cli"
}

install_agents_all() {
    local csv="${CERVELAI_AGENTS:-}"
    [[ "$csv" == "all" ]] && csv="claude-code,codex,opencode,pi,aider,crush,gemini-cli,goose,continue"
    IFS=',' read -r -a list <<< "$csv"
    for a in "${list[@]}"; do
        a="${a// /}"
        case "$a" in
            claude-code|codex|opencode|pi|aider|crush|gemini-cli|goose|continue)
                "install_agents_${a//-/_}" ;;
            none|"") log_skip "no agent requested" ;;
            *) log_warn "unknown agent in CERVELAI_AGENTS: $a (valid: claude-code,codex,opencode,pi,aider,crush,gemini-cli,goose,continue,none)" ;;
        esac
    done
}
