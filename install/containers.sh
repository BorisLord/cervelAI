#!/usr/bin/env bash
# install/containers.sh: docker, podman, lazydocker, hadolint. Opt-in.
# Needs nesting=1 + keyctl=1 on the LXC (cervelAI's defaults).

install_containers_all() {
    local u="${CERVELAI_USER:-agent}"

    # Docker official APT repo (fresher than Debian's docker.io). Per-distro URL.
    if has_cmd docker; then
        log_skip "docker already installed"
    else
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
        if id -nG "$u" | grep -qw docker; then
            log_skip "$u already in docker group"
        else
            run usermod -aG docker "$u"
            log_warn "$u added to docker group, re-login required for effect"
        fi
    fi

    apt_install podman
    mise_aqua "jesseduffield/lazydocker"
    mise_aqua "hadolint/hadolint"
}
