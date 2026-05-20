# shellcheck shell=sh
# /etc/profile.d/cervelai-entry.sh: interactive-login dispatcher.
#   root → exec su - agent (re-runs profile.d as agent, covers XPipe pct enter)
#   agent → exec tmux new-session -A -s shell (auto-attach the persistent `shell` session)
#   non-interactive or already in mux → no-op

# cervelAI user — rewritten by install_shell_entry_handoff to the chosen CERVELAI_USER.
CERVELAI_ENTRY_USER=agent

[ -n "$PS1" ] || return 0 2>/dev/null
[ -n "$CERVELAI_NO_MENU" ] && return 0
[ -n "$TMUX" ] && return 0
[ -n "$ZELLIJ" ] && return 0
[ -n "$AOE_SESSION" ] && return 0
# Skip in sub-shells (topgrade's bash-it step, manual `bash`, etc.) — only fire on the top login.
# shellcheck disable=SC3028
[ "${SHLVL:-1}" -gt 1 ] && return 0

if [ "$(id -u)" = "0" ]; then
    id -u "$CERVELAI_ENTRY_USER" >/dev/null 2>&1 && exec su - "$CERVELAI_ENTRY_USER"
    return 0
fi

# Env file (GITHUB_TOKEN, NTFY_*, PNPM_HOME) — exec below replaces this shell, so it skips .bashrc.
# shellcheck source=/dev/null
[ -r "$HOME/.config/cervelAI/env" ] && . "$HOME/.config/cervelAI/env"

if command -v tmux >/dev/null 2>&1; then
    exec tmux new-session -A -s shell
elif command -v zellij >/dev/null 2>&1; then
    exec zellij attach -c shell
fi
