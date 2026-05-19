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
    # mise refuses untrusted configs in non-interactive contexts (interactive logins auto-trust).
    soft run _user_bash "mise trust $cfg"
}

install_runtimes_node() {
    mise_use "node" "lts"
    # Pin corepack default to pnpm 11.1.2 (11.1.3 has ERR_PNPM_RESOLUTION_POLICY_VIOLATIONS_UNHANDLED).
    soft _user_bash "rm -rf ~/.cache/node/corepack/v1/pnpm && corepack prepare pnpm@11.1.2 --activate"
}

# Must run before install_runtimes_pnpm: pnpm v9+ blocks dependency postinstall by default.
# .npmrc covers pnpm 9/10; pnpm-workspace.yaml at PNPM_HOME covers v11+ (where allowBuilds lives).
install_runtimes_pnpm_config() {
    local u
    u="$(_user)"
    local pnpm_home="/home/$u/.local/share/pnpm"

    local src_npmrc="$CONFIGS_DIR/pnpm/.npmrc"
    if [[ -r "$src_npmrc" ]]; then
        run install -D -m 644 -o "$u" -g "$u" "$src_npmrc" "/home/$u/.npmrc"
        log_ok ".npmrc deployed (pnpm 9/10 onlyBuiltDependencies)"
    fi

    local src_ws="$CONFIGS_DIR/pnpm/pnpm-workspace.yaml"
    if [[ -r "$src_ws" ]]; then
        run install -d -m 755 -o "$u" -g "$u" "$pnpm_home"
        run install -D -m 644 -o "$u" -g "$u" "$src_ws" "$pnpm_home/pnpm-workspace.yaml"
        log_ok "pnpm-workspace.yaml deployed to PNPM_HOME (pnpm 11+ allowBuilds)"
    fi
}

# Bootstrap chicken-and-egg: config.toml routes npm:* through pnpm, but pnpm itself is npm:*.
install_runtimes_pnpm() {
    if _user_bash "command -v pnpm" &>/dev/null; then
        log_skip "mise: pnpm already on PATH"
        return 0
    fi
    log_info "mise use -g npm:pnpm@11.1.2 (bootstrap via MISE_NPM_PACKAGE_MANAGER=npm)"
    run _user_bash "NPM_CONFIG_MINIMUM_RELEASE_AGE=0 MISE_NPM_PACKAGE_MANAGER=npm mise use -g npm:pnpm@11.1.2" ||
        log_warn "pnpm bootstrap failed, later npm:* installs will too"
}

install_runtimes_node_tools() {
    mise_use "npm:typescript" latest tsc
    mise_npm "tsx"
}

install_runtimes_python() {
    mise_use "python" "latest"
    mise_use "ruff"
}
install_runtimes_uv() { mise_use "uv"; }
install_runtimes_go() { mise_use "go" "latest"; }
install_runtimes_rust() { mise_use "rust" "latest"; }
# apt (not mise): C/C++ toolchain lives in /usr namespace with build-essential.
install_runtimes_c_cpp() { apt_install cmake gdb pkg-config clangd; }
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
    mise_use "ghcup" || return
    soft _user_bash "ghcup install ghc --set"
    soft _user_bash "ghcup install cabal --set"
    soft _user_bash "ghcup install hls --set"
}

install_runtimes_mandatory() {
    install_runtimes_mise
    install_runtimes_node
    install_runtimes_pnpm_config
    install_runtimes_pnpm
    install_runtimes_node_tools
    install_runtimes_python
    install_runtimes_uv
    mise_use "topgrade"
}

install_runtimes_all() {
    local csv="${CERVELAI_RUNTIMES:-}"
    [[ "$csv" == "all" ]] && csv="c-cpp,go,rust,bun,deno,zig,java,kotlin,dotnet,dart,scala,lua,ruby,julia,haskell"
    IFS=',' read -r -a list <<<"$csv"
    for r in "${list[@]}"; do
        r="${r// /}"
        case "$r" in
            node | python | pnpm | uv | none | "") ;;
            c-cpp | go | rust | bun | deno | zig | java | kotlin | dotnet | dart | scala | lua | ruby | julia | haskell)
                "install_runtimes_${r//-/_}"
                ;;
            *) log_warn "unknown runtime in CERVELAI_RUNTIMES: $r (see install/runtimes.sh for the valid list)" ;;
        esac
    done
}
