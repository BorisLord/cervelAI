# .bashrc — cervelAI (the VM's default shell).
# The optional zsh shell has its own config in ../zsh/.

# Interactive-only — non-interactive runs go through ai-run, which loads the env itself.
case $- in *i*) ;; *) return ;; esac

[ -r "$HOME/.config/cervelAI/env" ] && . "$HOME/.config/cervelAI/env"

path_prepend() { [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"; return 0; }
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/share/npm/bin"
path_prepend "$HOME/.pi/bin"
export GOPATH="$HOME/go"; path_prepend "$GOPATH/bin"
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"

if [ -d "$HOME/.bash_it" ]; then
    export BASH_IT="$HOME/.bash_it"
    export BASH_IT_THEME='bobby'
    # shellcheck source=/dev/null
    source "$BASH_IT/bash_it.sh"
fi

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize

[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/bash-completion/completions/fzf ] && . /usr/share/bash-completion/completions/fzf

command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd='fdfind'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'
alias t='tmux new -A -s main'
alias br='source ~/.bashrc'

ai() {
    case "${1:-}" in
        claude|cc)   shift; command claude "$@" ;;
        codex|cx)    shift; command codex "$@" ;;
        opencode|oc) shift; command opencode "$@" ;;
        pi)          shift; command pi "$@" ;;
        aider)       shift; command aider "$@" ;;
        crush)       shift; command crush "$@" ;;
        gemini|gem)  shift; command gemini "$@" ;;
        goose)       shift; command goose "$@" ;;
        continue|cn) shift; command cn "$@" ;;
        ""|list|ls)  printf 'agents: claude codex opencode pi aider crush gemini goose cn\n' ;;
        *)           printf 'unknown agent: %s\n' "$1" >&2; return 1 ;;
    esac
}
