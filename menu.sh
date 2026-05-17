#!/usr/bin/env bash
# menu.sh: gum-powered setup menus. Sourced by setup.sh. Each menu_*_select writes via nameref.

# -g: sourced from a function (must survive). No commas: gum's --selected splits on commas.
declare -gA _MENU_DESC=(
    ["editor"]="vim|neovim|emacs|helix|micro (sub-menu)"
    ["agents"]="9 AI agent CLIs, pick which in the sub-menu"
    ["orchestrator"]="cervelai-entry menu + aoe (Agent of Empires TUI/web) if any agent installed"
    ["token-savers"]="snip | rtk (sub-menu)"
    ["usage-trackers"]="tokscale (cross-agent) + ccusage + ccstatusline"
    ["ide-web"]="code-server (VS Code web)"
    ["containers"]="docker podman lazydocker hadolint"
    ["data-stack"]="sqlite3 psql redis-cli usql duckdb mlr (DB clients + data analysis)"
    ["agent-memory"]="memsearch | qmd | engram | claude-mem | mcp-memory-service | agentmemory (sub-menu)"
    ["ai-tools"]="markitdown fabric mcp-inspector code2prompt mods ttok (LLM helpers)"
)

_MENU_DEFAULT_OFF=("${CATEGORIES[@]}")

# Item format: "<label>\t<value>" with --label-delimiter — gum displays label, returns value.
# /dev/tty pin: gum TUI works under pct exec without a controlling tty inherited.

# _menu_multi <result_array> <header> <name> <desc> <ON|OFF>... — always rc=0, [] on cancel.
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

# _menu_single <result_var> <header> <name> <desc> <ON|OFF>... — radio, rc=1 on cancel.
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

menu_git_forges_select() {
    _menu_multi "$1" "Git forge CLIs (delta+lazygit+gitleaks always installed):" \
        github "GitHub: gh" ON \
        gitlab "GitLab: glab" OFF \
        gitea "Gitea/Codeberg/Forgejo: tea" OFF
}

# shellcheck disable=SC2154  # selected[] lives in caller's scope (main in setup.sh).
_menu_in_selected() { [[ " ${selected[*]:-} " == *" $1 "* ]]; }

menu_summary_confirm() {
    {
        printf '\n──── Selection summary ────\n'
        printf '  Categories:    %s\n' "${selected[*]:-(none)}"
        printf '  Runtimes+:     %s\n' "${CERVELAI_RUNTIMES:-(none, node/python/pnpm/uv only)}"
        printf '  Baseline:      shell (%s+%s) + search CLI + git-tools (%s)\n' \
            "${CERVELAI_SHELL:-bash}" "${CERVELAI_MULTIPLEXER:-tmux}" "${CERVELAI_GIT_FORGES:-github}"
        [[ -n "${CERVELAI_AGENTS:-}" ]] && printf '  Agents:        %s\n' "$CERVELAI_AGENTS"
        [[ -n "${CERVELAI_EDITORS:-}" ]] && printf '  Editors:       %s\n' "$CERVELAI_EDITORS"
        [[ -n "${CERVELAI_TOKEN_SAVER:-}" ]] && printf '  Token-saver:   %s\n' "$CERVELAI_TOKEN_SAVER"
        [[ -n "${CERVELAI_AGENT_MEMORY:-}" ]] && printf '  Agent memory:  %s\n' "$CERVELAI_AGENT_MEMORY"
        _menu_in_selected orchestrator && printf '  Orchestrator:  aoe (gated on at least one AI agent installed)\n'
        _menu_in_selected data-stack && printf '  Data stack:    sqlite3, psql, redis-cli, usql, duckdb, mlr\n'
        _menu_in_selected containers && printf '  Containers:    docker, podman, lazydocker, hadolint\n'
        _menu_in_selected ide-web && printf '  IDE web:       code-server\n'
        _menu_in_selected usage-trackers && printf '  Usage:         tokscale, ccusage, ccstatusline\n'
        _menu_in_selected ai-tools && printf '  AI tools:      markitdown, fabric, mcp-inspector, code2prompt, mods, ttok\n'
        printf '\n'
    } >/dev/tty
    gum confirm --default=Yes "Install with these choices?" </dev/tty
}
