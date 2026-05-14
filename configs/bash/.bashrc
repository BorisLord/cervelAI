# .bashrc — cervelAI (the VM's default shell).
# The optional zsh shell has its own config in ../zsh/.

# Nothing interactive in a non-interactive shell — non-interactive runs go
# through ai-run, which sources ~/.config/cervelAI/env itself.
case $- in *i*) ;; *) return ;; esac

# ─── cervelAI environment (mise shims PATH + API keys + ntfy) ─────────────────
[ -r "$HOME/.config/cervelAI/env" ] && . "$HOME/.config/cervelAI/env"

# ─── PATH ─────────────────────────────────────────────────────────────────────
path_prepend() { [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"; return 0; }
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/share/npm/bin"   # npm agents (Codex, Gemini CLI…)
path_prepend "$HOME/.pi/bin"                 # Pi.dev
export GOPATH="$HOME/go"; path_prepend "$GOPATH/bin"
[ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ─── mise (version switch on cd) ──────────────────────────────────────────────
[ -x "$HOME/.local/bin/mise" ] && eval "$("$HOME/.local/bin/mise" activate bash)"

# ─── bash-it ──────────────────────────────────────────────────────────────────
if [ -d "$HOME/.bash_it" ]; then
    export BASH_IT="$HOME/.bash_it"
    export BASH_IT_THEME=''        # prompt handled by starship, not bash-it
    # shellcheck source=/dev/null
    source "$BASH_IT/bash_it.sh"
fi

# ─── starship ─────────────────────────────────────────────────────────────────
command -v starship &>/dev/null && eval "$(starship init bash)"

# ─── history ──────────────────────────────────────────────────────────────────
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize

# ─── fzf ──────────────────────────────────────────────────────────────────────
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/bash-completion/completions/fzf ] && . /usr/share/bash-completion/completions/fzf

# ─── aliases ──────────────────────────────────────────────────────────────────
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd='fdfind'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'
alias t='tmux new -A -s main'
alias br='source ~/.bashrc'

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
        ""|list|ls)  printf 'agents: claude codex opencode pi aider crush gemini goose cn\n' ;;
        *)           printf 'unknown agent: %s\n' "$1" >&2; return 1 ;;
    esac
}
