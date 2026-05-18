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
    # gopls intentionally skipped: no precompiled release upstream (Go-only ecosystem).
    _user_bash "command -v rustc" &>/dev/null && mise_aqua "rust-lang/rust-analyzer"
    _user_bash "command -v zig" &>/dev/null && mise_aqua "zigtools/zls"
    _user_bash "command -v lua" &>/dev/null && mise_aqua "LuaLS/lua-language-server"
    _user_bash "command -v kotlin" &>/dev/null && mise_use "github:fwcd/kotlin-language-server"
    # ruby-lsp via gem (no mise backend). Idempotent.
    _user_bash "command -v ruby" &>/dev/null &&
        soft _user_bash "gem install --user-install --silent ruby-lsp"
}
