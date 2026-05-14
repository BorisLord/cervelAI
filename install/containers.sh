#!/usr/bin/env bash
# install/containers.sh — docker, podman, distrobox. Opt-in via --custom.
# NOTE: Docker in an unprivileged LXC needs nesting=1 + keyctl=1 in the pct config.

install_containers_docker() {
    if has_cmd docker; then
        log_skip "docker already installed"; return 0
    fi
    log_info "installing Docker Engine via official APT repo"
    run install -dm 0755 /etc/apt/keyrings
    run bash -c 'curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg'
    run chmod a+r /etc/apt/keyrings/docker.gpg
    run bash -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list'
    run env DEBIAN_FRONTEND=noninteractive apt-get update -qq
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # add the user to the docker group
    local u="${CERVELAI_USER:-agent}"
    if id -nG "$u" | grep -qw docker; then
        log_skip "$u already in docker group"
    else
        run usermod -aG docker "$u"
        log_warn "$u added to docker group — re-login required for effect"
    fi
}

install_containers_podman() {
    apt_install podman
}

install_containers_distrobox() {
    if has_cmd distrobox; then
        log_skip "distrobox already installed"; return 0
    fi
    apt_install distrobox
}

install_containers_all() {
    log_warn "Docker/Podman in an unprivileged LXC require 'nesting=1' on the container."
    log_warn "→ if not set: on the Proxmox host run 'pct set <CTID> --features nesting=1,keyctl=1', then restart the LXC."
    install_containers_docker
    install_containers_podman
    install_containers_distrobox
}
