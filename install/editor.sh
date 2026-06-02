#!/usr/bin/env bash

install_editor_vim() { apt_install vim; }
install_editor_neovim() { mise_use "neovim"; }
install_editor_emacs() { apt_install emacs-nox; }
install_editor_micro() { mise_aqua "micro-editor/micro"; }

install_editor_code_server() {
    if has_cmd code-server; then
        log_skip "code-server already installed"
        return 0
    fi
    log_info "installing code-server"
    run sh -c 'curl -fsSL https://code-server.dev/install.sh | sh'
    local u cfg pw
    u="$(_user)"
    cfg="/home/$u/.config/code-server/config.yaml"
    if ((DRY_RUN)); then
        log_info "(dryrun) would write $cfg (0.0.0.0:8081, LAN)"
    else
        pw="$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 24)"
        if [[ ${#pw} -ne 24 ]]; then
            log_err "could not generate code-server password (urandom unavailable?), skipping config"
            return 1
        fi
        install -d -m 700 -o "$u" -g "$u" "$(dirname "$cfg")"
        # bind LAN (0.0.0.0) so it's reachable at http://<host-ip>:8081; gated by the password below.
        # A browser IDE is a code-execution surface, so the firewall only opens 8081 when code-server
        # is installed, and the password is the only guard — keep it on a trusted LAN.
        cat >"$cfg" <<EOF
bind-addr: 0.0.0.0:8081
auth: password
password: ${pw}
cert: false
EOF
        chmod 600 "$cfg"
        chown "$u:$u" "$cfg"
        log_ok "code-server config written ($cfg, http://<host-ip>:8081, password-gated)"
    fi
    soft run systemctl enable "code-server@${u}" 2>/dev/null
    log_info "code-server enabled, not started (start: sudo systemctl start code-server@${u})"
}

install_editor_all() {
    _dispatch_csv editor CERVELAI_EDITOR "vim,neovim,emacs,micro,code-server"
}
