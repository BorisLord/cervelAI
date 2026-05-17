#!/usr/bin/env bash
# install/orchestrator.sh: aoe + entry menu. Skips aoe if no AI agent installed.

# Mirrors `aoe agents` for the bootstrap path (aoe not yet installed).
_AOE_KNOWN_AGENTS=(
    claude opencode codex gemini pi aider crush goose vibe
    cursor copilot droid hermes kiro qwen
)

# 0 if at least one AI agent binary is reachable by the agent user.
_orch_at_least_one_agent_installed() {
    local u
    u="$(_user)"
    local home="/home/$u"

    if has_cmd aoe; then
        sudo -u "$u" env \
            PATH="$home/.local/bin:$home/.local/share/mise/shims:/usr/local/bin:/usr/bin:/bin" \
            aoe agents 2>/dev/null | grep -qE '^[[:space:]]*✓'
        return $?
    fi

    local a p
    for a in "${_AOE_KNOWN_AGENTS[@]}"; do
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

# bin=aoe required: release asset is aoe-linux-amd64.tar.gz, mise would otherwise name the shim aoe-linux-amd64.
install_orchestrator_aoe() {
    mise_use "github:njbrake/agent-of-empires[bin=aoe]" latest aoe
}

# /etc/profile.d entry + /etc/skel menu + /root/.bashrc handoff for `pct enter` (interactive non-login).
install_orchestrator_entry() {
    local src_profile="${CONFIGS_DIR}/profile.d/cervelai-entry.sh"
    local src_menu="${CONFIGS_DIR}/bin/cervelai-menu"
    if [[ ! -r "$src_profile" || ! -r "$src_menu" ]]; then
        log_warn "configs/profile.d/cervelai-entry.sh or configs/bin/cervelai-menu missing, skip"
        return 0
    fi
    log_info "deploying /etc/profile.d/cervelai-entry.sh + /etc/skel menu"
    run install -D -m 644 "$src_profile" /etc/profile.d/cervelai-entry.sh
    run install -D -m 755 "$src_menu" /etc/skel/.local/bin/cervelai-menu

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

# systemd --user `aoe serve` (web LAN dashboard). enable-linger keeps it up without a session.
install_orchestrator_aoe_serve_systemd() {
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
    # install -D ran as root: fix ownership so systemctl --user finds wants/.
    run chown -R "$u:$u" "$home/.config/systemd"
    soft run loginctl enable-linger "$u"
    soft run sudo -u "$u" XDG_RUNTIME_DIR="/run/user/$(id -u "$u")" \
        systemctl --user daemon-reload
    soft run sudo -u "$u" XDG_RUNTIME_DIR="/run/user/$(id -u "$u")" \
        systemctl --user enable --now aoe-serve.service
}

install_orchestrator_all() {
    install_orchestrator_entry
    if _orch_at_least_one_agent_installed; then
        install_orchestrator_aoe
        install_orchestrator_aoe_serve_systemd
    else
        log_skip "no AI agent installed, skipping aoe (menu still offers shell)"
    fi
}
