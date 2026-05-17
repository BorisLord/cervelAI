# shellcheck shell=sh
# /etc/profile.d/cervelai-entry.sh: interactive-login entry point.
#   root (XPipe pct enter)         -> exec su - agent (re-runs profile.d as agent)
#   other interactive user         -> exec ~/.local/bin/cervelai-menu if present
#   non-interactive / in mux       -> no-op (original shell continues)

# Non-interactive (ssh host cmd, scp, sftp, cron): bail.
[ -n "$PS1" ] || return 0 2>/dev/null

# User opted out of the menu for this shell (set by menu's "plain shell" path).
[ -n "$CERVELAI_NO_MENU" ] && return 0

# Already in a multiplexer or aoe session: avoid recursion.
[ -n "$TMUX" ] && return 0
[ -n "$ZELLIJ" ] && return 0
[ -n "$AOE_SESSION" ] && return 0

# Root: jump to agent (re-evaluates /etc/profile.d as agent).
if [ "$(id -u)" = "0" ]; then
    id -u agent >/dev/null 2>&1 && exec su - agent
    return 0
fi

# Add ~/.local/bin and mise shims to PATH so the menu can find claude, opencode,
# aoe, engram, etc. /etc/profile doesn't, and exec'ing the menu skips .bashrc.
for d in "$HOME/.local/bin" "$HOME/.local/share/mise/shims"; do
    [ -d "$d" ] && export PATH="$d:$PATH"
done

# Launch the menu if installed.
[ -x "$HOME/.local/bin/cervelai-menu" ] || return 0
exec "$HOME/.local/bin/cervelai-menu"
