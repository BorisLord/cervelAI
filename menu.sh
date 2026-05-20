#!/usr/bin/env bash
# -g: sourced inside a function; must survive. No commas in values: gum --selected splits on commas.
declare -gA _MENU_DESC=(
    ["agents"]="AI agent CLIs: claude/codex/opencode/pi/copilot/gemini/qwen/... (sub)"
    ["token-savers"]="snip | rtk (cut shell output 60-90% before reaching agents)"
    ["agent-memory"]="cross-session memory: memsearch/qmd/engram/claude-mem/... (sub)"
    ["usage-trackers"]="token/cost trackers: tokscale + ccusage + ccstatusline"
    ["ai-tools"]="LLM helpers: code2prompt/fabric/llm/markitdown/... (sub)"
    ["editor"]="vim/neovim/emacs/micro + code-server (sub)"
    ["runtimes"]="extra runtimes: go/rust/bun/deno/zig/java/.../haskell (sub)"
    ["containers"]="docker/podman/lazydocker/hadolint/dive (sub)"
    ["k8s-stack"]="kubectl/k9s/helm/kubectx/kubens/kustomize/kind/stern (sub)"
    ["cloud-stack"]="cloud CLIs + IaC: aws/gcloud/azure/.../opentofu/pulumi (sub)"
    ["data-stack"]="sqlite3/psql/redis-cli/usql/duckdb/mlr/pgcli/mycli/litecli (sub)"
    ["cli-extras"]="modern CLI + dev-loop: eza/zoxide/.../act/just/watchexec (sub)"
    ["security-tools"]="sops/age/gitleaks/trivy/syft/cosign (sub)"
    ["git-tools"]="git TUI + forge CLI: lazygit/glab (sub)"
    ["blockchain"]="evm/solana/move/cosmos/near/cairo (sub)"
)

_MENU_DEFAULT_OFF=("${CATEGORIES[@]}")

# /dev/tty: gum TUI works under pct exec without an inherited controlling tty.
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

_menu_single() {
    local -n _ms_out="$1"
    shift
    local header="$1"
    shift
    local -a labels=()
    local label def_label=""
    while (($# >= 3)); do
        label="$(printf '%-10s %s' "$1" "$2")"
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
    _menu_multi "$1" "Categories to install (Space toggles, Enter confirms):" "${args[@]}"
}

menu_shell_select() {
    _menu_single "$1" "Login shell:" \
        bash "bash" ON \
        zsh "zsh" OFF
}

menu_multiplexer_select() {
    _menu_single "$1" "Terminal multiplexer:" \
        tmux+aoe "tmux + aoe (Agent of Empires) — AI workflow, auto-attach on login" ON \
        zellij "zellij (modern Rust multiplexer)" OFF \
        none "none (direct shell login, no persistence)" OFF
}

menu_runtimes_select() {
    _menu_multi "$1" "Extra runtimes (node/python/pnpm/uv + gcc/g++/make always installed):" \
        c-cpp "C/C++: clang, clang-format/tidy, lld, lldb, cmake, gdb, clangd" OFF \
        go "Backend, DevOps, CLI (kubectl, traefik, Charm)" OFF \
        rust "Modern dev tools, systems perf" OFF \
        bun "Fast JS/TS runtime (opencode uses it)" OFF \
        deno "Secure JS runtime" OFF \
        zig "Systems alternative to Rust" OFF \
        java "Enterprise, Android, Spring" OFF \
        kotlin "Android, modern JVM" OFF \
        dotnet ".NET / C# / F#" OFF \
        dart "Flutter mobile/web" OFF \
        scala "Functional JVM, data eng" OFF \
        lua "Neovim, OpenResty scripting" OFF \
        ruby "Rails, ops scripts (precompiled when avail.)" OFF \
        julia "Data science, ML, scientific (LSP incl.)" OFF \
        haskell "Functional purist via ghcup (ghc+cabal+hls)" OFF
}

# Agent set must match configs/libexec/agents-registry (source of truth); menu adds labels+defaults only.
menu_agents_select() {
    _menu_multi "$1" "AI agent CLIs:" \
        claude-code "Claude Code" ON \
        codex "Codex" ON \
        opencode "opencode" ON \
        pi "Pi" ON \
        copilot-cli "Copilot CLI" OFF \
        crush "Crush" OFF \
        gemini-cli "Gemini CLI" OFF \
        goose "Goose" OFF \
        continue "Continue" OFF \
        qwen-code "Qwen-Code" OFF \
        mistral-vibe "Mistral Vibe" OFF \
        deepseek-tui "DeepSeek TUI" OFF
}

menu_editor_select() {
    _menu_multi "$1" "Editors:" \
        vim "Vim" OFF \
        neovim "Neovim — modern standard, Lua config" ON \
        emacs "Emacs (emacs-nox)" OFF \
        micro "micro — intuitive editor (no modes)" OFF \
        code-server "code-server — VS Code in the browser" OFF
}

menu_agent_memory_select() {
    _menu_multi "$1" "Agent memory tools:" \
        memsearch "lite: BM25 search over project Markdown memory" ON \
        qmd "lite: BM25/hybrid search facts/notes (CLI)" OFF \
        engram "lite: Go binary, SQLite+FTS5, CLI/HTTP/MCP/TUI" OFF \
        claude-mem "heavy: daemon, multi-IDE hooks" OFF \
        mcp-memory-service "heavy: SQLite+ONNX, MCP+REST, semantic" OFF \
        agentmemory "heavy: MCP tools + viewer + REST API" OFF
}

menu_token_savers_select() {
    _menu_single "$1" "CLI token-saver (filters shell output before reaching agents):" \
        snip "snip: YAML pipelines, 60-90% token savings" ON \
        rtk "rtk: Rust binary, 100+ commands built-in" OFF \
        none "none" OFF
}

menu_ai_tools_select() {
    _menu_multi "$1" "AI/LLM helpers:" \
        code2prompt "Pack a repo as LLM-ready prompt context" ON \
        fabric "Reusable AI prompt library (Patterns) + CLI" ON \
        llm "Universal multi-model CLI (simonw, SQLite logs, built-in llm tokens)" ON \
        agents "Sync AGENTS.md + skills + MCP across CLIs (canonical)" ON \
        aichat "Multi-provider chat REPL + RAG + tools (Rust)" OFF \
        markitdown "Convert PDF/DOCX/PPT/HTML → Markdown (MS)" OFF \
        shell-gpt "NL → shell/code/chat REPL (sgpt)" OFF \
        gptscript "Framework: LLM ↔ tools/APIs/files (Acorn)" OFF \
        promptfoo "Eval/test LLM prompts (regressions, A/B, metrics)" OFF
}

menu_cloud_stack_select() {
    _menu_multi "$1" "Cloud provider CLIs + IaC:" \
        aws "AWS CLI v2 (hyperscaler)" OFF \
        flyctl "Fly.io" OFF \
        cloudflared "Cloudflare tunnel + Zero Trust access client" OFF \
        supabase "Supabase" OFF \
        doctl "DigitalOcean" OFF \
        hcloud "Hetzner Cloud (EU)" OFF \
        scaleway "Scaleway (EU)" OFF \
        gcloud "Google Cloud SDK (vfox, ~87 MB, init required)" OFF \
        azure "Azure CLI (Microsoft official installer)" OFF \
        opentofu "OpenTofu — Terraform-compatible IaC" OFF \
        pulumi "Pulumi — IaC in real languages" OFF
}

menu_blockchain_select() {
    _menu_multi "$1" "Blockchain bundles:" \
        evm "Ethereum: solc + foundry + LSP + slither + solhint" OFF \
        solana "Solana: agave validator/CLI + anchor framework" OFF \
        move "Sui + Aptos (Move language, sui is ~1 GB)" OFF \
        cosmos "Cosmos SDK: ignite scaffolder (Go)" OFF \
        near "NEAR Protocol: near-cli-rs (interactive Rust CLI)" OFF \
        cairo "Starknet: scarb (build/deps) + sncast CLI (Starknet Foundry, Cairo lang)" OFF
}

menu_data_stack_select() {
    _menu_multi "$1" "DB clients + data CLIs:" \
        sqlite3 "SQLite client (apt)" ON \
        pgcli "Postgres pretty CLI (autocomplete+highlight)" ON \
        duckdb "DuckDB analytical DB engine + CLI" ON \
        postgresql-client "Vanilla psql + pg_dump" OFF \
        redis-tools "Vanilla redis-cli" OFF \
        usql "Universal SQL CLI (one tool, many DBs)" OFF \
        mlr "Miller — awk/sed/cut/join for CSV/TSV/JSON" OFF \
        mycli "MySQL pretty CLI" OFF \
        litecli "SQLite pretty CLI" OFF \
        lazysql "TUI for SQL (PG/MySQL/SQLite/MSSQL)" OFF
}

menu_containers_select() {
    _menu_multi "$1" "Container runtimes + tools:" \
        docker "Docker Engine + buildx + compose (official APT repo)" ON \
        lazydocker "TUI for docker (logs, stats, exec)" ON \
        hadolint "Dockerfile linter" ON \
        podman "Rootless container runtime" OFF \
        dive "Inspect image layers + efficiency scoring" OFF
}

menu_k8s_stack_select() {
    _menu_multi "$1" "Kubernetes CLIs:" \
        kubectl "Canonical Kubernetes CLI" ON \
        k9s "TUI dashboard for clusters" ON \
        helm "Package manager" ON \
        kubectx "Switch contexts fast" ON \
        kubens "Switch namespaces fast" ON \
        kustomize "Overlay-based YAML composition" OFF \
        kind "Kubernetes-in-Docker (ephemeral clusters)" OFF \
        stern "Multi-pod log tailing with regex" OFF
}

menu_cli_extras_select() {
    _menu_multi "$1" "Human-facing modern CLI extras (search-core always installed):" \
        eza "Modern ls with git/icons" ON \
        zoxide "Smart cd by frecency" ON \
        tldr "Concise community man pages" ON \
        yazi "TUI file manager (async, image preview)" OFF \
        glow "Markdown TUI reader (local + GitHub/GitLab)" OFF \
        sd "Intuitive find & replace (JS/Python regex)" OFF \
        hyperfine "Benchmark commands (CSV/JSON output)" OFF \
        shfmt "Shell formatter" OFF \
        shellcheck "Shell linter" OFF \
        xh "Modern HTTPie clone (Rust)" OFF \
        typos "Source-code spell checker" OFF \
        act "Run GitHub Actions locally" OFF \
        just "Command runner (Make-like)" OFF \
        watchexec "Re-run a command on file change" OFF
}

menu_security_tools_select() {
    _menu_multi "$1" "Security tools:" \
        sops "Encrypt YAML/JSON/.env with age/KMS" ON \
        age "Modern file encryption (CLI)" ON \
        kingfisher "AI-aware secret scanner (Anthropic/OpenAI/Gemini/...)" ON \
        varlock "AI-safe .env: schemas for agents, secrets for humans" OFF \
        dotenvx "Encrypted .env files (drop-in dotenv)" OFF \
        infisical "Centralized secret manager CLI" OFF \
        trivy "All-in-one scanner: CVE+IaC+secrets+SBOM" OFF \
        gitleaks "Scan repos for committed secrets" OFF \
        syft "Generate SBOMs from images/dirs" OFF \
        cosign "Sign/verify container images + artifacts" OFF
}

menu_git_tools_select() {
    _menu_multi "$1" "Extra git forges + TUI (gh + delta always installed):" \
        lazygit "TUI for git (most popular)" ON \
        gitlab "GitLab CLI (glab) — PRs/issues/CI from terminal" OFF
}

# shellcheck disable=SC2154  # selected[] lives in caller's scope (main in setup.sh).
_menu_in_selected() { [[ " ${selected[*]:-} " == *" $1 "* ]]; }

menu_summary_confirm() {
    {
        printf '\n──── Selection summary ────\n'
        printf '  Shell:         %s\n' "${CERVELAI_SHELL:-bash}"
        printf '  Multiplexer:   %s\n' "${CERVELAI_MULTIPLEXER:-tmux+aoe}"
        printf '  Categories:    %s\n' "${selected[*]:-(none beyond mandatory)}"
        [[ -n "${CERVELAI_AGENTS:-}" ]] && printf '  Agents:        %s\n' "$CERVELAI_AGENTS"
        [[ -n "${CERVELAI_TOKEN_SAVERS:-}" ]] && printf '  Token-saver:   %s\n' "$CERVELAI_TOKEN_SAVERS"
        [[ -n "${CERVELAI_AGENT_MEMORY:-}" ]] && printf '  Agent memory:  %s\n' "$CERVELAI_AGENT_MEMORY"
        [[ -n "${CERVELAI_AI_TOOLS:-}" ]] && printf '  AI tools:      %s\n' "$CERVELAI_AI_TOOLS"
        [[ -n "${CERVELAI_EDITOR:-}" ]] && printf '  Editors:       %s\n' "$CERVELAI_EDITOR"
        [[ -n "${CERVELAI_RUNTIMES:-}" ]] && printf '  Runtimes+:     %s\n' "$CERVELAI_RUNTIMES"
        [[ -n "${CERVELAI_DATA_STACK:-}" ]] && printf '  Data:          %s\n' "$CERVELAI_DATA_STACK"
        [[ -n "${CERVELAI_CONTAINERS:-}" ]] && printf '  Containers:    %s\n' "$CERVELAI_CONTAINERS"
        [[ -n "${CERVELAI_K8S_STACK:-}" ]] && printf '  k8s:           %s\n' "$CERVELAI_K8S_STACK"
        [[ -n "${CERVELAI_CLOUD_STACK:-}" ]] && printf '  Cloud:         %s\n' "$CERVELAI_CLOUD_STACK"
        [[ -n "${CERVELAI_BLOCKCHAIN:-}" ]] && printf '  Blockchain:    %s\n' "$CERVELAI_BLOCKCHAIN"
        [[ -n "${CERVELAI_CLI_EXTRAS:-}" ]] && printf '  CLI extras:    %s\n' "$CERVELAI_CLI_EXTRAS"
        [[ -n "${CERVELAI_SECURITY_TOOLS:-}" ]] && printf '  Security:      %s\n' "$CERVELAI_SECURITY_TOOLS"
        [[ -n "${CERVELAI_GIT_TOOLS:-}" ]] && printf '  Git extras:    %s\n' "$CERVELAI_GIT_TOOLS"
        _menu_in_selected usage-trackers && printf '  Usage:         tokscale + ccusage + ccstatusline\n'
        printf '\n'
    } >/dev/tty
    gum confirm --default=Yes "Install with these choices?" </dev/tty
}
