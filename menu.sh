#!/usr/bin/env bash
# menu.sh — interactive setup menus, powered by gum. Sourced by setup.sh.
# Each menu_*_select() writes its result into a passed-by-name variable:
# multi-selects fill an array, single-selects a scalar.

# Per-category descriptions. -g: sourced from a function, must be global to
# survive. No commas in the values — gum's --selected splits its list on commas.
declare -gA _MENU_DESC=(
    [shell]="bash+bash-it | zsh+oh-my-zsh | fish + tmux|zellij (sub-menu)"
    [search]="rg fd sd fzf jq yq dasel gron ast-grep typos bat eza glow zoxide tldr hyperfine"
    [editor]="vim|neovim|emacs|helix|micro (sub-menu)"
    [git-tools]="github|gitlab|gitea CLIs + delta + lazygit + gitleaks (sub-menu)"
    [agents]="9 AI agent CLIs - pick which in the sub-menu"
    [token-savers]="snip | rtk (sub-menu)"
    [usage-trackers]="tokscale (cross-agent) + ccusage + ccstatusline"
    [ide-web]="code-server (VS Code web)"
    [containers]="docker podman distrobox lazydocker"
)

# Derived from setup.sh: ON = ALL_CATEGORIES (pre-checked), OFF = OPTIONAL_CATEGORIES.
_MENU_DEFAULT_ON=("${ALL_CATEGORIES[@]}")
_MENU_DEFAULT_OFF=("${OPTIONAL_CATEGORIES[@]}")

# Items are passed as "<label>\t<value>" with --label-delimiter: gum shows the
# label (name + desc), returns the value (bare name). stdin is pinned to
# /dev/tty so gum's TUI works under `pct exec`.

# _menu_multi <result_array> <header> <name> <desc> <ON|OFF>...
# gum choose --no-limit. Fills the array (empty on cancel/none). Always returns 0.
_menu_multi() {
    local -n _mm_out="$1"; shift
    local header="$1"; shift
    local -a labels=() sel=()
    local label
    while (( $# >= 3 )); do
        label="$(printf '%-15s %s' "$1" "$2")"
        labels+=( "${label}"$'\t'"$1" )
        [[ "$3" == "ON" ]] && sel+=( "--selected=${label}" )
        shift 3
    done
    local out
    if out="$(gum choose --no-limit --height=20 --header="$header" \
                  --label-delimiter=$'\t' "${sel[@]}" -- "${labels[@]}" < /dev/tty)" \
       && [[ -n "$out" ]]; then
        mapfile -t _mm_out <<< "$out"
    else
        _mm_out=()
    fi
    return 0
}

# _menu_single <result_var> <header> <name> <desc> <ON|OFF>...
# gum choose (radio); the ON entry is the default. Returns 1 on cancel.
_menu_single() {
    local -n _ms_out="$1"; shift
    local header="$1"; shift
    local -a labels=()
    local label def_label=""
    while (( $# >= 3 )); do
        label="$(printf '%-8s %s' "$1" "$2")"
        labels+=( "${label}"$'\t'"$1" )
        [[ "$3" == "ON" ]] && def_label="$label"
        shift 3
    done
    local out
    out="$(gum choose --height=12 --header="$header" \
               --label-delimiter=$'\t' --selected="$def_label" -- "${labels[@]}" < /dev/tty)" \
        || return 1
    _ms_out="$out"
    return 0
}

menu_select() {
    local args=() cat
    for cat in "${_MENU_DEFAULT_ON[@]}";  do args+=("$cat" "${_MENU_DESC[$cat]}" ON);  done
    for cat in "${_MENU_DEFAULT_OFF[@]}"; do args+=("$cat" "${_MENU_DESC[$cat]}" OFF); done
    _menu_multi "$1" "Categories to install (Space to toggle, Enter to confirm):" "${args[@]}"
}

# Extra runtimes — node/python/pnpm/uv are infrastructure, always installed.
menu_runtimes_select() {
    _menu_multi "$1" "Extra language runtimes (node/python/pnpm/uv always installed):" \
        go     "Backend/DevOps/CLI (kubectl traefik Charm)" OFF \
        rust   "Modern dev tools - systems perf"            OFF \
        bun    "Fast JS/TS runtime (opencode uses it)"      OFF \
        deno   "Secure JS runtime"                          OFF \
        zig    "Systems alternative to Rust"                OFF \
        java   "Enterprise Android Spring"                  OFF \
        kotlin "Android - modern JVM"                       OFF \
        dotnet ".NET / C# / F#"                             OFF \
        php    "Web (WordPress Laravel legacy)"             OFF \
        ruby   "Rails - ops scripts"                        OFF \
        dart   "Flutter mobile/web"                         OFF \
        scala  "Functional JVM / data eng"                  OFF \
        elixir "Concurrent backend (Phoenix)"               OFF \
        erlang "Telecom - distributed"                      OFF \
        lua    "Neovim OpenResty scripting"                 OFF
}

menu_agents_select() {
    _menu_multi "$1" "AI agent CLIs to install (none pre-selected):" \
        claude-code "Claude Code - Anthropic"   OFF \
        codex       "Codex CLI - OpenAI"        OFF \
        opencode    "opencode - multi-provider" OFF \
        pi          "Pi.dev - Earendil"         OFF \
        aider       "Aider - pair programmer"   OFF \
        crush       "Crush - Charm"             OFF \
        gemini-cli  "Gemini CLI - Google"       OFF \
        goose       "Goose - Block"             OFF \
        continue    "Continue - continue.dev"   OFF
}

menu_editors_select() {
    _menu_multi "$1" "Terminal editors to install:" \
        vim    "Vim"               ON \
        neovim "Neovim"            ON \
        emacs  "Emacs (emacs-nox)" OFF \
        helix  "Helix"             OFF \
        micro  "micro"             OFF
}

# delta + lazygit + gitleaks are always installed alongside the chosen forges.
menu_git_forges_select() {
    _menu_multi "$1" "Git forge CLIs (delta + lazygit + gitleaks always installed):" \
        github "GitHub CLI (gh)"   ON \
        gitlab "GitLab CLI (glab)" OFF \
        gitea  "Gitea CLI (tea)"   OFF
}

menu_shell_select() {
    _menu_single "$1" "Default login shell:" \
        bash "bash + bash-it"  ON \
        zsh  "zsh + oh-my-zsh" OFF \
        fish "fish"            OFF
}

menu_multiplexer_select() {
    _menu_single "$1" "Terminal multiplexer:" \
        tmux   "tmux"   ON \
        zellij "zellij" OFF \
        none   "none"   OFF
}

menu_token_saver_select() {
    _menu_single "$1" "CLI token-saver (filters noise fed to agents):" \
        snip "snip - extensible YAML filters" ON \
        rtk  "rtk - Rust binary - hardcoded"  OFF \
        both "both"                           OFF \
        none "none"                           OFF
}
