#!/usr/bin/env bash

install_containers_docker() {
    local u
    u="$(_user)"
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
    fi
    if id -nG "$u" | grep -qw docker; then
        log_skip "$u already in docker group"
    else
        run usermod -aG docker "$u"
        log_warn "$u added to docker group, re-login required for effect"
    fi
}

install_containers_podman() {
    # uidmap + slirp4netns + passt(pasta) are Recommends; without them rootless podman fails
    apt_install podman uidmap slirp4netns passt
    local u
    u="$(_user)"
    if ! grep -q "^${u}:" /etc/subuid 2>/dev/null; then
        run usermod --add-subuids 100000-165535 "$u"
        log_ok "subuid range added for $u"
    else
        log_skip "subuid already set for $u"
    fi
    if ! grep -q "^${u}:" /etc/subgid 2>/dev/null; then
        run usermod --add-subgids 100000-165535 "$u"
        log_ok "subgid range added for $u"
    else
        log_skip "subgid already set for $u"
    fi
    if ! _user_bash "podman info" &>/dev/null; then
        log_warn "rootless podman not functional in unprivileged LXC (kernel uid_map limit); use 'sudo podman' for rootful mode"
    fi
}
install_containers_lazydocker() { mise_use "lazydocker"; }
install_containers_hadolint() { mise_use "hadolint"; }
install_containers_dive() { mise_use "dive"; }

install_containers_all() {
    _dispatch_csv containers CERVELAI_CONTAINERS "docker,podman,lazydocker,hadolint,dive"
}
