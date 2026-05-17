#!/usr/bin/env bash
# install/containers.sh: docker, podman, lazydocker. Opt-in.
# Needs nesting=1 + keyctl=1 on the LXC (cervelAI's defaults).

install_containers_all() {
    local u="${CERVELAI_USER:-agent}"

    # Docker Engine: official APT repo (fresher than Debian's docker.io).
    if has_cmd docker; then
        log_skip "docker already installed"
    else
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
        if id -nG "$u" | grep -qw docker; then
            log_skip "$u already in docker group"
        else
            run usermod -aG docker "$u"
            log_warn "$u added to docker group, re-login required for effect"
        fi
    fi

    apt_install podman
    mise_aqua "jesseduffield/lazydocker"
}
