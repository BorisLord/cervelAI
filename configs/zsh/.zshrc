# shellcheck shell=bash
# .zshrc — cervelAI (generic; tuned for a headless LXC with AI agents).

# PATH must be set before oh-my-zsh, else its completions break.
path_prepend() {
    [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
    return 0
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export GOPATH="$HOME/go"
path_prepend "$GOPATH/bin"
path_prepend "$HOME/.local/share/npm/bin"

export ZSH="$HOME/.oh-my-zsh"

if [ -d "$ZSH" ]; then
    ZSH_THEME="robbyrussell"
    plugins=(
        git
        sudo
        fzf
        history-substring-search
        command-not-found
        extract
    )
    # shellcheck source=/dev/null
    source "$ZSH/oh-my-zsh.sh"
fi

command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
    EXTENDED_HISTORY INC_APPEND_HISTORY

autoload -Uz compinit && compinit -i
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# on Debian fd-find is `fdfind`, bat is `batcat`
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd='fdfind'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'
alias t='tmux new -A -s main'
alias zr='source ~/.zshrc'

cervel() {
    case "${1:-}" in
        menu | -m) exec cervelai-menu ;;
        help | -h) cervelai-menu --cheatsheet ;;
        ls)
            local a
            for a in claude codex opencode pi aider crush gemini goose cn qwen vibe deepseek grok; do
                command -v "$a" >/dev/null 2>&1 && printf '  %s\n' "$a"
            done
            ;;
        *) printf 'usage: cervel {menu|-m | help|-h | ls}\n' >&2 ;;
    esac
}
