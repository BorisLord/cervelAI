#!/usr/bin/env bash
# install/ai-tools.sh: LLM context/IO helpers. Opt-in.

install_ai_tools_all() {
    mise_use "pipx:markitdown" latest markitdown
    mise_use "go:github.com/danielmiessler/fabric" latest fabric
    mise_use "npm:@modelcontextprotocol/inspector" latest mcp-inspector
    mise_use "github:mufeedvh/code2prompt[bin=code2prompt]" latest code2prompt
    mise_aqua "charmbracelet/mods"
    mise_use "pipx:ttok" latest ttok
}
