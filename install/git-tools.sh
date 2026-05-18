#!/usr/bin/env bash
# install/git-tools.sh: core (gh+delta) mandatory, rest opt-in via CERVELAI_GIT_FORGES.

install_git_tools_core() {
    mise_aqua "cli/cli"
    mise_aqua "dandavison/delta"
}

# Direct .deb download — aqua/mise can't install Gitlab-hosted projects (aqua-registry TODO).
install_git_tools_glab() {
    if has_cmd glab; then
        log_skip "glab already installed"
        return 0
    fi
    local v deb tmp
    v="$(curl -fsSL https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases | grep -oP '"tag_name":"v\K[0-9.]+' | head -1)"
    [[ -z "$v" ]] && {
        log_warn "could not resolve latest glab version, skipping"
        return 0
    }
    # mktemp -d defaults to mode 700 — apt's sandbox user `_apt` then can't read the .deb.
    tmp="$(mktemp -d)" && chmod 755 "$tmp"
    deb="$tmp/glab_${v}_linux_amd64.deb"
    log_info "downloading glab ${v} .deb from GitLab"
    run curl -fsSL -o "$deb" "https://gitlab.com/gitlab-org/cli/-/releases/v${v}/downloads/glab_${v}_linux_amd64.deb"
    chmod 644 "$deb"
    run env DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb"
    rm -rf "$tmp"
}
install_git_tools_lazygit() { mise_aqua "jesseduffield/lazygit"; }

install_git_tools_all() {
    local csv="${CERVELAI_GIT_FORGES:-}"
    [[ "$csv" == "all" ]] && csv="gitlab,lazygit"
    IFS=',' read -r -a list <<<"$csv"
    for f in "${list[@]}"; do
        f="${f// /}"
        case "$f" in
            gitlab) install_git_tools_glab ;;
            lazygit) install_git_tools_lazygit ;;
            none | "") ;;
            *) log_warn "unknown git-forges entry: $f (valid: gitlab,lazygit,none)" ;;
        esac
    done
}
