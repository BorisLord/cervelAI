#!/usr/bin/env bash
# install/base.sh — essential LXC packages. Sourced by setup.sh.

install_base_apt_update() {
    log_info "apt update"
    run env DEBIAN_FRONTEND=noninteractive apt-get update -qq
}

install_base_packages() {
    apt_install \
        curl wget git build-essential ca-certificates gnupg lsb-release \
        sudo unzip xz-utils zstd \
        openssh-server mosh \
        whiptail \
        less locales tzdata
}

install_base_locales() {
    if locale -a 2>/dev/null | grep -qi 'en_US.utf8'; then
        log_skip "locale en_US.UTF-8 already generated"
        return 0
    fi
    log_info "generating locale en_US.UTF-8"
    run sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    run locale-gen >/dev/null
    run update-locale LANG=en_US.UTF-8
}

install_base_sshd() {
    if systemctl is-enabled ssh &>/dev/null; then
        log_skip "sshd already enabled"
    else
        log_info "enabling sshd"
        run systemctl enable --now ssh
    fi
    # Key-only hardening — only when an SSH key was provided (else lock-out).
    local dropin="/etc/ssh/sshd_config.d/10-cervelAI.conf"
    if [[ -n "${CERVELAI_SSH_KEY:-}" ]]; then
        if [[ -f "$dropin" ]]; then
            log_skip "sshd hardening already applied"
        else
            log_info "hardening sshd (key-only auth)"
            run bash -c "printf 'PasswordAuthentication no\nPermitRootLogin prohibit-password\nKbdInteractiveAuthentication no\n' > '$dropin'"
            run systemctl reload ssh
        fi
    else
        log_warn "no SSH key provided — password auth left ON (set CERVELAI_SSH_KEY to harden)"
    fi
}

install_base_all() {
    install_base_apt_update
    install_base_packages
    install_base_locales
    install_base_sshd
}
