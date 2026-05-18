#!/usr/bin/env bash
# install/agents.sh: AI agent CLIs (CERVELAI_AGENTS=<csv|all>). claude-code self-updates.

# package → binary map. -g survives sourcing from a function; also read by aoe gate in shell.sh.
declare -gA _AGENT_BIN=(
    ["claude-code"]=claude
    ["codex"]=codex
    ["opencode"]=opencode
    ["pi"]=pi
    ["crush"]=crush
    ["gemini-cli"]=gemini
    ["goose"]=goose
    ["continue"]=cn
    ["qwen-code"]=qwen
    ["mistral-vibe"]=vibe
    ["deepseek-tui"]=deepseek
    ["grok-cli"]=grok
)

install_agents_claude_code() {
    if _user_bash 'command -v claude' &>/dev/null; then
        log_skip "Claude Code already installed"
        return 0
    fi
    log_info "installing Claude Code (Anthropic)"
    run _user_bash 'curl -fsSL https://claude.ai/install.sh | bash'
}

install_agents_codex() { mise_npm "@openai/codex"; }
install_agents_opencode() { mise_use "npm:opencode-ai" latest opencode; }
install_agents_pi() { mise_use "npm:@earendil-works/pi-coding-agent" latest pi; }
install_agents_crush() { mise_aqua "charmbracelet/crush"; }
install_agents_gemini_cli() { mise_use "npm:@google/gemini-cli" latest gemini; }
# github: backend instead of aqua because aqua's block/goose attestation fails on the aaif-goose redirect.
install_agents_goose() { mise_use "github:aaif-goose/goose"; }
install_agents_continue() { mise_use "npm:@continuedev/cli" latest cn; }
install_agents_qwen_code() { mise_use "npm:@qwen-code/qwen-code" latest qwen; }
install_agents_mistral_vibe() { mise_use "pipx:mistral-vibe" latest vibe; }
install_agents_deepseek_tui() { mise_use "npm:deepseek-tui" latest deepseek; }
install_agents_grok_cli() { mise_use "npm:@vibe-kit/grok-cli" latest grok; }

install_agents_all() {
    local csv="${CERVELAI_AGENTS:-}"
    if [[ "$csv" == "all" ]]; then
        csv="$(
            IFS=,
            echo "${!_AGENT_BIN[*]}"
        )"
    fi
    IFS=',' read -r -a list <<<"$csv"
    for a in "${list[@]}"; do
        a="${a// /}"
        if [[ -n "${_AGENT_BIN[$a]:-}" ]]; then
            "install_agents_${a//-/_}"
        elif [[ "$a" == "none" || -z "$a" ]]; then
            log_skip "no agent requested"
        else
            log_warn "unknown agent in CERVELAI_AGENTS: $a (valid: ${!_AGENT_BIN[*]},none)"
        fi
    done
}
