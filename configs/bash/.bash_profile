# .bash_profile — sourced by bash login shells (ssh). Delegates to .bashrc.
# shellcheck source=/dev/null
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
