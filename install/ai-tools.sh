#!/usr/bin/env bash
# install/ai-tools.sh: LLM context/IO helpers. CERVELAI_AI_TOOLS=<csv|all>.

install_ai_tools_markitdown() { mise_use "pipx:markitdown" latest markitdown; }
install_ai_tools_fabric() { mise_use "github:danielmiessler/fabric[bin=fabric]" latest fabric; }
install_ai_tools_code2prompt() { mise_use "github:mufeedvh/code2prompt[bin=code2prompt]" latest code2prompt; }
install_ai_tools_llm() { mise_use "pipx:llm" latest llm; }
install_ai_tools_shell_gpt() { mise_use "pipx:shell-gpt" latest sgpt; }
install_ai_tools_gptscript() { mise_aqua "gptscript-ai/gptscript"; }
install_ai_tools_aichat() { mise_use "aichat"; }
# Cross-agent config sync (AGENTS.md canonical, skills, MCP). Complements cervelAI's symlinks.
install_ai_tools_agents() { mise_use "npm:@agents-dev/cli" latest agents; }
# pnpm v11 fails to compile better-sqlite3's native bindings (allowBuilds not honored
# for globals). bun handles native modules correctly out-of-the-box.
install_ai_tools_promptfoo() {
    _user_bash "command -v bun" &>/dev/null || mise_use "bun" "latest"
    soft _user_bash "bun add -g promptfoo"
}

install_ai_tools_all() {
    _dispatch_csv ai-tools CERVELAI_AI_TOOLS \
        "markitdown,fabric,code2prompt,llm,shell-gpt,gptscript,aichat,agents,promptfoo"
}
