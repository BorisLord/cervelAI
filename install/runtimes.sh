#!/usr/bin/env bash
# install/runtimes.sh: mise + language runtimes. node/python/pnpm/uv mandatory, rest opt-in.

install_runtimes_mise() {
    if [[ -x /usr/local/bin/mise ]]; then
        log_skip "mise already installed (system-wide)"
    else
        log_info "installing mise system-wide to /usr/local/bin/mise"
        run sh -c 'curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh'
    fi
    # Deploy [settings] BEFORE any `mise use -g` appends [tools] to the same file.
    local u
    u="$(_user)"
    local cfg="/home/$u/.config/mise/config.toml"
    if [[ ! -e "$cfg" && -r "$CONFIGS_DIR/mise/config.toml" ]]; then
        run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/mise/config.toml" "$cfg"
        log_ok "mise config deployed (settings only)"
    fi
}

install_runtimes_node() { mise_use "node" "lts"; }

# Bootstrap chicken-and-egg: config.toml routes npm:* through pnpm, but pnpm itself is npm:*.
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
# libicu required for .NET globalization (CultureInfo).
install_runtimes_dotnet() {
    _user_bash "command -v dotnet" &>/dev/null && {
        log_skip "mise: dotnet already on PATH"
        return 0
    }
    apt_install libicu-dev
    mise_use "dotnet"
}
install_runtimes_dart() { mise_use "dart" "latest"; }
install_runtimes_scala() { mise_use "scala" "latest"; }
install_runtimes_lua() { mise_use "lua" "latest"; }

# apt deps: needed for the compile fallback if no precompiled ruby binary matches the host.
install_runtimes_ruby() {
    apt_install libffi-dev libyaml-dev libreadline-dev libssl-dev zlib1g-dev libgmp-dev
    mise_use "ruby" "latest"
}

install_runtimes_julia() {
    mise_use "julia" "latest" || return
    soft _user_bash 'julia -e "using Pkg; \"LanguageServer\" in keys(Pkg.dependencies()) || Pkg.add(\"LanguageServer\")"'
}

install_runtimes_haskell() {
    mise_aqua "haskell/ghcup-hs" || return
    soft _user_bash "ghcup install ghc --set"
    soft _user_bash "ghcup install cabal --set"
    soft _user_bash "ghcup install hls --set"
}

install_runtimes_mandatory() {
    install_runtimes_mise
    install_runtimes_node
    install_runtimes_pnpm
    install_runtimes_node_tools
    install_runtimes_python
    install_runtimes_uv
    mise_aqua "topgrade-rs/topgrade"
}

install_runtimes_all() {
    local csv="${CERVELAI_RUNTIMES:-}"
    [[ "$csv" == "all" ]] && csv="go,rust,bun,deno,zig,java,kotlin,dotnet,dart,scala,lua,ruby,julia,haskell"
    IFS=',' read -r -a list <<<"$csv"
    for r in "${list[@]}"; do
        r="${r// /}"
        case "$r" in
            node | python | pnpm | uv | none | "") ;;
            go | rust | bun | deno | zig | java | kotlin | dotnet | dart | scala | lua | ruby | julia | haskell)
                "install_runtimes_$r"
                ;;
            *) log_warn "unknown runtime in CERVELAI_RUNTIMES: $r (see install/runtimes.sh for the valid list)" ;;
        esac
    done
}
