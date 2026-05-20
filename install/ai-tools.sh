#!/usr/bin/env bash

install_ai_tools_markitdown() { mise_use "pipx:markitdown" latest markitdown; }
install_ai_tools_fabric() { mise_use "github:danielmiessler/fabric[bin=fabric]" latest fabric; }
install_ai_tools_code2prompt() { mise_use "github:mufeedvh/code2prompt[bin=code2prompt]" latest code2prompt; }
install_ai_tools_llm() { mise_use "pipx:llm" latest llm; }
install_ai_tools_shell_gpt() { mise_use "pipx:shell-gpt" latest sgpt; }
install_ai_tools_gptscript() { mise_aqua "gptscript-ai/gptscript"; }
install_ai_tools_aichat() { mise_use "aichat"; }
install_ai_tools_agents() { mise_use "npm:@agents-dev/cli" latest agents; }
# pnpm v11 fails to compile better-sqlite3 native bindings (allowBuilds not honored for globals); bun handles it.
install_ai_tools_promptfoo() {
    _user_bash "command -v bun" &>/dev/null || mise_use "bun" "latest"
    soft _user_bash "bun add -g promptfoo"
}

install_ai_tools_all() {
    _dispatch_csv ai-tools CERVELAI_AI_TOOLS \
        "markitdown,fabric,code2prompt,llm,shell-gpt,gptscript,aichat,agents,promptfoo"
}
