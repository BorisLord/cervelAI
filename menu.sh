#!/usr/bin/env bash
# menu.sh — whiptail menus for interactive setup. Sourced by setup.sh.
# Each menu_*_select() writes its result into a passed-by-name variable
# (bash nameref); returns 0 on OK, 1 on Cancel.

# Per-category description shown in the category menu.
declare -A _MENU_DESC=(
    [shell]="bash+bash-it | zsh+oh-my-zsh | fish + tmux|zellij (sub-menu)"
    [search]="rg, fd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, zoxide, hyperfine"
    [editor]="vim|neovim|emacs|helix|micro (sub-menu)"
    [git-tools]="github|gitlab|gitea forge CLIs + git-delta + lazygit (sub-menu)"
    [python-tools]="uv (pkg manager), ruff (lint+format)"
    [node-tools]="pnpm, typescript (tsc), tsx"
    [agents]="9 AI agent CLIs — pick which in the sub-menu"
    [token-savers]="snip | rtk (sub-menu)"
    [usage-trackers]="tokscale (cross-agent) + ccusage + ccstatusline"
    [ide-web]="code-server (VS Code web)"
    [containers]="docker, podman, distrobox"
)

# Defaults derived from setup.sh (single source of truth):
#   _MENU_DEFAULT_ON  = ALL_CATEGORIES (pre-checked)
#   _MENU_DEFAULT_OFF = OPTIONAL_CATEGORIES (opt-in)
# base and runtimes/mise are infrastructure — not shown here, always installed.
_MENU_DEFAULT_ON=("${ALL_CATEGORIES[@]}")
_MENU_DEFAULT_OFF=("${OPTIONAL_CATEGORIES[@]}")

# menu_select <result_var_name>
# Fills the named array with the selected categories.
menu_select() {
    local -n _cat_out="$1"
    _cat_out=()

    local args=() cat
    for cat in "${_MENU_DEFAULT_ON[@]}"; do
        args+=("$cat" "${_MENU_DESC[$cat]}" ON)
    done
    for cat in "${_MENU_DEFAULT_OFF[@]}"; do
        args+=("$cat" "${_MENU_DESC[$cat]}" OFF)
    done

    # whiptail --checklist writes the selection to stderr (3>&1 1>&2 2>&3 swap)
    local result
    result=$(whiptail --title "cervelAI: categories" \
        --checklist "Select the categories to install (Space to toggle):" \
        20 74 11 \
        "${args[@]}" \
        3>&1 1>&2 2>&3) || return 1

    local -a sel
    read -ra sel <<< "$(echo "$result" | tr -d '"')"
    _cat_out=("${sel[@]}")
    return 0
}

# menu_runtimes_select <result_var_name>
# Language runtimes (via mise). node+python pre-checked, rest off.
menu_runtimes_select() {
    local -n _rt_out="$1"
    _rt_out=()
    local args=(
        node    "JS/TS — npm agents (Codex/Gemini/Continue/Pi), tokscale, ccusage"  ON
        python  "Aider + uv tools (ruff, pytest)"                                   ON
        go      "Backend/DevOps/CLI (kubectl, traefik, Charm)"                      OFF
        rust    "Modern dev tools, systems perf"                                    OFF
        bun     "Fast JS/TS runtime (opencode uses it)"                             OFF
        deno    "Secure JS runtime"                                                 OFF
        zig     "Systems alternative to Rust"                                       OFF
        java    "Enterprise, Android, Spring"                                       OFF
        kotlin  "Android, modern JVM"                                               OFF
        dotnet  ".NET / C# / F#"                                                    OFF
        php     "Web (WordPress, Laravel, legacy)"                                  OFF
        ruby    "Rails, ops scripts"                                                OFF
        swift   "iOS, server Swift"                                                 OFF
        dart    "Flutter mobile/web"                                                OFF
        scala   "Functional JVM / data eng"                                         OFF
        elixir  "Concurrent backend (Phoenix)"                                      OFF
        erlang  "Telecom, distributed"                                              OFF
        lua     "Neovim, OpenResty, scripting"                                      OFF
    )
    local result
    result=$(whiptail --title "cervelAI: runtimes (languages)" \
        --checklist "Pick the languages to install via mise (Space to toggle):" \
        24 78 14 \
        "${args[@]}" 3>&1 1>&2 2>&3) || return 1
    local -a sel
    read -ra sel <<< "$(echo "$result" | tr -d '"')"
    _rt_out=("${sel[@]}")
    return 0
}

# menu_agents_select <result_var_name>
# AI agent CLIs. None pre-checked — the user picks deliberately.
menu_agents_select() {
    local -n _ag_out="$1"
    _ag_out=()
    local args=(
        claude-code "Claude Code — Anthropic"    OFF
        codex       "Codex CLI — OpenAI"         OFF
        opencode    "opencode — multi-provider"  OFF
        pi          "Pi.dev — Earendil"          OFF
        aider       "Aider — pair programmer"    OFF
        crush       "Crush — Charm"              OFF
        gemini-cli  "Gemini CLI — Google"        OFF
        goose       "Goose — Block"              OFF
        continue    "Continue — continue.dev"    OFF
    )
    local result
    result=$(whiptail --title "cervelAI: AI agents" \
        --checklist "Pick the AI agent CLIs to install (Space to toggle, none pre-selected):" \
        18 72 9 \
        "${args[@]}" 3>&1 1>&2 2>&3) || return 1
    local -a sel
    read -ra sel <<< "$(echo "$result" | tr -d '"')"
    _ag_out=("${sel[@]}")
    return 0
}

# menu_editors_select <result_var_name>
menu_editors_select() {
    local -n _ed_out="$1"
    _ed_out=()
    local args=(
        vim    "Vim"               ON
        neovim "Neovim"            ON
        emacs  "Emacs (emacs-nox)" OFF
        helix  "Helix"             OFF
        micro  "micro"             OFF
    )
    local result
    result=$(whiptail --title "cervelAI: editors" \
        --checklist "Pick the terminal editors (Space to toggle):" \
        14 60 5 \
        "${args[@]}" 3>&1 1>&2 2>&3) || return 1
    local -a sel
    read -ra sel <<< "$(echo "$result" | tr -d '"')"
    _ed_out=("${sel[@]}")
    return 0
}

# menu_git_forges_select <result_var_name>
menu_git_forges_select() {
    local -n _gf_out="$1"
    _gf_out=()
    local args=(
        github "GitHub CLI (gh)"   ON
        gitlab "GitLab CLI (glab)" OFF
        gitea  "Gitea CLI (tea)"   OFF
    )
    local result
    result=$(whiptail --title "cervelAI: git forges" \
        --checklist "Pick the git forge CLIs (git-delta + lazygit always installed):" \
        12 70 3 \
        "${args[@]}" 3>&1 1>&2 2>&3) || return 1
    local -a sel
    read -ra sel <<< "$(echo "$result" | tr -d '"')"
    _gf_out=("${sel[@]}")
    return 0
}

# menu_shell_select <result_var_name> — single login shell.
menu_shell_select() {
    local -n _sh_out="$1"
    local result
    result=$(whiptail --title "cervelAI: login shell" \
        --radiolist "Pick the default login shell:" \
        12 60 3 \
        bash "bash + bash-it"  ON \
        zsh  "zsh + oh-my-zsh" OFF \
        fish "fish"            OFF \
        3>&1 1>&2 2>&3) || return 1
    _sh_out="$(echo "$result" | tr -d '"')"
    return 0
}

# menu_multiplexer_select <result_var_name> — single terminal multiplexer.
menu_multiplexer_select() {
    local -n _mx_out="$1"
    local result
    result=$(whiptail --title "cervelAI: terminal multiplexer" \
        --radiolist "Pick the terminal multiplexer:" \
        12 60 3 \
        tmux   "tmux"   ON \
        zellij "zellij" OFF \
        none   "none"   OFF \
        3>&1 1>&2 2>&3) || return 1
    _mx_out="$(echo "$result" | tr -d '"')"
    return 0
}

# menu_token_saver_select <result_var_name> — single token-saver choice.
menu_token_saver_select() {
    local -n _ts_out="$1"
    local result
    result=$(whiptail --title "cervelAI: token saver" \
        --radiolist "Pick the CLI token-saver (filters noise fed to agents):" \
        13 66 4 \
        snip "snip — extensible YAML filters" ON \
        rtk  "rtk — Rust binary, hardcoded"   OFF \
        both "both"                           OFF \
        none "none"                           OFF \
        3>&1 1>&2 2>&3) || return 1
    _ts_out="$(echo "$result" | tr -d '"')"
    return 0
}
