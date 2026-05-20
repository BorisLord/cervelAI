#!/usr/bin/env bash

install_git_tools_core() {
    mise_use "github-cli" latest gh
    mise_use "delta"
}

# No mise registry entry; ships as a .deb on GitLab releases.
install_git_tools_gitlab() {
    if has_cmd glab; then
        log_skip "glab already installed"
        return 0
    fi
    local v deb tmp
    if ((DRY_RUN)); then
        log_info "(dryrun) would resolve+install latest glab .deb from GitLab"
        return 0
    fi
    v="$(curl -fsSL https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases | grep -oP '"tag_name":"v\K[0-9.]+' | head -1)"
    [[ -z "$v" ]] && {
        log_warn "could not resolve latest glab version, skipping"
        return 0
    }
    tmp="$(mktemp -d)"
    deb="$tmp/glab_${v}_linux_amd64.deb"
    log_info "downloading glab ${v} .deb from GitLab"
    run curl -fsSL -o "$deb" "https://gitlab.com/gitlab-org/cli/-/releases/v${v}/downloads/glab_${v}_linux_amd64.deb"
    run env DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb"
    rm -rf "$tmp"
}
install_git_tools_lazygit() { mise_use "lazygit"; }

install_git_tools_all() {
    _dispatch_csv git-tools CERVELAI_GIT_TOOLS "gitlab,lazygit"
}
