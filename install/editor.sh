#!/usr/bin/env bash
# install/editor.sh — terminal editors. CERVELAI_EDITORS=<csv>, "all" = every one.

install_editor_vim()    { apt_install vim; }
install_editor_neovim() { mise_aqua "neovim/neovim"; }
install_editor_emacs()  { apt_install emacs-nox; }
install_editor_helix()  { mise_aqua "helix-editor/helix"; }
install_editor_micro()  { apt_install micro; }

install_editor_all() {
    local csv="${CERVELAI_EDITORS:-vim,neovim}"
    [[ "$csv" == "all" ]] && csv="vim,neovim,emacs,helix,micro"
    IFS=',' read -r -a list <<< "$csv"
    for e in "${list[@]}"; do
        e="${e// /}"
        case "$e" in
            vim|neovim|emacs|helix|micro) "install_editor_$e" ;;
            none|"") log_skip "no editor requested" ;;
            *) log_warn "unknown editor in CERVELAI_EDITORS: $e (valid: vim,neovim,emacs,helix,micro,none)" ;;
        esac
    done
}
