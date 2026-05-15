#!/usr/bin/env bash
# install/agent-memory.sh — cross-session memory tools. CERVELAI_AGENT_MEMORY=<csv>, "all" = every one.

install_agent_memory_memsearch()        { mise_use "pipx:memsearch" latest memsearch; }
install_agent_memory_qmd()              { mise_use "npm:@tobilu/qmd" latest qmd; }
install_agent_memory_engram()           { mise_use "github:Gentleman-Programming/engram" latest engram; }
install_agent_memory_claude_mem()       { mise_use "npm:claude-mem" latest claude-mem; }
install_agent_memory_mcp_memory_service() { mise_use "pipx:mcp-memory-service" latest memory; }
install_agent_memory_agentmemory()      { mise_use "npm:@agentmemory/agentmemory" latest agentmemory; }

install_agent_memory_all() {
    local csv="${CERVELAI_AGENT_MEMORY:-}"
    [[ "$csv" == "all" ]] && csv="memsearch,qmd,engram,claude-mem,mcp-memory-service,agentmemory"
    IFS=',' read -r -a list <<< "$csv"
    for m in "${list[@]}"; do
        m="${m// /}"
        case "$m" in
            memsearch|qmd|engram|claude-mem|mcp-memory-service|agentmemory)
                "install_agent_memory_${m//-/_}" ;;
            none|"") log_skip "no agent-memory tool requested" ;;
            *) log_warn "unknown agent-memory in CERVELAI_AGENT_MEMORY: $m (valid: memsearch,qmd,engram,claude-mem,mcp-memory-service,agentmemory,none)" ;;
        esac
    done
}
