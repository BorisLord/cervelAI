#!/usr/bin/env bash
# menu.sh: interactive setup menus, powered by gum. Sourced by setup.sh.
# Each menu_*_select() writes into a passed-by-name variable (array or scalar).

# Per-category descriptions. -g: sourced from a function, must be global to
# survive. No commas in the values (gum's --selected splits on commas).
declare -gA _MENU_DESC=(
    ["shell"]="bash+bash-it | zsh+oh-my-zsh | fish + tmux|zellij (sub-menu)"
    ["search"]="rg fd sd fzf jq yq dasel gron ast-grep typos bat eza glow zoxide tldr hyperfine shfmt"
    ["editor"]="vim|neovim|emacs|helix|micro (sub-menu)"
    ["git-tools"]="github|gitlab|gitea CLIs + delta + lazygit + gitleaks (sub-menu)"
    ["agents"]="9 AI agent CLIs, pick which in the sub-menu"
    ["orchestrator"]="cervelai-entry menu + aoe (Agent of Empires TUI/web) if any agent installed"
    ["token-savers"]="snip | rtk (sub-menu)"
    ["usage-trackers"]="tokscale (cross-agent) + ccusage + ccstatusline"
    ["ide-web"]="code-server (VS Code web)"
    ["containers"]="docker podman lazydocker"
    ["db"]="sqlite3 + psql + redis-cli + usql (universal SQL)"
    ["http"]="xh (modern curl)"
    ["data"]="duckdb + miller (mlr): SQL on CSV/Parquet/JSON"
    ["agent-memory"]="memsearch | qmd | engram | claude-mem | mcp-memory-service | agentmemory (sub-menu)"
)

# Categories ship as OFF: user picks deliberately. Sourced from setup.sh.
_MENU_DEFAULT_OFF=("${CATEGORIES[@]}")

# Items pass as "<label>\t<value>" with --label-delimiter: gum shows the label,
# returns the value. stdin pinned to /dev/tty so gum's TUI works under pct exec.

# _menu_multi <result_array> <header> <name> <desc> <ON|OFF>...
# gum choose --no-limit. Fills the array (empty on cancel/none). Always returns 0.
_menu_multi() {
    local -n _mm_out="$1"
    shift
    local header="$1"
    shift
    local -a labels=() sel=()
    local label
    while (($# >= 3)); do
        label="$(printf '%-15s %s' "$1" "$2")"
        labels+=("${label}"$'\t'"$1")
        [[ "$3" == "ON" ]] && sel+=("--selected=${label}")
        shift 3
    done
    local out
    if out="$(gum choose --no-limit --height=20 --header="$header" \
        --label-delimiter=$'\t' "${sel[@]}" -- "${labels[@]}" </dev/tty)" &&
        [[ -n "$out" ]]; then
        mapfile -t _mm_out <<<"$out"
    else
        _mm_out=()
    fi
    return 0
}

# _menu_single <result_var> <header> <name> <desc> <ON|OFF>...
# gum choose (radio); the ON entry is the default. Returns 1 on cancel.
_menu_single() {
    local -n _ms_out="$1"
    shift
    local header="$1"
    shift
    local -a labels=()
    local label def_label=""
    while (($# >= 3)); do
        label="$(printf '%-8s %s' "$1" "$2")"
        labels+=("${label}"$'\t'"$1")
        [[ "$3" == "ON" ]] && def_label="$label"
        shift 3
    done
    local out
    out="$(gum choose --height=12 --header="$header" \
        --label-delimiter=$'\t' --selected="$def_label" -- "${labels[@]}" </dev/tty)" ||
        return 1
    _ms_out="$out"
    return 0
}

menu_select() {
    local args=() cat
    for cat in "${_MENU_DEFAULT_OFF[@]}"; do args+=("$cat" "${_MENU_DESC[$cat]}" OFF); done
    _menu_multi "$1" "Categories to install (Space to toggle ON, Enter to confirm. Nothing pre-selected.):" "${args[@]}"
}

menu_runtimes_select() {
    _menu_multi "$1" "Extra language runtimes (node/python/pnpm/uv always installed):" \
        go "Backend/DevOps/CLI (kubectl traefik Charm)" OFF \
        rust "Modern dev tools, systems perf" OFF \
        bun "Fast JS/TS runtime (opencode uses it)" OFF \
        deno "Secure JS runtime" OFF \
        zig "Systems alternative to Rust" OFF \
        java "Enterprise Android Spring" OFF \
        kotlin "Android, modern JVM" OFF \
        dotnet ".NET / C# / F#" OFF \
        php "Web (WordPress Laravel legacy)" OFF \
        ruby "Rails, ops scripts" OFF \
        dart "Flutter mobile/web" OFF \
        scala "Functional JVM / data eng" OFF \
        elixir "Concurrent backend (Phoenix)" OFF \
        erlang "Telecom, distributed" OFF \
        lua "Neovim OpenResty scripting" OFF
}

menu_agents_select() {
    _menu_multi "$1" "AI agent CLIs to install (none pre-selected):" \
        claude-code "Claude Code (Anthropic)" OFF \
        codex "Codex CLI (OpenAI)" OFF \
        opencode "opencode (multi-provider)" OFF \
        pi "Pi.dev (Earendil)" OFF \
        aider "Aider (pair programmer)" OFF \
        crush "Crush (Charm)" OFF \
        gemini-cli "Gemini CLI (Google)" OFF \
        goose "Goose (Block)" OFF \
        continue "Continue (continue.dev)" OFF
}

menu_editors_select() {
    _menu_multi "$1" "Terminal editors to install (none pre-selected):" \
        vim "Vim" OFF \
        neovim "Neovim" OFF \
        emacs "Emacs (emacs-nox)" OFF \
        helix "Helix" OFF \
        micro "micro" OFF
}

menu_git_forges_select() {
    _menu_multi "$1" "Git forge CLIs (delta + lazygit + gitleaks always installed):" \
        github "GitHub CLI (gh)" ON \
        gitlab "GitLab CLI (glab)" OFF \
        gitea "Gitea CLI (tea)" OFF
}

menu_shell_select() {
    _menu_single "$1" "Default login shell:" \
        bash "bash + bash-it" ON \
        zsh "zsh + oh-my-zsh" OFF \
        fish "fish" OFF
}

menu_multiplexer_select() {
    _menu_single "$1" "Terminal multiplexer:" \
        tmux "tmux" ON \
        zellij "zellij" OFF \
        none "none" OFF
}

menu_agent_memory_select() {
    _menu_multi "$1" "Agent memory tools (none pre-selected, multi-select):" \
        memsearch "lite: project Markdown memory" OFF \
        qmd "lite: BM25/hybrid search facts/notes" OFF \
        engram "lite: Go binary, cross-agent (CLI+MCP)" OFF \
        claude-mem "heavy: daemon, multi-IDE hooks" OFF \
        mcp-memory-service "heavy: SQLite + ONNX, MCP + HTTP API" OFF \
        agentmemory "heavy: 51 MCP tools, viewer, 107 endp" OFF
}

menu_token_saver_select() {
    _menu_single "$1" "CLI token-saver (filters noise fed to agents, pick one):" \
        snip "snip: extensible YAML filters" ON \
        rtk "rtk: Rust binary, hardcoded" OFF \
        none "none" OFF
}

# shellcheck disable=SC2154  # selected[] comes from caller's scope (main in setup.sh).
_menu_in_selected() { [[ " ${selected[*]:-} " == *" $1 "* ]]; }

menu_summary_confirm() {
    {
        printf '\n──── Selection summary ────\n'
        printf '  Categories:    %s\n' "${selected[*]:-(none)}"
        printf '  Runtimes+:     %s\n' "${CERVELAI_RUNTIMES:-(none, node/python/pnpm/uv only)}"
        [[ -n "${CERVELAI_AGENTS:-}" ]] && printf '  Agents:        %s\n' "$CERVELAI_AGENTS"
        [[ -n "${CERVELAI_EDITORS:-}" ]] && printf '  Editors:       %s\n' "$CERVELAI_EDITORS"
        [[ -n "${CERVELAI_GIT_FORGES:-}" ]] && printf '  Git forges:    %s\n' "$CERVELAI_GIT_FORGES"
        [[ -n "${CERVELAI_SHELL:-}" ]] && printf '  Shell:         %s + %s\n' "$CERVELAI_SHELL" "${CERVELAI_MULTIPLEXER:-tmux}"
        [[ -n "${CERVELAI_TOKEN_SAVER:-}" ]] && printf '  Token-saver:   %s\n' "$CERVELAI_TOKEN_SAVER"
        [[ -n "${CERVELAI_AGENT_MEMORY:-}" ]] && printf '  Agent memory:  %s\n' "$CERVELAI_AGENT_MEMORY"
        _menu_in_selected search && printf '  Search:        rg, fd, sd, fzf, jq, yq, bat, eza, shfmt, ...\n'
        _menu_in_selected orchestrator && printf '  Orchestrator:  aoe (gated on at least one AI agent installed)\n'
        _menu_in_selected db && printf '  DB:            sqlite3, psql, redis-cli, usql\n'
        _menu_in_selected http && printf '  HTTP:          xh\n'
        _menu_in_selected data && printf '  Data:          duckdb, mlr (miller)\n'
        _menu_in_selected containers && printf '  Containers:    docker, podman, lazydocker\n'
        _menu_in_selected ide-web && printf '  IDE web:       code-server\n'
        _menu_in_selected usage-trackers && printf '  Usage:         tokscale, ccusage, ccstatusline\n'
        printf '\n'
    } >/dev/tty
    gum confirm --default=Yes "Install with these choices?" </dev/tty
}
