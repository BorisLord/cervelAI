#!/usr/bin/env bash
# install/lsp.sh: LSP servers. Universal always; rest gated on matching runtime.

install_lsp_all() {
    mise_npm "bash-language-server"
    mise_npm "yaml-language-server"
    mise_aqua "tamasfe/taplo"
    mise_aqua "artempyanykh/marksman"
    mise_npm "typescript-language-server"
    mise_npm "vscode-json-languageserver"
    mise_use "pipx:basedpyright" latest basedpyright
    if [[ " ${selected[*]:-} " == *" containers "* ]]; then
        mise_use "npm:dockerfile-language-server-nodejs" latest docker-langserver
        mise_use "npm:@microsoft/compose-language-service" latest docker-compose-langserver
    fi
    _user_bash "command -v go" &>/dev/null && mise_use "go:golang.org/x/tools/gopls"
    _user_bash "command -v rustc" &>/dev/null && mise_aqua "rust-lang/rust-analyzer"
    _user_bash "command -v zig" &>/dev/null && mise_aqua "zigtools/zls"
    _user_bash "command -v scala" &>/dev/null && mise_aqua "scalameta/metals"
    _user_bash "command -v lua" &>/dev/null && mise_aqua "LuaLS/lua-language-server"
    _user_bash "command -v php" &>/dev/null && mise_npm "intelephense"
    _user_bash "command -v kotlin" &>/dev/null && mise_use "github:fwcd/kotlin-language-server"
    _user_bash "command -v dotnet" &>/dev/null && mise_use "github:razzmatazz/csharp-language-server" latest csharp-ls
    _user_bash "command -v elixir" &>/dev/null && mise_use "github:elixir-tools/next-ls"
    _user_bash "command -v erl" &>/dev/null && mise_use "github:erlang-ls/erlang_ls"
    # Skip: java (jdtls brittle), ruby (gem install ruby-lsp). Built-in: dart/deno; bun uses ts-ls.
}
