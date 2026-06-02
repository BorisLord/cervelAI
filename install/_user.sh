#!/usr/bin/env bash

create_user() {
    local u
    u="$(_user)"
    if id "$u" &>/dev/null; then
        log_skip "user $u already exists"
    else
        log_info "creating user $u (no sudo — agents run untrusted code)"
        run useradd -m -s /bin/bash "$u"
    fi
    run install -d -m 700 -o "$u" -g "$u" "/home/$u/.ssh"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.config"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.cache"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/bin"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/share"
    run install -d -m 755 -o "$u" -g "$u" "/home/$u/.local/state"
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

    # mise/config.toml omitted here: owned by install_runtimes_mise to avoid clobbering [tools].
    local -A files=(
        ["bash/.bashrc"]=".bashrc"
        ["bash/.bash_profile"]=".bash_profile"
        ["zsh/.zshrc"]=".zshrc"
        ["zsh/.zshenv"]=".zshenv"
        ["zsh/.zprofile"]=".zprofile"
        ["tmux/.tmux.conf"]=".tmux.conf"
        ["agents/AGENTS.md"]="AGENTS.md"
        ["topgrade/topgrade.toml"]=".config/topgrade.toml"
    )
    # Deploy decision is per-file (not gated on the stamp below) so it's correct even on boxes
    # provisioned BEFORE the stamp existed: an already-deployed file is kept, never clobbered.
    local src dest deploy
    for src in "${!files[@]}"; do
        [[ -r "$CONFIGS_DIR/$src" ]] || {
            log_skip "configs/$src missing"
            continue
        }
        dest="$h/${files[$src]}"
        # Re-run safe: keep an existing file. Exception: the stock .bashrc that useradd seeds from
        # /etc/skel on a fresh box (lacks our env line) — replace that one with ours, once.
        deploy=0
        if [[ ! -e "$dest" ]]; then
            deploy=1
        elif [[ "${files[$src]}" == ".bashrc" ]] && ! grep -qF 'config/cervelAI/env' "$dest"; then
            deploy=1
        fi
        if ((deploy)); then
            run install -D -m 644 -o "$u" -g "$u" "$CONFIGS_DIR/$src" "$dest"
            log_ok "${files[$src]}"
        else
            log_skip "${files[$src]} present, keeping current (re-run safe)"
        fi
    done

    if [[ -d "$CONFIGS_DIR/libexec" ]]; then
        _deploy_libexec "$h/.local/libexec/cervelai" "$u"
        run install -d -m 755 -o "$u" -g "$u" "$h/.local/bin"
        run sudo -u "$u" ln -sf "$h/.local/libexec/cervelai/cervel" "$h/.local/bin/cervel"
        log_ok "libexec deployed + cervel → ~/.local/bin/cervel"
    fi

    # "cervelAI was here" stamp — provenance only. Written once and backfilled on pre-stamp boxes
    # (so an upgrade stamps the box without re-deploying anything).
    local stamp="$h/.config/cervelAI/provisioned"
    if [[ ! -e "$stamp" ]] && ! ((DRY_RUN)); then
        install -d -m 700 -o "$u" -g "$u" "$(dirname "$stamp")"
        printf '# cervelAI provisioned this home — managed configs were deployed here.\n# Re-runs preserve your edits; delete a file (or this stamp) to let cervelAI redeploy it.\nfirst_provisioned=%s\n' \
            "$(date -u +%FT%TZ)" >"$stamp"
        chmod 600 "$stamp"
        chown "$u:$u" "$stamp"
        log_ok "stamp written: ~/.config/cervelAI/provisioned"
    fi
}

ensure_env_file() {
    local u
    u="$(_user)"
    local f="/home/$u/${ENV_FILE_REL}"
    if [[ -e "$f" ]]; then
        log_skip "env file already exists: $f"
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
# cervelAI env: NTFY_* for cervel run notifications. Mode 600.
# PATH is native (mise shims via mise activate + dotfiles), not set here.
export NTFY_SERVER="https://ntfy.sh"
export NTFY_TOPIC="${topic}"
EOF
    chmod 600 "$f"
    chown "$u:$u" "$f"
    log_ok "env file created: $f"
    log_info "ntfy topic: ${topic}, subscribe at https://ntfy.sh/${topic}"
}
