#!/usr/bin/env bash
# install/git-tools.sh — git forge CLIs + delta + lazygit.
# CERVELAI_GIT_FORGES=<csv>  (default: "github"; "all" = every forge)
#   github → gh, gitlab → glab, gitea → tea (also Codeberg/Forgejo), none
# git-delta and lazygit are always installed (forge-independent).

install_git_tools_gh()      { mise_aqua "cli/cli"; }
install_git_tools_glab()    { mise_aqua "gitlab-org/cli"; }
install_git_tools_tea()     { mise_aqua "gitea/tea"; }
install_git_tools_delta()   { mise_aqua "dandavison/delta"; }
install_git_tools_lazygit() { mise_aqua "jesseduffield/lazygit"; }

install_git_tools_all() {
    local csv="${CERVELAI_GIT_FORGES:-github}"
    [[ "$csv" == "all" ]] && csv="github,gitlab,gitea"
    IFS=',' read -r -a list <<< "$csv"
    for f in "${list[@]}"; do
        f="${f// /}"
        case "$f" in
            github)                  install_git_tools_gh ;;
            gitlab)                  install_git_tools_glab ;;
            gitea|codeberg|forgejo)  install_git_tools_tea ;;
            none|"")                 ;;
            *) log_warn "unknown git forge in CERVELAI_GIT_FORGES: $f (valid: github,gitlab,gitea,none)" ;;
        esac
    done
    install_git_tools_delta
    install_git_tools_lazygit
}
