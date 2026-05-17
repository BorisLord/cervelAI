#!/usr/bin/env bash
# install/ide-web.sh: code-server (VS Code in browser). Opt-in.

install_ide_web_all() {
    if has_cmd code-server; then
        log_skip "code-server already installed"
        return 0
    fi
    log_info "installing code-server"
    run sh -c 'curl -fsSL https://code-server.dev/install.sh | sh'
    local u="${CERVELAI_USER:-agent}"
    soft run systemctl enable "code-server@${u}" 2>/dev/null
    log_info "code-server enabled but not started"
    log_info "start: sudo systemctl start code-server@${u}"
    log_info "config: /home/${u}/.config/code-server/config.yaml"
}
