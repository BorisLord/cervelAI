#!/usr/bin/env bash

install_base_apt_update() {
    run bash -c 'echo "DPkg::Lock::Timeout \"300\";" > /etc/apt/apt.conf.d/99cervelai-lock-timeout'
    log_info "apt update + upgrade"
    run env DEBIAN_FRONTEND=noninteractive apt-get update -qq
    # confdef+confold: keep existing config files on conflicts (no interactive prompt).
    run env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        -o Dpkg::Options::=--force-confdef \
        -o Dpkg::Options::=--force-confold
    run env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
}

install_base_packages() {
    apt_install \
        curl wget git build-essential ca-certificates gnupg lsb-release \
        sudo unzip xz-utils zstd \
        openssh-server mosh \
        less locales tzdata \
        xclip
}

# C.UTF-8 is built into glibc (no locale-gen needed); LC_ALL overrides any locale SSH forwards via SendEnv.
install_base_locales() {
    log_info "update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8"
    run update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8
    local csv="${CERVELAI_LOCALES:-}"
    [[ -z "$csv" ]] && return 0
    IFS=',' read -r -a list <<<"$csv"
    log_info "locale-gen ${list[*]}"
    run locale-gen "${list[@]}" >/dev/null
}

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

# Security patches as root via the stock apt-daily timers. The no-sudo agent can't apt, so without
# this the box is never patched after install. Stock 50unattended-upgrades only pulls *-security.
install_base_unattended() {
    apt_install unattended-upgrades
    # Own the setting deterministically — don't rely on the package's debconf default being "on".
    log_info "enabling unattended-upgrades (security auto-updates)"
    run bash -c "printf 'APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Unattended-Upgrade \"1\";\n' > /etc/apt/apt.conf.d/20auto-upgrades"
}

install_base_sshd() {
    # Recent Debian/Ubuntu use ssh.socket; absent on older releases (soft absorbs the error).
    soft run systemctl disable --now ssh.socket
    run systemctl enable ssh.service

    # Gated on a key being provided — hardening without a key would lock out the user.
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

install_base_nftables() {
    apt_install nftables
    ((DRY_RUN)) && {
        log_skip "nftables ruleset (dryrun)"
        return 0
    }
    log_info "deploying default-deny firewall (nftables)"
    cat >/etc/nftables.conf <<'NFT'
#!/usr/sbin/nft -f
# Manage only our own table (no global flush) so Docker's iptables-nft rules survive.
table inet cervelai {}
delete table inet cervelai
table inet cervelai {
    chain input {
        type filter hook input priority filter; policy drop;
        iif "lo" accept
        ct state established,related accept
        ct state invalid drop
        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept
        tcp dport { 22, 8080 } accept
        udp dport 60000-61000 accept
    }
    chain forward { type filter hook forward priority filter; policy accept; }
}
NFT
    # enable --now starts it on a fresh box (service active); nft -f then force-applies our ruleset
    # since `enable --now` won't reload an already-running service. We avoid `restart`, whose
    # Debian ExecStop=`nft flush ruleset` would wipe Docker's rules.
    soft run systemctl enable --now nftables
    soft run nft -f /etc/nftables.conf
}

install_base_all() {
    install_base_apt_update
    install_base_packages
    install_base_unattended
    install_base_gum
    install_base_locales
    install_base_sshd
    install_base_nftables
}
