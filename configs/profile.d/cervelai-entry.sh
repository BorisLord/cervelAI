# shellcheck shell=sh
# rewritten by install_shell_entry_handoff to the chosen CERVELAI_USER.
CERVELAI_ENTRY_USER=agent

[ -n "$PS1" ] || return 0 2>/dev/null
[ -n "$CERVELAI_NO_MENU" ] && return 0
[ -n "$TMUX" ] && return 0
[ -n "$ZELLIJ" ] && return 0
[ -n "$AOE_SESSION" ] && return 0
# shellcheck disable=SC3028
[ "${SHLVL:-1}" -gt 1 ] && return 0

if [ "$(id -u)" = "0" ]; then
    id -u "$CERVELAI_ENTRY_USER" >/dev/null 2>&1 && exec su - "$CERVELAI_ENTRY_USER"
    return 0
fi

# exec replaces this shell, so .bashrc is skipped; source env manually.
# shellcheck source=/dev/null
[ -r "$HOME/.config/cervelAI/env" ] && . "$HOME/.config/cervelAI/env"

if command -v tmux >/dev/null 2>&1; then
    exec tmux new-session -A -s shell
elif command -v zellij >/dev/null 2>&1; then
    exec zellij attach -c shell
fi
