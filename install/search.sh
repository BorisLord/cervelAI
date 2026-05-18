#!/usr/bin/env bash
# install/search.sh: AI-critical search/parsing CLIs (mandatory). Human extras in install/cli-extras.sh.

install_search_all() {
    mise_aqua "BurntSushi/ripgrep"
    mise_aqua "sharkdp/fd"
    mise_aqua "junegunn/fzf"
    mise_aqua "jqlang/jq"
    mise_aqua "mikefarah/yq"
    mise_aqua "TomWright/dasel"
    mise_aqua "tomnomnom/gron"
    mise_aqua "ast-grep/ast-grep"
    mise_aqua "sharkdp/bat"
}
