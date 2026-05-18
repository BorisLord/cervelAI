#!/usr/bin/env bash
# install/_user.sh: user creation, sudoers, SSH key, config files, env file.

create_user() {
    local u="${CERVELAI_USER:-agent}"
    if id "$u" &>/dev/null; then
        log_skip "user $u already exists"
    else
        log_info "creating user $u"
        run useradd -m -s /bin/bash -G sudo "$u"
    fi
    # `install -d` doesn't chown intermediate dirs — list each level.
    run install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.config"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.cache"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/bin"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/share"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/state"
    local sudoers="/etc/sudoers.d/90-${u}"
    if [[ ! -f "$sudoers" ]]; then
        if ((DRY_RUN)); then
            log_info "(dryrun) would write $sudoers"
        else
            printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$u" >"$sudoers"
            chmod 440 "$sudoers"
            log_ok "sudo NOPASSWD configured for $u"
        fi
    fi
    if [[ -n "${CERVELAI_SSH_KEY:-}" ]]; then
        local ak="/home/$u/.ssh/authorized_keys"
        if ! grep -qF "${CERVELAI_SSH_KEY}" "$ak" 2>/dev/null; then
            if ((DRY_RUN)); then
                log_info "(dryrun) would append SSH key to $ak"
            else
                printf '%s\n' "${CERVELAI_SSH_KEY}" >>"$ak"
                chmod 600 "$ak"
                chown "$u:$u" "$ak"
                log_ok "SSH key added for $u"
            fi
        fi
    fi
}

install_configs() {
    local u
    u="$(_user)"
    local h="/home/$u"
    [[ -d "$CONFIGS_DIR" ]] || {
        log_warn "configs/ missing, skipping"
        return 0
    }
    log_step "deploying configs/ → $h"

    # mise/config.toml deliberately omitted — owned by install_runtimes_mise (avoid clobbering [tools]).
    local -A files=(
        ["bash/.bashrc"]=".bashrc"
        ["bash/.bash_profile"]=".bash_profile"
        ["zsh/.zshrc"]=".zshrc"
        ["zsh/.zshenv"]=".zshenv"
        ["tmux/.tmux.conf"]=".tmux.conf"
        ["agents/AGENTS.md"]="AGENTS.md"
        ["topgrade/topgrade.toml"]=".config/topgrade.toml"
    )
    local src
    for src in "${!files[@]}"; do
        [[ -r "$CONFIGS_DIR/$src" ]] || {
            log_skip "configs/$src missing"
            continue
        }
        run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/$src" "$h/${files[$src]}"
        log_ok "${files[$src]}"
    done

    if [[ -d "$CONFIGS_DIR/bin" ]]; then
        local b
        for b in "$CONFIGS_DIR"/bin/*; do
            [[ -f "$b" ]] || continue
            run install -D -m 755 -o "$u" -g "$u" "$b" "$h/.local/bin/$(basename "$b")"
            log_ok ".local/bin/$(basename "$b")"
        done
    fi
}

ensure_env_file() {
    local u
    u="$(_user)"
    local f="/home/$u/${ENV_FILE_REL}"
    if [[ -e "$f" ]]; then
        # Covers re-runs where the first install ran without a token.
        if [[ -n "${GITHUB_TOKEN:-}" ]] && ! grep -q '^export GITHUB_TOKEN=' "$f"; then
            printf 'export GITHUB_TOKEN=%q\n' "$GITHUB_TOKEN" >>"$f"
            log_ok "appended GITHUB_TOKEN to existing env file: $f"
        else
            log_skip "env file already exists: $f"
        fi
        return 0
    fi
    if ((DRY_RUN)); then
        log_info "(dryrun) would create $f"
        return 0
    fi
    install -d -m 700 -o "$u" -g "$u" "$(dirname "$f")"
    local topic suffix
    suffix="$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 16)"
    if [[ ${#suffix} -ne 16 ]]; then
        log_err "could not generate ntfy topic suffix (urandom unavailable?), aborting env file"
        return 1
    fi
    topic="cervelAI-${suffix}"
    cat >"$f" <<EOF
# cervelAI shared environment (bash, zsh, ai-run). Mode 600.
# mise shims first so runtimes stay visible in non-interactive shells.
# PNPM_HOME/bin needed: pnpm 11+ puts global bins there, not in PNPM_HOME.
export PNPM_HOME="\$HOME/.local/share/pnpm"
export PATH="\$HOME/.local/share/mise/shims:\$HOME/.local/bin:\$PNPM_HOME:\$PNPM_HOME/bin:\$PATH"
export NTFY_SERVER="https://ntfy.sh"
export NTFY_TOPIC="${topic}"
EOF
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        printf 'export GITHUB_TOKEN=%q\n' "$GITHUB_TOKEN" >>"$f"
    fi
    chmod 600 "$f"
    chown "$u:$u" "$f"
    log_ok "env file created: $f"
    log_info "ntfy topic: ${topic}, subscribe at https://ntfy.sh/${topic}"
}
