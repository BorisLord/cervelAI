# shellcheck shell=bash
# shellcheck source=/dev/null
[ -r "$HOME/.config/cervelAI/env" ] && . "$HOME/.config/cervelAI/env"

path_prepend() {
    [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
    return 0
}
path_prepend "$HOME/.local/share/mise/shims"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/share/npm/bin"
path_prepend "$HOME/.bun/bin"
export GOPATH="$HOME/go"
path_prepend "$GOPATH/bin"
path_prepend "$HOME/.ghcup/bin"
for _gemdir in "$HOME"/.local/share/gem/ruby/*/bin; do [ -d "$_gemdir" ] && path_prepend "$_gemdir"; done
# shellcheck source=/dev/null
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

case $- in *i*) ;; *) return ;; esac

command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"

if [ -d "$HOME/.bash_it" ]; then
    export BASH_IT="$HOME/.bash_it"
    export BASH_IT_THEME='bobby'
    # bash-it's auto-restart fires on any non-empty value; unset to prevent mid-session exec bash.
    unset BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE
    # shellcheck source=/dev/null
    source "$BASH_IT/bash_it.sh"
fi

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize

# shellcheck source=/dev/null
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
# shellcheck source=/dev/null
[ -f /usr/share/bash-completion/completions/fzf ] && . /usr/share/bash-completion/completions/fzf

command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd='fdfind'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'
alias t='tmux new -A -s shell'
alias br='source ~/.bashrc'

complete -W "help status ls run -h -s" cervel
