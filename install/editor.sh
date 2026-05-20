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
        log_info "(dryrun) would write $cfg (127.0.0.1:8081)"
    else
        pw="$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 24)"
        install -d -m 700 -o "$u" -g "$u" "$(dirname "$cfg")"
        cat >"$cfg" <<EOF
bind-addr: 127.0.0.1:8081
auth: password
password: ${pw}
cert: false
EOF
        chmod 600 "$cfg"
        chown "$u:$u" "$cfg"
        log_ok "code-server config written ($cfg, http://127.0.0.1:8081)"
    fi
    soft run systemctl enable "code-server@${u}" 2>/dev/null
    log_info "code-server enabled, not started (start: sudo systemctl start code-server@${u})"
}

install_editor_all() {
    _dispatch_csv editor CERVELAI_EDITOR "vim,neovim,emacs,micro,code-server"
}
