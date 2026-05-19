#!/usr/bin/env bash
# install/editor.sh: terminal editors. CERVELAI_EDITOR=<csv|all>.

install_editor_vim() { apt_install vim; }
install_editor_neovim() { mise_use "neovim"; }
install_editor_emacs() { apt_install emacs-nox; }
install_editor_micro() { mise_aqua "micro-editor/micro"; }

install_editor_all() {
    _dispatch_csv editor CERVELAI_EDITOR "vim,neovim,emacs,micro"
}
