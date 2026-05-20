#!/usr/bin/env bash
# install/lsp.sh: LSP servers. core runs early; runtime-gated runs after opt-in runtimes exist.

install_lsp_core() {
    mise_npm "bash-language-server"
    mise_npm "yaml-language-server"
    mise_use "taplo"
    mise_use "marksman"
    mise_npm "typescript-language-server"
    mise_use "npm:vscode-langservers-extracted" latest vscode-json-language-server
    mise_use "pipx:basedpyright" latest basedpyright
    if [[ " ${selected[*]:-} " == *" containers "* ]]; then
        mise_use "github:docker/docker-language-server[bin=docker-language-server]" latest docker-language-server
    fi
}

install_lsp_runtime_gated() {
    # rustup proxy in ~/.cargo/bin shadows mise shims; installing via rustup avoids the
    # "infinite recursion detected" error when the component is missing.
    _user_bash "command -v rustc" &>/dev/null &&
        soft _user_bash "rustup component add rust-analyzer"
    _user_bash "command -v zig" &>/dev/null && mise_use "zls"
    _user_bash "command -v lua" &>/dev/null && mise_use "lua-language-server"
    _user_bash "command -v kotlin" &>/dev/null && mise_use "github:fwcd/kotlin-language-server"
    _user_bash "command -v ruby" &>/dev/null &&
        soft _user_bash "gem install --user-install --silent ruby-lsp"
}
