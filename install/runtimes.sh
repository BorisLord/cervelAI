#!/usr/bin/env bash
# install/runtimes.sh — mise + language runtimes.
# CERVELAI_RUNTIMES=<csv>  (default: "node,python"; "all" = every language).
# An interactive whiptail sub-menu picks the selection.
#   node    required by Codex, Gemini CLI, Continue, Pi, tokscale, ccusage
#   python  Aider + uv tools
#   also: go rust bun deno zig java kotlin dotnet php ruby swift dart scala
#         elixir erlang lua  — anything else: `mise use -g <lang>@<ver>`

install_runtimes_mise() {
    local u; u="$(_user)"
    if [[ -x "/home/$u/.local/bin/mise" ]]; then
        log_skip "mise already installed for $u"; return 0
    fi
    log_info "installing mise for $u"
    run sudo -u "$u" sh -c 'curl -fsSL https://mise.run | sh'
    # Interactive mise activation lives in the shipped shell configs; the shims
    # PATH for non-interactive shells lives in ~/.config/cervelAI/env.
}

install_runtimes_node()    { mise_use "node"    "lts"; }
install_runtimes_python()  { mise_use "python"  "latest"; }
install_runtimes_go()      { mise_use "go"      "latest"; }
install_runtimes_rust()    { mise_use "rust"    "latest"; }
install_runtimes_bun()     { mise_use "bun"     "latest"; }
install_runtimes_deno()    { mise_use "deno"    "latest"; }
install_runtimes_zig()     { mise_use "zig"     "latest"; }
install_runtimes_java()    { mise_use "java"    "latest"; }
install_runtimes_kotlin()  { mise_use "kotlin"  "latest"; }
install_runtimes_dotnet()  { mise_use "dotnet"  "latest"; }
install_runtimes_php()     { mise_use "php"     "latest"; }
install_runtimes_ruby()    { mise_use "ruby"    "latest"; }
install_runtimes_swift()   { mise_use "swift"   "latest"; }
install_runtimes_dart()    { mise_use "dart"    "latest"; }
install_runtimes_scala()   { mise_use "scala"   "latest"; }
install_runtimes_elixir()  { mise_use "elixir"  "latest"; }
install_runtimes_erlang()  { mise_use "erlang"  "latest"; }
install_runtimes_lua()     { mise_use "lua"     "latest"; }

install_runtimes_all() {
    install_runtimes_mise
    local csv="${CERVELAI_RUNTIMES:-node,python}"
    [[ "$csv" == "all" ]] && csv="node,python,go,rust,bun,deno,zig,java,kotlin,dotnet,php,ruby,swift,dart,scala,elixir,erlang,lua"
    IFS=',' read -r -a list <<< "$csv"
    for r in "${list[@]}"; do
        r="${r// /}"
        case "$r" in
            node|python|go|rust|bun|deno|zig|java|kotlin|dotnet|php|ruby|swift|dart|scala|elixir|erlang|lua)
                "install_runtimes_$r" ;;
            none|"")
                log_skip "no extra runtime requested" ;;
            *)
                log_warn "unknown runtime in CERVELAI_RUNTIMES: $r (see install/runtimes.sh for the valid list)" ;;
        esac
    done
}
