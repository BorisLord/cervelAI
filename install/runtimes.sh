#!/usr/bin/env bash
# install/runtimes.sh — mise (system-wide) + language runtimes.
# node, python, pnpm, uv are always installed (infrastructure); CERVELAI_RUNTIMES
# / the menu picks the extras. node ships tsc/tsx, python ships ruff.

install_runtimes_mise() {
    if [[ -x /usr/local/bin/mise ]]; then
        log_skip "mise already installed (system-wide)"
    else
        # System-wide so it's on the default PATH: mise's npm backend and shims
        # shell out to a bare `mise`; a per-user ~/.local/bin/mise isn't reliable.
        log_info "installing mise system-wide → /usr/local/bin/mise"
        run sh -c 'curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh'
    fi
    # Deploy the [settings] config BEFORE any `mise use -g` (which append [tools]
    # to it) — install_configs must not clobber it later, so it owns this file.
    local u; u="$(_user)"
    local cfg="/home/$u/.config/mise/config.toml"
    if [[ ! -e "$cfg" && -r "$CONFIGS_DIR/mise/config.toml" ]]; then
        run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/mise/config.toml" "$cfg"
        log_ok "mise config deployed (settings only)"
    fi
}

# node + python ship their global tooling (tsc/tsx, ruff) — not worth a category.
install_runtimes_node() {
    mise_use "node" "lts"
    mise_npm "typescript"
    mise_npm "tsx"
}
install_runtimes_python() {
    mise_use "python" "3.13"   # 3.14 has no scipy/numpy wheels — aider would fail to build
    mise_aqua "astral-sh/ruff"
}
install_runtimes_pnpm()    { mise_use "pnpm"    "latest"; }
install_runtimes_uv()      { mise_aqua "astral-sh/uv"; }
install_runtimes_go()      { mise_use "go"      "latest"; }
install_runtimes_rust()    { mise_use "rust"    "latest"; }
install_runtimes_bun()     { mise_use "bun"     "latest"; }
install_runtimes_deno()    { mise_use "deno"    "latest"; }
install_runtimes_zig()     { mise_use "zig"     "latest"; }
install_runtimes_java()    { mise_use "java"    "latest"; }
install_runtimes_kotlin()  { mise_use "kotlin"  "latest"; }
install_runtimes_dotnet()  { mise_use "dotnet"  "latest"; }
install_runtimes_ruby()    { mise_use "ruby"    "latest"; }
install_runtimes_dart()    { mise_use "dart"    "latest"; }
install_runtimes_scala()   { mise_use "scala"   "latest"; }
install_runtimes_lua()     { mise_use "lua"     "latest"; }

# php and erlang build from source via mise — their dev libraries must be present
# first or ./configure aborts. Gated: only runs when the runtime is picked.
install_runtimes_php() {
    apt_install autoconf bison re2c pkg-config zlib1g-dev libxml2-dev \
        libssl-dev libsqlite3-dev libcurl4-openssl-dev libonig-dev \
        libreadline-dev libzip-dev libgd-dev libicu-dev libpq-dev
    mise_use "php" "8.4.21"   # exact stable — 'latest' fuzzy-matches an RC
}
install_runtimes_erlang() {
    apt_install autoconf libssl-dev libncurses-dev
    mise_use "erlang" "latest"
}
install_runtimes_elixir() {
    install_runtimes_erlang   # elixir needs Erlang's `erl` on PATH
    mise_use "elixir" "latest"
}

install_runtimes_all() {
    install_runtimes_mise
    install_runtimes_node
    install_runtimes_python
    install_runtimes_pnpm
    install_runtimes_uv
    local csv="${CERVELAI_RUNTIMES:-}"
    [[ "$csv" == "all" ]] && csv="go,rust,bun,deno,zig,java,kotlin,dotnet,php,ruby,dart,scala,elixir,erlang,lua"
    IFS=',' read -r -a list <<< "$csv"
    for r in "${list[@]}"; do
        r="${r// /}"
        case "$r" in
            node|python|pnpm|uv|none|"") ;;
            go|rust|bun|deno|zig|java|kotlin|dotnet|php|ruby|dart|scala|elixir|erlang|lua)
                "install_runtimes_$r" ;;
            *) log_warn "unknown runtime in CERVELAI_RUNTIMES: $r (see install/runtimes.sh for the valid list)" ;;
        esac
    done
}
