#!/usr/bin/env bash
# install/ai-tools.sh: LLM context/IO helpers. CERVELAI_AI_TOOLS=<csv|all>.

install_ai_tools_markitdown() { mise_use "pipx:markitdown" latest markitdown; }
install_ai_tools_fabric() { mise_use "github:danielmiessler/fabric[bin=fabric]" latest fabric; }
install_ai_tools_mcp_inspector() { mise_use "npm:@modelcontextprotocol/inspector" latest mcp-inspector; }
install_ai_tools_code2prompt() { mise_use "github:mufeedvh/code2prompt[bin=code2prompt]" latest code2prompt; }
install_ai_tools_llm() { mise_use "pipx:llm" latest llm; }
install_ai_tools_shell_gpt() { mise_use "pipx:shell-gpt" latest sgpt; }
install_ai_tools_gptscript() { mise_aqua "gptscript-ai/gptscript"; }
install_ai_tools_aichat() { mise_aqua "sigoden/aichat"; }
install_ai_tools_ttok() { mise_use "pipx:ttok" latest ttok; }

install_ai_tools_all() {
    local csv="${CERVELAI_AI_TOOLS:-}"
    [[ "$csv" == "all" ]] && csv="markitdown,fabric,mcp-inspector,code2prompt,llm,shell-gpt,gptscript,aichat,ttok"
    IFS=',' read -r -a list <<<"$csv"
    for t in "${list[@]}"; do
        t="${t// /}"
        case "$t" in
            markitdown | fabric | mcp-inspector | code2prompt | llm | shell-gpt | gptscript | aichat | ttok)
                "install_ai_tools_${t//-/_}"
                ;;
            none | "") log_skip "no ai-tools requested" ;;
            *) log_warn "unknown ai-tools in CERVELAI_AI_TOOLS: $t (valid: markitdown,fabric,mcp-inspector,code2prompt,llm,shell-gpt,gptscript,aichat,ttok,none)" ;;
        esac
    done
}
