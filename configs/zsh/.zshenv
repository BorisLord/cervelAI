# .zshenv — sourced by zsh in ALL contexts (interactive, non-interactive, login).
# Loads the cervelAI environment so a non-interactively launched agent
# (e.g. ssh host 'pi ...') sees the mise shims PATH and the API keys.
[ -r "$HOME/.config/cervelAI/env" ] && . "$HOME/.config/cervelAI/env"
