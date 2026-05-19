#!/usr/bin/env bash
# install/agents.sh: AI agent CLIs (CERVELAI_AGENTS=<csv|all>). claude-code self-updates.

# package → binary map. -g survives sourcing from a function; also read by aoe gate in shell.sh.
declare -gA _AGENT_BIN=(
    ["claude-code"]=claude
    ["codex"]=codex
    ["opencode"]=opencode
    ["pi"]=pi
    ["copilot-cli"]=copilot
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
install_agents_copilot_cli() { mise_use "npm:@github/copilot" latest copilot; }
install_agents_crush() { mise_aqua "charmbracelet/crush"; }
install_agents_gemini_cli() { mise_use "npm:@google/gemini-cli" latest gemini; }
install_agents_goose() { mise_use "github:aaif-goose/goose"; }
install_agents_continue() { mise_use "npm:@continuedev/cli" latest cn; }
install_agents_qwen_code() { mise_use "npm:@qwen-code/qwen-code" latest qwen; }
install_agents_mistral_vibe() { mise_use "pipx:mistral-vibe" latest vibe; }
install_agents_deepseek_tui() { mise_use "npm:deepseek-tui" latest deepseek; }
install_agents_grok_cli() { mise_use "npm:@vibe-kit/grok-cli" latest grok; }

install_agents_all() {
    local all
    all="$(
        IFS=,
        echo "${!_AGENT_BIN[*]}"
    )"
    _dispatch_csv agents CERVELAI_AGENTS "$all"
}

# bin → agent prompt path. Symlinked to ~/AGENTS.md (single source of truth, no drift).
declare -gA _AGENT_MD_PATH=(
    [claude]=".claude/CLAUDE.md"
    [codex]=".codex/AGENTS.md"
    [opencode]=".config/opencode/AGENTS.md"
    [pi]=".pi/agent/AGENTS.md"
    [copilot]=".copilot/copilot-instructions.md"
    [gemini]=".gemini/GEMINI.md"
)

install_agents_md_links() {
    local u home src bin rel target
    u="$(_user)"
    home="/home/$u"
    src="$home/AGENTS.md"
    [[ -r "$src" ]] || return 0
    for bin in "${!_AGENT_MD_PATH[@]}"; do
        _user_bash "command -v $bin" &>/dev/null || continue
        rel="${_AGENT_MD_PATH[$bin]}"
        target="$home/$rel"
        run install -d -m 755 -o "$u" -g "$u" "$(dirname "$target")"
        run sudo -u "$u" ln -sf "$src" "$target"
        log_ok "linked ~/$rel → ~/AGENTS.md"
    done
}
