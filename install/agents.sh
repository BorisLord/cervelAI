#!/usr/bin/env bash
# install/agents.sh — AI agent CLIs. CERVELAI_AGENTS=<csv>, "all" = every one.
# All via mise except claude-code, which self-updates on its own installer.

install_agents_claude_code() {
    if _user_bash 'command -v claude' &>/dev/null; then
        log_skip "Claude Code already installed"; return 0
    fi
    log_info "installing Claude Code (Anthropic)"
    run _user_bash 'curl -fsSL https://claude.ai/install.sh | bash'
}

install_agents_codex()      { mise_npm "@openai/codex"; }
install_agents_opencode()   { mise_use "npm:opencode-ai" latest opencode; }
install_agents_pi()         { mise_use "npm:@earendil-works/pi-coding-agent" latest pi; }
install_agents_aider()      { mise_use "pipx:aider-chat" latest aider; }
install_agents_crush()      { mise_aqua "charmbracelet/crush"; }
install_agents_gemini_cli() { mise_npm "@google/gemini-cli"; }
# block/goose redirects to aaif-goose/goose; aqua still pins block/goose and its
# attestation check fails on the mismatch — go through github: directly.
install_agents_goose()      { mise_use "github:aaif-goose/goose"; }
install_agents_continue()   { mise_npm "@continuedev/cli"; }

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
