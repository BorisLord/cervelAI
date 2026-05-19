#!/usr/bin/env bash
# install/shell.sh: shell (CERVELAI_SHELL) + multiplexer (CERVELAI_MULTIPLEXER, drives aoe).

install_shell_bash() { apt_install bash bash-completion; }
install_shell_zsh() { apt_install zsh; }
install_shell_fish() { mise_aqua "fish-shell/fish-shell"; }

install_shell_oh_my_zsh() {
    local u
    u="$(_user)"
    if [[ -d "/home/$u/.oh-my-zsh" ]]; then
        log_skip "oh-my-zsh already installed for $u"
        return 0
    fi
    log_info "installing oh-my-zsh for $u"
    run sudo -u "$u" sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
}

install_shell_bash_it() {
    local u
    u="$(_user)"
    # bash-it sets LC_CTYPE=en_US.UTF-8 — must be generated or it spams setlocale warnings.
    if ! locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
        log_info "locale-gen en_US.UTF-8 (needed by bash-it)"
        run bash -c 'sed -i "s/^# *\(en_US.UTF-8 UTF-8\)/\1/" /etc/locale.gen'
        run locale-gen en_US.UTF-8 >/dev/null
    fi
    if [[ -d "/home/$u/.bash_it" ]]; then
        log_skip "bash-it already installed for $u"
        return 0
    fi
    log_info "installing bash-it for $u"
    # Full clone (no --depth=1): bash-it's version detection and _bash-it-update need tag history.
    run sudo -u "$u" bash -c '
        git clone https://github.com/Bash-it/bash-it.git "$HOME/.bash_it" \
        && "$HOME/.bash_it/install.sh" --silent
    '
}

install_shell_tmux() { apt_install tmux; }
install_shell_zellij() { mise_use "zellij"; }

# --- aoe orchestrator (CERVELAI_MULTIPLEXER=tmux+aoe) ---

_orch_load_agent_bin() {
    # shellcheck disable=SC1091
    [[ -n "${_AGENT_BIN[*]:-}" ]] || source "${INSTALL_DIR}/agents.sh"
}

# aoe-recognized agents not installed via `agents` category — only detected if user pre-installed.
_AOE_EXTRA_AGENTS=(
    cursor copilot droid hermes kiro
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

# [bin=aoe]: release asset is aoe-linux-amd64.tar.gz, else mise names the shim aoe-linux-amd64.
install_shell_aoe() {
    mise_use "github:njbrake/agent-of-empires[bin=aoe]" latest aoe
}

# /root/.bashrc handoff covers `pct enter` (interactive non-login skips /etc/profile.d).
install_shell_entry_handoff() {
    local src_profile="${CONFIGS_DIR}/profile.d/cervelai-entry.sh"
    local src_libexec="${CONFIGS_DIR}/libexec"
    if [[ ! -r "$src_profile" || ! -d "$src_libexec" ]]; then
        log_warn "configs/profile.d/cervelai-entry.sh or configs/libexec/ missing, skip"
        return 0
    fi
    log_info "deploying /etc/profile.d/cervelai-entry.sh + /etc/skel libexec"
    run install -D -m 644 "$src_profile" /etc/profile.d/cervelai-entry.sh
    local b
    for b in "$src_libexec"/*; do
        [[ -f "$b" ]] || continue
        run install -D -m 755 "$b" "/etc/skel/.local/libexec/cervelai/$(basename "$b")"
    done

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
    # enable-linger spawns user@.service async; wait for /run/user/UID/systemd before systemctl --user.
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

# aoe install is deferred to install_shell_aoe_post_dispatch (gated on ≥1 agent installed).
install_shell_multiplexer_tmux_aoe() {
    install_shell_tmux
    install_shell_entry_handoff
}

install_shell_aoe_post_dispatch() {
    [[ "${CERVELAI_MULTIPLEXER:-tmux+aoe}" == "tmux+aoe" ]] || return 0
    _orch_load_agent_bin
    if _orch_at_least_one_agent_installed; then
        install_shell_aoe
        install_shell_aoe_serve_systemd
    else
        log_skip "no AI agent installed, skipping aoe (menu still offers shell)"
    fi
}

install_shell_all() {
    # bash always present (login shell fallback). Framework is opt-in via the -it/-omz variants.
    install_shell_bash
    case "${CERVELAI_SHELL:-bash}" in
        bash) ;;
        bash-it) install_shell_bash_it ;;
        zsh) install_shell_zsh ;;
        zsh-omz)
            install_shell_zsh
            install_shell_oh_my_zsh
            ;;
        fish) install_shell_fish ;;
        none) log_skip "shell: none (bash only, no framework)" ;;
        *) log_warn "unknown CERVELAI_SHELL=${CERVELAI_SHELL} (valid: bash,bash-it,zsh,zsh-omz,fish,none); keeping plain bash" ;;
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
