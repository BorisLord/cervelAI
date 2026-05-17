# shellcheck shell=sh
# /etc/profile.d/cervelai-entry.sh: interactive-login dispatcher.
#   root → exec su - agent (re-runs profile.d as agent, covers XPipe pct enter)
#   agent → exec ~/.local/bin/cervelai-menu
#   non-interactive or already in mux → no-op

[ -n "$PS1" ] || return 0 2>/dev/null
[ -n "$CERVELAI_NO_MENU" ] && return 0
[ -n "$TMUX" ] && return 0
[ -n "$ZELLIJ" ] && return 0
[ -n "$AOE_SESSION" ] && return 0

if [ "$(id -u)" = "0" ]; then
    id -u agent >/dev/null 2>&1 && exec su - agent
    return 0
fi

# PATH: menu needs claude/opencode/aoe/engram; /etc/profile doesn't add ~/.local; exec skips .bashrc.
for d in "$HOME/.local/bin" "$HOME/.local/share/mise/shims"; do
    [ -d "$d" ] && export PATH="$d:$PATH"
done

[ -x "$HOME/.local/bin/cervelai-menu" ] || return 0
exec "$HOME/.local/bin/cervelai-menu"
