#!/usr/bin/env bash
# install/shell.sh: login shell + multiplexer.
#   CERVELAI_SHELL=bash|zsh|fish|none      (default: bash + bash-it)
#   CERVELAI_MULTIPLEXER=tmux|zellij|none  (default: tmux)
# A non-bash default shell is applied by setup.sh:finalize() via chsh.
# Agent orchestrator (aoe) lives in install/orchestrator.sh, runs after agents.

install_shell_bash() { apt_install bash bash-completion; }
install_shell_zsh() { apt_install zsh; }
install_shell_fish() { apt_install fish; }

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
    # bash-it sets LC_CTYPE=en_US.UTF-8 → setlocale warnings unless generated.
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
    run sudo -u "$u" bash -c '
        git clone --depth=1 https://github.com/Bash-it/bash-it.git "$HOME/.bash_it" \
        && "$HOME/.bash_it/install.sh" --silent
    '
}

install_shell_tmux() { apt_install tmux; }
install_shell_zellij() { mise_aqua "zellij-org/zellij"; }

install_shell_all() {
    case "${CERVELAI_SHELL:-bash}" in
        bash)
            install_shell_bash
            install_shell_bash_it
            ;;
        zsh)
            install_shell_bash
            install_shell_zsh
            install_shell_oh_my_zsh
            ;;
        fish)
            install_shell_bash
            install_shell_fish
            ;;
        none) log_skip "shell: none" ;;
        *)
            log_warn "unknown CERVELAI_SHELL=${CERVELAI_SHELL}, defaulting to bash"
            install_shell_bash
            install_shell_bash_it
            ;;
    esac

    case "${CERVELAI_MULTIPLEXER:-tmux}" in
        tmux) install_shell_tmux ;;
        zellij) install_shell_zellij ;;
        none) log_skip "multiplexer: none" ;;
        *)
            log_warn "unknown CERVELAI_MULTIPLEXER=${CERVELAI_MULTIPLEXER}, defaulting to tmux"
            install_shell_tmux
            ;;
    esac
}
