#!/usr/bin/env bash
# install/editor.sh: terminal editors. CERVELAI_EDITORS=<csv|all>.

install_editor_vim() { apt_install vim; }
install_editor_neovim() { mise_aqua "neovim/neovim"; }
install_editor_emacs() { apt_install emacs-nox; }
install_editor_micro() { mise_aqua "micro-editor/micro"; }
# Helix grammars: 245 tree-sitter repo clones. GIT_TERMINAL_PROMPT=0 avoids creds prompts
# on dead repos (e.g. gotmpl 404'd upstream). soft: partial fetch doesn't fail setup.
install_editor_helix() {
    mise_aqua "helix-editor/helix" || return
    soft _user_bash "GIT_TERMINAL_PROMPT=0 hx --grammar fetch"
}

install_editor_all() {
    local csv="${CERVELAI_EDITORS:-none}"
    [[ "$csv" == "all" ]] && csv="vim,neovim,emacs,helix,micro"
    IFS=',' read -r -a list <<<"$csv"
    for e in "${list[@]}"; do
        e="${e// /}"
        case "$e" in
            vim | neovim | emacs | helix | micro) "install_editor_$e" ;;
            none | "") log_skip "no editor requested" ;;
            *) log_warn "unknown editor in CERVELAI_EDITORS: $e (valid: vim,neovim,emacs,helix,micro,none)" ;;
        esac
    done
}
