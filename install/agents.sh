#!/usr/bin/env bash

# _AGENT_BIN feeds shell.sh's aoe gate; single source of truth is configs/libexec/agents-registry.
# shellcheck source=configs/libexec/agents-registry
source "${CONFIGS_DIR}/libexec/agents-registry"
declare -gA _AGENT_BIN=()
_agent_entry=""
for _agent_entry in "${CERVELAI_AGENTS_REGISTRY[@]}"; do
    _AGENT_BIN["${_agent_entry%%:*}"]="${_agent_entry##*:}"
done
unset _agent_entry

install_agents_claude_code() {
    if _user_bash 'command -v claude' &>/dev/null; then
        log_skip "Claude Code already installed"
        return 0
    fi
    log_info "installing Claude Code (Anthropic)"
    run _user_bash 'curl -fsSL https://claude.ai/install.sh | bash'
}

install_agents_codex() { mise_use "codex" latest codex; }
install_agents_opencode() {
    mise_use "npm:opencode-ai" latest opencode || return
    # pnpm v11 skips postinstall (downloads platform binary); run it ourselves.
    # shellcheck disable=SC2016
    soft _user_bash 'p=$(find -L ~/.local/share/mise/installs/npm-opencode-ai -maxdepth 12 -path "*opencode-ai*" -name postinstall.mjs 2>/dev/null | head -1); [ -n "$p" ] && cd "$(dirname "$p")" && node postinstall.mjs'
}
install_agents_pi() { mise_use "pi" latest pi; }
install_agents_copilot_cli() { mise_use "copilot" latest copilot; }
install_agents_crush() { mise_use "crush"; }
install_agents_gemini_cli() { mise_use "gemini-cli" latest gemini; }
install_agents_goose() { mise_use "github:aaif-goose/goose"; }
install_agents_continue() { mise_use "npm:@continuedev/cli" latest cn; }
install_agents_qwen_code() { mise_use "qwen" latest qwen; }
install_agents_mistral_vibe() { mise_use "pipx:mistral-vibe" latest vibe; }
install_agents_deepseek_tui() { mise_use "npm:deepseek-tui" latest deepseek; }
install_agents_factory_droid() { mise_use "npm:droid" latest droid; }
install_agents_hermes() {
    if _user_bash 'command -v hermes' &>/dev/null; then
        log_skip "Hermes already installed"
        return 0
    fi
    log_info "installing Hermes (NousResearch)"
    run _user_bash 'curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash'
}
install_agents_kiro_cli() {
    if _user_bash 'command -v kiro-cli' &>/dev/null; then
        log_skip "Kiro CLI already installed"
        return 0
    fi
    log_info "installing Kiro CLI (AWS)"
    run _user_bash 'curl -fsSL https://cli.kiro.dev/install | bash'
}

install_agents_all() {
    _dispatch_csv agents CERVELAI_AGENTS "$(cervelai_agent_packages_csv)"
}

declare -gA _AGENT_MD_PATH=(
    [claude]=".claude/CLAUDE.md"
    [codex]=".codex/AGENTS.md"
    [opencode]=".config/opencode/AGENTS.md"
    [pi]=".pi/agent/AGENTS.md"
    [copilot]=".copilot/copilot-instructions.md"
    [gemini]=".gemini/GEMINI.md"
    [vibe]=".vibe/AGENTS.md"
    [goose]=".config/goose/.goosehints"
    [cn]=".continue/rules/agents.md"
    [qwen]=".qwen/QWEN.md"
    [droid]=".factory/AGENTS.md"
    ["kiro-cli"]=".kiro/steering/AGENTS.md"
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
