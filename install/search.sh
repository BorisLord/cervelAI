#!/usr/bin/env bash
# install/search.sh: search/navigation/parsing CLIs, all via mise (aqua).

install_search_all() {
    mise_aqua "BurntSushi/ripgrep"
    mise_aqua "sharkdp/fd"
    mise_aqua "chmln/sd"
    mise_aqua "junegunn/fzf"
    mise_aqua "jqlang/jq"
    mise_aqua "mikefarah/yq"
    mise_aqua "TomWright/dasel"
    mise_aqua "tomnomnom/gron"
    mise_aqua "ast-grep/ast-grep"
    mise_aqua "crate-ci/typos"
    mise_aqua "sharkdp/bat"
    mise_aqua "eza-community/eza"
    mise_aqua "charmbracelet/glow"
    mise_aqua "ajeetdsouza/zoxide"
    mise_use "aqua:tealdeer-rs/tealdeer" latest tldr
    mise_aqua "sharkdp/hyperfine"
    mise_aqua "mvdan/sh"
    mise_aqua "koalaman/shellcheck"
    mise_aqua "hadolint/hadolint"
}
