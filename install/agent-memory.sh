#!/usr/bin/env bash

install_agent_memory_memsearch() { mise_use "pipx:memsearch" latest memsearch; }
install_agent_memory_qmd() { mise_use "npm:@tobilu/qmd" latest qmd; }
install_agent_memory_engram() {
    # Pinned to 1.x — upstream also tags pi-v* (no binary assets) that mise's "latest" picks up.
    mise_use "github:Gentleman-Programming/engram[bin=engram]" "1" engram || return
    local agent bin
    for agent in claude-code:claude opencode:opencode pi:pi gemini-cli:gemini codex:codex; do
        bin="${agent##*:}"
        if _user_bash "command -v $bin" &>/dev/null; then
            soft _user_bash "engram setup ${agent%%:*}"
        fi
    done
}
install_agent_memory_claude_mem() { mise_use "npm:claude-mem" latest claude-mem; }
install_agent_memory_mcp_memory_service() { mise_use "pipx:mcp-memory-service" latest memory; }
install_agent_memory_agentmemory() { mise_use "npm:@agentmemory/agentmemory" latest agentmemory; }
install_agent_memory_beads() { mise_use "github:gastownhall/beads[bin=bd]" latest bd; }

install_agent_memory_all() {
    _dispatch_csv agent-memory CERVELAI_AGENT_MEMORY \
        "memsearch,qmd,engram,claude-mem,mcp-memory-service,agentmemory,beads"
}
