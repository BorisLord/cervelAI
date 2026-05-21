#!/usr/bin/env bash

install_shell_bash() { apt_install bash bash-completion; }
install_shell_zsh() { apt_install zsh; }

install_shell_tmux() { apt_install tmux; }
install_shell_zellij() { mise_use "zellij"; }

_orch_load_agent_bin() {
    # shellcheck disable=SC1091
    [[ -n "${_AGENT_BIN[*]:-}" ]] || source "${INSTALL_DIR}/agents.sh"
}

# aoe-recognized but not in registry; copilot excluded (covered by copilot-cli in _AGENT_BIN).
_AOE_EXTRA_AGENTS=(
    cursor droid hermes kiro
)

_orch_at_least_one_agent_installed() {
    local u
    u="$(_user)"
    local home="/home/$u"

    if has_cmd aoe; then
        sudo -u "$u" env \
            PATH="$home/.local/bin:$home/.local/share/mise/shims:/usr/local/bin:/usr/bin:/bin" \
            aoe agents 2>/dev/null | grep -q '✓'
        return $?
    fi

    local a p
    for a in "${_AGENT_BIN[@]}" "${_AOE_EXTRA_AGENTS[@]}"; do
        for p in "$home/.local/bin/$a" \
            "$home/.local/share/mise/shims/$a" \
            "/usr/local/bin/$a" \
            "/usr/bin/$a"; do
            if [[ -x "$p" ]]; then
                log_info "found agent: $a ($p)"
                return 0
            fi
        done
    done
    return 1
}

# [bin=aoe]: without it mise names the shim after the tarball (aoe-linux-amd64).
install_shell_aoe() {
    mise_use "github:njbrake/agent-of-empires[bin=aoe]" latest aoe
}

# Ship cervelAI's aoe defaults (empire theme + cockpit). Skip if the user already has a config.
install_shell_aoe_config() {
    local u home src dest
    u="$(_user)"
    home="/home/$u"
    src="${CONFIGS_DIR}/agent-of-empires/config.toml"
    dest="$home/.config/agent-of-empires/config.toml"
    [[ -r "$src" ]] || {
        log_warn "configs/agent-of-empires/config.toml missing, skip"
        return 0
    }
    if [[ -e "$dest" ]]; then
        log_skip "aoe config already present"
        return 0
    fi
    log_info "deploying aoe config (empire theme + cockpit)"
    run install -D -m 644 -o "$u" -g "$u" "$src" "$dest"
}

# Cockpit renders ACP agents natively; install npm ACP adapters for the ACP-capable
# agents present. gemini/opencode are native, aoe-agent is bundled — no adapter needed.
install_shell_cockpit_adapters() {
    # <agent binary>:<npm adapter package>:<adapter binary>
    local triples=(
        "claude:@agentclientprotocol/claude-agent-acp:claude-agent-acp"
        "codex:@zed-industries/codex-acp:codex-acp"
        "pi:pi-acp:pi-acp"
    )
    local t bin pkg adbin
    for t in "${triples[@]}"; do
        bin="${t%%:*}"
        pkg="${t#*:}"
        pkg="${pkg%:*}"
        adbin="${t##*:}"
        _user_bash "command -v $bin" &>/dev/null || continue
        mise_use "npm:$pkg" latest "$adbin"
    done
}

# `pct enter` is interactive non-login; /etc/profile.d is skipped, so /root/.bashrc must source the handoff.
install_shell_entry_handoff() {
    local src_profile="${CONFIGS_DIR}/profile.d/cervelai-entry.sh"
    local src_libexec="${CONFIGS_DIR}/libexec"
    if [[ ! -r "$src_profile" || ! -d "$src_libexec" ]]; then
        log_warn "configs/profile.d/cervelai-entry.sh or configs/libexec/ missing, skip"
        return 0
    fi
    log_info "deploying /etc/profile.d/cervelai-entry.sh + /etc/skel libexec"
    run install -D -m 644 "$src_profile" /etc/profile.d/cervelai-entry.sh
    # Bake the chosen user in (default in the shipped file is `agent`).
    run sed -i "s/^CERVELAI_ENTRY_USER=agent$/CERVELAI_ENTRY_USER=$(_user)/" /etc/profile.d/cervelai-entry.sh
    _deploy_libexec /etc/skel/.local/libexec/cervelai

    local marker='# cervelai-entry handoff'
    local snippet='
# cervelai-entry handoff (added by cervelAI provisioner)
case $- in *i*)
    [ -r /etc/profile.d/cervelai-entry.sh ] && . /etc/profile.d/cervelai-entry.sh
;; esac'
    local f
    for f in /root/.bashrc /etc/skel/.bashrc; do
        if grep -qF "$marker" "$f" 2>/dev/null; then
            log_skip "handoff already in $f"
        else
            log_info "appending handoff to $f"
            run bash -c "printf '%s\n' \"\$1\" >> '$f'" -- "$snippet"
        fi
    done
}

install_shell_aoe_serve_systemd() {
    local u
    u="$(_user)"
    local src="${CONFIGS_DIR}/systemd/aoe-serve.service"
    local home="/home/$u"
    local unit_dir="$home/.config/systemd/user"
    [[ -r "$src" ]] || {
        log_warn "configs/systemd/aoe-serve.service missing, skip"
        return 0
    }

    log_info "deploying aoe-serve.service (user=$u) + enabling linger"
    run install -D -m 644 -o "$u" -g "$u" "$src" "$unit_dir/aoe-serve.service"
    # `install -D` as root leaves parents root-owned; systemctl --user needs $u to own wants/.
    run chown -R "$u:$u" "$home/.config/systemd"
    soft run loginctl enable-linger "$u"
    # enable-linger is async; wait for /run/user/UID/systemd before systemctl --user.
    local uid xdg
    uid="$(id -u "$u")"
    xdg="/run/user/$uid"
    for _ in {1..20}; do
        [[ -S "$xdg/systemd/private" ]] && break
        sleep 0.5
    done
    soft run sudo -u "$u" XDG_RUNTIME_DIR="$xdg" systemctl --user daemon-reload
    soft run sudo -u "$u" XDG_RUNTIME_DIR="$xdg" systemctl --user enable --now aoe-serve.service
}

install_shell_multiplexer_tmux_aoe() {
    install_shell_tmux
    install_shell_entry_handoff
}

install_shell_aoe_post_dispatch() {
    [[ "${CERVELAI_MULTIPLEXER:-tmux+aoe}" == "tmux+aoe" ]] || return 0
    _orch_load_agent_bin
    if _orch_at_least_one_agent_installed; then
        install_shell_aoe
        install_shell_aoe_config
        install_shell_cockpit_adapters
        install_shell_aoe_serve_systemd
    else
        log_skip "no AI agent installed, skipping aoe (menu still offers shell)"
    fi
}

install_shell_all() {
    case "${CERVELAI_SHELL:-bash}" in
        bash) ;;
        zsh) install_shell_zsh ;;
        none) log_skip "shell: none (bash only)" ;;
        *) log_warn "unknown CERVELAI_SHELL=${CERVELAI_SHELL} (valid: bash,zsh,none); keeping plain bash" ;;
    esac

    case "${CERVELAI_MULTIPLEXER:-tmux+aoe}" in
        tmux+aoe) install_shell_multiplexer_tmux_aoe ;;
        zellij) install_shell_zellij ;;
        none) log_skip "multiplexer: none (direct shell login, no persistence)" ;;
        *)
            log_warn "unknown CERVELAI_MULTIPLEXER=${CERVELAI_MULTIPLEXER} (valid: tmux+aoe,zellij,none), defaulting to tmux+aoe"
            install_shell_multiplexer_tmux_aoe
            ;;
    esac
}
