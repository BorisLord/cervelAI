#!/usr/bin/env bash
# install/base.sh: essential LXC packages, gum, locales, sshd.

install_base_apt_update() {
    log_info "apt update"
    run env DEBIAN_FRONTEND=noninteractive apt-get update -qq
}

install_base_packages() {
    apt_install \
        curl wget git build-essential ca-certificates gnupg lsb-release \
        sudo unzip xz-utils zstd \
        openssh-server mosh \
        less locales tzdata
}

install_base_locales() {
    # Extra locales are opt-in (CERVELAI_LOCALES CSV). Silences perl warnings
    # when an SSH client sends LANG=fr_FR.UTF-8 via SendEnv. locale-gen is idempotent.
    local csv="${CERVELAI_LOCALES:-}"
    [[ -z "$csv" ]] && {
        log_skip "no extra locale (set CERVELAI_LOCALES=<csv>)"
        return 0
    }
    IFS=',' read -r -a list <<<"$csv"
    log_info "locale-gen ${list[*]}"
    run locale-gen "${list[@]}" >/dev/null
}

# gum powers the interactive menus, installed before setup.sh resolves selection.
install_base_gum() {
    if has_cmd gum; then
        log_skip "gum already installed"
        return 0
    fi
    log_info "installing gum (Charm)"
    run install -dm 0755 /etc/apt/keyrings
    run bash -c 'curl -fsSL https://repo.charm.sh/apt/gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/charm.gpg'
    run chmod a+r /etc/apt/keyrings/charm.gpg
    run bash -c 'echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
        > /etc/apt/sources.list.d/charm.list'
    run env DEBIAN_FRONTEND=noninteractive apt-get update -qq
    apt_install gum
}

install_base_sshd() {
    # Debian 13 ssh.socket holds :22; standalone ssh.service would fail to re-bind.
    soft run systemctl disable --now ssh.socket
    run systemctl enable ssh.service

    # Key-only hardening: only with a key provided, else lock-out risk.
    local dropin="/etc/ssh/sshd_config.d/10-cervelAI.conf"
    if [[ -n "${CERVELAI_SSH_KEY:-}" ]]; then
        if [[ -f "$dropin" ]]; then
            log_skip "sshd hardening already applied"
        else
            log_info "hardening sshd (key-only auth)"
            run bash -c "printf 'PasswordAuthentication no\nPermitRootLogin prohibit-password\nKbdInteractiveAuthentication no\n' > '$dropin'"
        fi
    else
        log_warn "no SSH key provided, password auth left ON (set CERVELAI_SSH_KEY to harden)"
    fi

    run systemctl restart ssh.service
}

install_base_all() {
    install_base_apt_update
    install_base_packages
    install_base_gum
    install_base_locales
    install_base_sshd
}
