#!/usr/bin/env bash
# install/search.sh — search/navigation/parsing CLI tools, all via mise (aqua).

install_search_ripgrep()  { mise_aqua "BurntSushi/ripgrep"; }
install_search_fd()       { mise_aqua "sharkdp/fd"; }
install_search_sd()       { mise_aqua "chmln/sd"; }
install_search_fzf()      { mise_aqua "junegunn/fzf"; }
install_search_jq()       { mise_aqua "jqlang/jq"; }
install_search_yq()       { mise_aqua "mikefarah/yq"; }
install_search_dasel()    { mise_aqua "TomWright/dasel"; }
install_search_gron()     { mise_aqua "tomnomnom/gron"; }
install_search_astgrep()  { mise_aqua "ast-grep/ast-grep"; }
install_search_typos()    { mise_aqua "crate-ci/typos"; }
install_search_bat()      { mise_aqua "sharkdp/bat"; }
install_search_eza()      { mise_aqua "eza-community/eza"; }
install_search_glow()     { mise_aqua "charmbracelet/glow"; }
install_search_zoxide()   { mise_aqua "ajeetdsouza/zoxide"; }
install_search_tldr()     { mise_use "aqua:tealdeer-rs/tealdeer" latest tldr; }
install_search_hyperfine() { mise_aqua "sharkdp/hyperfine"; }

install_search_all() {
    install_search_ripgrep
    install_search_fd
    install_search_sd
    install_search_fzf
    install_search_jq
    install_search_yq
    install_search_dasel
    install_search_gron
    install_search_astgrep
    install_search_typos
    install_search_bat
    install_search_eza
    install_search_glow
    install_search_zoxide
    install_search_tldr
    install_search_hyperfine
}
