#!/usr/bin/env bash
# install/runtimes.sh: mise system-wide + language runtimes. node/python/pnpm/uv always.

install_runtimes_mise() {
    if [[ -x /usr/local/bin/mise ]]; then
        log_skip "mise already installed (system-wide)"
    else
        # system-wide /usr/local/bin/mise: npm backend + shims shell out to bare `mise`.
        log_info "installing mise system-wide to /usr/local/bin/mise"
        run sh -c 'curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh'
    fi
    # deploy [settings] BEFORE any `mise use -g` (which appends [tools] in the same file).
    local u
    u="$(_user)"
    local cfg="/home/$u/.config/mise/config.toml"
    if [[ ! -e "$cfg" && -r "$CONFIGS_DIR/mise/config.toml" ]]; then
        run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/mise/config.toml" "$cfg"
        log_ok "mise config deployed (settings only)"
    fi
}

install_runtimes_node() { mise_use "node" "lts"; }

# config.toml routes npm:* through pnpm, but pnpm itself is an npm:* package (circular).
# MISE_NPM_PACKAGE_MANAGER=npm breaks the loop for this one install.
install_runtimes_pnpm() {
    if _user_bash "command -v pnpm" &>/dev/null; then
        log_skip "mise: pnpm already on PATH"
        return 0
    fi
    log_info "mise use -g npm:pnpm (bootstrap via MISE_NPM_PACKAGE_MANAGER=npm)"
    run _user_bash "MISE_NPM_PACKAGE_MANAGER=npm mise use -g npm:pnpm@latest" ||
        log_warn "pnpm bootstrap failed, later npm:* installs will too"
}

install_runtimes_node_tools() {
    mise_use "npm:typescript" latest tsc
    mise_npm "tsx"
}

install_runtimes_python() {
    mise_use "python" "latest"
    mise_aqua "astral-sh/ruff"
}
install_runtimes_uv() { mise_aqua "astral-sh/uv"; }
install_runtimes_go() { mise_use "go" "latest"; }
install_runtimes_rust() { mise_use "rust" "latest"; }
install_runtimes_bun() { mise_use "bun" "latest"; }
install_runtimes_deno() { mise_use "deno" "latest"; }
install_runtimes_zig() { mise_use "zig" "latest"; }
install_runtimes_java() { mise_use "java" "latest"; }
install_runtimes_kotlin() { mise_use "kotlin" "latest"; }
# MISE_EXPERIMENTAL scopes the flag here instead of polluting mise's global settings.
install_runtimes_dotnet() {
    _user_bash "command -v dotnet" &>/dev/null && {
        log_skip "mise: dotnet already on PATH"
        return 0
    }
    run _user_bash "MISE_EXPERIMENTAL=1 mise use -g dotnet@latest"
}
install_runtimes_ruby() { mise_use "ruby" "latest"; }
install_runtimes_dart() { mise_use "dart" "latest"; }
install_runtimes_scala() { mise_use "scala" "latest"; }
install_runtimes_lua() { mise_use "lua" "latest"; }

# php/erlang build from source via mise: dev libs must be present or ./configure aborts.
install_runtimes_php() {
    apt_install autoconf bison re2c pkg-config zlib1g-dev libxml2-dev \
        libssl-dev libsqlite3-dev libcurl4-openssl-dev libonig-dev \
        libreadline-dev libzip-dev libgd-dev libicu-dev libpq-dev
    # 'mise latest php' picks RCs over stables (8.5.6RC3 > 8.5.6). Resolve newest 8.x stable ourselves.
    local v
    v="$(_user_bash 'mise ls-remote php' 2>/dev/null | grep -E '^8\.[0-9]+\.[0-9]+$' | tail -1)"
    if [[ -z "$v" ]]; then
        log_warn "could not resolve latest stable PHP 8.x, falling back to 'latest'"
        v="latest"
    fi
    mise_use "php" "$v"
}
install_runtimes_erlang() {
    apt_install autoconf libssl-dev libncurses-dev
    mise_use "erlang" "latest"
}
install_runtimes_elixir() {
    install_runtimes_erlang # elixir needs Erlang's erl on PATH
    mise_use "elixir" "latest"
}

install_runtimes_all() {
    install_runtimes_mise
    install_runtimes_node
    install_runtimes_pnpm
    install_runtimes_node_tools
    install_runtimes_python
    install_runtimes_uv
    mise_aqua "topgrade-rs/topgrade"
    local csv="${CERVELAI_RUNTIMES:-}"
    [[ "$csv" == "all" ]] && csv="go,rust,bun,deno,zig,java,kotlin,dotnet,php,ruby,dart,scala,elixir,erlang,lua"
    IFS=',' read -r -a list <<<"$csv"
    for r in "${list[@]}"; do
        r="${r// /}"
        case "$r" in
            node | python | pnpm | uv | none | "") ;;
            go | rust | bun | deno | zig | java | kotlin | dotnet | php | ruby | dart | scala | elixir | erlang | lua)
                "install_runtimes_$r"
                ;;
            *) log_warn "unknown runtime in CERVELAI_RUNTIMES: $r (see install/runtimes.sh for the valid list)" ;;
        esac
    done
}
