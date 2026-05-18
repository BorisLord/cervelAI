#!/usr/bin/env bash
# install/containers.sh: container runtimes + tooling. CERVELAI_CONTAINERS=<csv|all>.
# LXC needs nesting=1 + keyctl=1 (cervelAI's defaults).

install_containers_docker() {
    local u
    u="$(_user)"
    if has_cmd docker; then
        log_skip "docker already installed"
    else
        # Docker's own APT repo — fresher than Debian's docker.io package.
        local distro_id
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}" in
            debian | ubuntu) distro_id="$ID" ;;
            *)
                if [[ "${ID_LIKE:-}" == *"ubuntu"* ]]; then
                    distro_id=ubuntu
                elif [[ "${ID_LIKE:-}" == *"debian"* ]]; then
                    distro_id=debian
                else
                    log_warn "unknown distro for docker repo, falling back to debian"
                    distro_id=debian
                fi
                ;;
        esac
        log_info "installing Docker Engine via official APT repo ($distro_id)"
        run install -dm 0755 /etc/apt/keyrings
        run bash -c "curl -fsSL https://download.docker.com/linux/${distro_id}/gpg \
            | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
        run chmod a+r /etc/apt/keyrings/docker.gpg
        run bash -c "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/${distro_id} \$(lsb_release -cs) stable\" \
            > /etc/apt/sources.list.d/docker.list"
        run env DEBIAN_FRONTEND=noninteractive apt-get update -qq
        apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    if id -nG "$u" | grep -qw docker; then
        log_skip "$u already in docker group"
    else
        run usermod -aG docker "$u"
        log_warn "$u added to docker group, re-login required for effect"
    fi
}

install_containers_podman() { apt_install podman; }
install_containers_lazydocker() { mise_aqua "jesseduffield/lazydocker"; }
install_containers_hadolint() { mise_aqua "hadolint/hadolint"; }
install_containers_dive() { mise_aqua "wagoodman/dive"; }

install_containers_all() {
    local csv="${CERVELAI_CONTAINERS:-}"
    [[ "$csv" == "all" ]] && csv="docker,podman,lazydocker,hadolint,dive"
    IFS=',' read -r -a list <<<"$csv"
    for c in "${list[@]}"; do
        c="${c// /}"
        case "$c" in
            docker | podman | lazydocker | hadolint | dive)
                "install_containers_$c"
                ;;
            none | "") log_skip "no containers tool requested" ;;
            *) log_warn "unknown containers in CERVELAI_CONTAINERS: $c (valid: docker,podman,lazydocker,hadolint,dive,none)" ;;
        esac
    done
}
