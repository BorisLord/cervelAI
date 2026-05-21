#!/usr/bin/env bash

# minimumReleaseAge: 0 is install-only; lock it out so periodic updates use pnpm's default quarantine.
lock_pnpm_release_age() {
    local u f
    u="$(_user)"
    f="/home/$u/.local/share/pnpm/pnpm-workspace.yaml"
    ((DRY_RUN)) && return 0
    [[ -f "$f" ]] || return 0
    run sed -i 's/^minimumReleaseAge: 0$/# minimumReleaseAge: 0 — install-only; updates use pnpm default/' "$f"
}

run_final_topgrade() {
    ((DRY_RUN)) && {
        log_skip "final topgrade (dryrun)"
        return 0
    }
    log_step "final refresh (topgrade): mise + user-space backends (apt = root/unattended-upgrades)"
    soft _user_bash "GIT_TERMINAL_PROMPT=0 topgrade --yes"
}

# GITHUB_TOKEN is install-only; wipe it at end so runtime access uses `gh auth login` + SSH keys, not a stored token.
clear_github_token() {
    ((DRY_RUN)) && {
        log_skip "clear GITHUB_TOKEN (dryrun)"
        return 0
    }
    local u f
    u="$(_user)"
    f="/home/$u/${ENV_FILE_REL}"
    if [[ -f "$f" ]] && grep -q '^export GITHUB_TOKEN=' "$f"; then
        run sed -i '/^export GITHUB_TOKEN=/d' "$f"
        log_ok "removed persisted GITHUB_TOKEN from $f"
    fi
    unset GITHUB_TOKEN
    log_ok "GITHUB_TOKEN cleared (install-only, not kept on the box)"
}

write_manifest() {
    local u f
    u="$(_user)"
    f="/home/$u/.config/cervelAI/manifest"
    ((DRY_RUN)) && return 0
    run install -d -m 700 -o "$u" -g "$u" "$(dirname "$f")"
    {
        printf 'CERVELAI_SHELL=%q\n' "${CERVELAI_SHELL:-bash}"
        printf 'CERVELAI_MULTIPLEXER=%q\n' "${CERVELAI_MULTIPLEXER:-tmux+aoe}"
        printf 'CERVELAI_CATEGORIES=%q\n' "${selected[*]:-}"
        printf 'CERVELAI_AGENTS=%q\n' "${CERVELAI_AGENTS:-}"
        printf 'CERVELAI_EDITOR=%q\n' "${CERVELAI_EDITOR:-}"
    } >"$f"
    chmod 644 "$f"
    chown "$u:$u" "$f"
}

print_final_summary() {
    local u ip
    u="$(_user)"
    # default-route src IP — skips docker0/podman bridges that hardcoding eth0 would catch.
    ip="$(ip -4 -o route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++)if($i=="src")print $(i+1)}' | head -1)"
    write_manifest
    log_step "setup complete"
    bash "$CONFIGS_DIR/libexec/logo"
    cat <<EOF

  cervelAI is ready on ${u}@$(hostname) (${ip:-<detect: ip a>})

  → run  cervel status  for the full picture — stack, sessions, endpoints

EOF
}

finalize() {
    local u desired
    u="$(_user)"
    desired="${CERVELAI_SHELL:-bash}"

    run chown -R "$u:$u" "/home/$u"

    local desired_bin
    case "$desired" in
        bash) desired_bin=bash ;;
        zsh) desired_bin=zsh ;;
        *) desired_bin="$desired" ;;
    esac

    if [[ "$desired_bin" != "bash" && "$desired_bin" != "none" ]]; then
        local target
        target="$(command -v "$desired_bin" 2>/dev/null || true)"
        if [[ -z "$target" ]]; then
            log_warn "default shell $desired_bin requested but not installed, skipping chsh"
        else
            local cur
            cur="$(getent passwd "$u" | cut -d: -f7)"
            if [[ "$cur" == "$target" ]]; then
                log_skip "$desired_bin already default for $u"
            else
                run chsh -s "$target" "$u"
                log_ok "default shell $desired_bin set for $u"
            fi
        fi
    fi

    local motd="/etc/motd"
    if grep -q "cervelAI" "$motd" 2>/dev/null; then
        log_skip "MOTD already set"
    elif ((DRY_RUN)); then
        log_info "(dryrun) would write $motd"
    else
        {
            printf '\n'
            bash "$CONFIGS_DIR/libexec/logo"
            cat <<MOTD

  ready for AI coding agents

  Shell:    ${desired}    Multiplexer: ${CERVELAI_MULTIPLEXER:-tmux+aoe}
  Connect:  ssh ${u}@<this-ip>  |  mosh ${u}@<this-ip>
  Agents:   aoe          Dashboard: cervel status  (live URL + token)
  Env:      ~/.config/cervelAI/env
  Notify:   cervel run <cmd>
  Tools:    cat ~/AGENTS.md

MOTD
        } >"$motd"
        log_ok "MOTD set"
    fi
}
