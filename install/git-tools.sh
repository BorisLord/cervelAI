#!/usr/bin/env bash
# install/git-tools.sh — forge CLIs (CERVELAI_GIT_FORGES=<csv>) + delta, lazygit,
# gitleaks (always installed). gitleaks: an autonomous agent shouldn't commit secrets.

install_git_tools_gh()       { mise_aqua "cli/cli"; }
# glab lives on gitlab.com — mise's short name resolves to its gitlab backend.
# tea has no GitHub/aqua path — it's a Go program on gitea.com, install via go:.
install_git_tools_glab()     { mise_use "glab"; }
install_git_tools_tea()      { mise_use "go"; mise_use "go:code.gitea.io/tea"; }
install_git_tools_delta()    { mise_aqua "dandavison/delta"; }
install_git_tools_lazygit()  { mise_aqua "jesseduffield/lazygit"; }
install_git_tools_gitleaks() { mise_aqua "gitleaks/gitleaks"; }

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
    install_git_tools_gitleaks
}
