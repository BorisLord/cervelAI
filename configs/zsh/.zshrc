# shellcheck shell=bash
# .zshrc — cervelAI (generic; tuned for a headless LXC with AI agents).

# ─── PATH (before oh-my-zsh, else its completions break) ──────────────────────
path_prepend() {
    [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
    return 0
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/share/mise/shims"
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export GOPATH="$HOME/go"
path_prepend "$GOPATH/bin"
path_prepend "$HOME/.local/share/npm/bin"   # npm agents (Claude Code, Codex, Gemini CLI)
path_prepend "$HOME/.pi/bin"                 # Pi.dev

# ─── oh-my-zsh ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

if [ -d "$ZSH" ]; then
    ZSH_THEME=""   # prompt handled by starship, not oh-my-zsh
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

# ─── mise activate ────────────────────────────────────────────────────────────
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
fi

# ─── fzf bindings ─────────────────────────────────────────────────────────────
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ]   && source /usr/share/doc/fzf/examples/completion.zsh

# ─── history ──────────────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       EXTENDED_HISTORY INC_APPEND_HISTORY

# ─── completion ───────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit -i
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# ─── aliases ──────────────────────────────────────────────────────────────────
# on Debian fd-find is `fdfind`, bat is `batcat`
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd='fdfind'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'
alias t='tmux new -A -s main'
alias zr='source ~/.zshrc'

# ─── quick switch between AI agents ───────────────────────────────────────────
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
        ""|list|ls)
            printf 'Available agents:\n  claude codex opencode pi aider crush gemini goose cn\n'
            ;;
        *) printf 'unknown agent: %s\n' "$1"; return 1 ;;
    esac
}

# ─── cervelAI environment (BYOK) ──────────────────────────────────────────────
# mise shims PATH + API keys + ntfy config live in ~/.config/cervelAI/env,
# loaded via ~/.zshenv (sourced by zsh in all contexts).
