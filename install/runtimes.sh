#!/usr/bin/env bash

# pnpm 11.1.3 breaks with ERR_PNPM_RESOLUTION_POLICY_VIOLATIONS_UNHANDLED; pin it.
_PNPM_VERSION="11.1.2"

install_runtimes_mise() {
    local u
    u="$(_user)"
    # Per-user install (~/.local/bin/mise, owned by the agent) so the no-sudo agent can `mise self-update`.
    if [[ -x "/home/$u/.local/bin/mise" ]]; then
        log_skip "mise already installed for $u"
    else
        log_info "installing mise for $u (~/.local/bin/mise)"
        # MISE_INSTALL_HELP=0: skip the installer's "add to .bashrc" advice — our .bashrc already activates mise.
        run _user_bash 'curl -fsSL https://mise.run | MISE_INSTALL_HELP=0 sh'
    fi
    # Must deploy [settings] before any `mise use -g` appends [tools] to the same file.
    local cfg="/home/$u/.config/mise/config.toml"
    if [[ ! -e "$cfg" && -r "$CONFIGS_DIR/mise/config.toml" ]]; then
        run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/mise/config.toml" "$cfg"
        log_ok "mise config deployed (settings only)"
    fi
    soft run _user_bash "mise trust $cfg"
}

install_runtimes_node() {
    mise_use "node" "lts"
    soft _user_bash "rm -rf ~/.cache/node/corepack/v1/pnpm && corepack prepare pnpm@${_PNPM_VERSION} --activate"
}

install_runtimes_pnpm_config() {
    local u
    u="$(_user)"
    local pnpm_home="/home/$u/.local/share/pnpm"

    local src_ws="$CONFIGS_DIR/pnpm/pnpm-workspace.yaml"
    if [[ -r "$src_ws" ]]; then
        run install -d -m 755 -o "$u" -g "$u" "$pnpm_home"
        if [[ -e "$pnpm_home/pnpm-workspace.yaml" ]]; then
            log_skip "pnpm-workspace.yaml present, keeping current (re-run safe)"
        else
            run install -D -m 644 -o "$u" -g "$u" "$src_ws" "$pnpm_home/pnpm-workspace.yaml"
            log_ok "pnpm-workspace.yaml deployed to ~/.local/share/pnpm (pnpm XDG dir)"
        fi
    fi
}

# Chicken-and-egg: config.toml routes npm:* through pnpm, but pnpm itself is npm:*.
install_runtimes_pnpm() {
    if _user_bash "command -v pnpm" &>/dev/null; then
        log_skip "mise: pnpm already on PATH"
        return 0
    fi
    log_info "mise use -g npm:pnpm@${_PNPM_VERSION} (bootstrap via MISE_NPM_PACKAGE_MANAGER=npm)"
    run _user_bash "MISE_NPM_PACKAGE_MANAGER=npm mise use -g npm:pnpm@${_PNPM_VERSION}" ||
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
install_runtimes_c_cpp() { apt_install cmake gdb pkg-config clangd clang clang-format clang-tidy lld lldb; }
install_runtimes_bun() { mise_use "bun" "latest"; }
install_runtimes_deno() { mise_use "deno" "latest"; }
install_runtimes_zig() { mise_use "zig" "latest"; }
install_runtimes_java() { mise_use "java" "latest"; }
install_runtimes_kotlin() { mise_use "kotlin" "latest"; }
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

install_runtimes_ruby() {
    # Pin: `latest` outruns the precompiled binary feed and falls back to a source build — bump when a newer binary ships.
    mise_use "ruby" "4.0.4"
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
