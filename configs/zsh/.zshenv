# shellcheck shell=bash
# Non-interactive zsh (e.g. `ssh host 'pi ...'`) loads only .zshenv, so PATH lives here.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh --shims)"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH" ;;
esac

# shellcheck source=/dev/null
[ -r "$HOME/.config/cervelAI/env" ] && . "$HOME/.config/cervelAI/env"
