#!/usr/bin/env bash
# install/lsp.sh: LSP servers. Universal always; rest gated on matching runtime.

install_lsp_all() {
    mise_npm "bash-language-server"
    mise_npm "yaml-language-server"
    mise_use "taplo"
    mise_use "marksman"
    mise_npm "typescript-language-server"
    # vscode-langservers-extracted (Hayden Roszell): maintained fork containing the
    # JSON/HTML/CSS/Eslint LSPs that Microsoft stopped publishing as standalone npm packages.
    mise_use "npm:vscode-langservers-extracted" latest vscode-json-language-server
    mise_use "pipx:basedpyright" latest basedpyright
    # docker/docker-language-server (official, replaces rcjsuen + microsoft compose LSPs).
    if [[ " ${selected[*]:-} " == *" containers "* ]]; then
        mise_use "github:docker/docker-language-server[bin=docker-language-server]" latest docker-language-server
    fi
    # gopls intentionally skipped: no precompiled release upstream (Go-only ecosystem).
    _user_bash "command -v rustc" &>/dev/null && mise_use "rust-analyzer"
    _user_bash "command -v zig" &>/dev/null && mise_use "zls"
    _user_bash "command -v lua" &>/dev/null && mise_use "lua-language-server"
    _user_bash "command -v kotlin" &>/dev/null && mise_use "github:fwcd/kotlin-language-server"
    # ruby-lsp via gem (no mise backend). Idempotent.
    _user_bash "command -v ruby" &>/dev/null &&
        soft _user_bash "gem install --user-install --silent ruby-lsp"
}
