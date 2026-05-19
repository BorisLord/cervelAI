#!/usr/bin/env bash
# install/_finalize.sh: final topgrade + summary + chsh + MOTD.

# GIT_TERMINAL_PROMPT=0 keeps any git step from prompting for creds on dead/private repos.
run_final_topgrade() {
    ((DRY_RUN)) && {
        log_skip "final topgrade (dryrun)"
        return 0
    }
    log_step "final refresh (topgrade): catches apt security updates"
    soft _user_bash "GIT_TERMINAL_PROMPT=0 topgrade --yes"
}

print_final_summary() {
    local u
    u="$(_user)"
    local ip
    # default-route src IP — skips docker0/podman bridges that eth0 hardcoding would catch.
    ip="$(ip -4 -o route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++)if($i=="src")print $(i+1)}' | head -1)"
    log_step "summary"
    bash "$CONFIGS_DIR/libexec/logo"
    printf '\n'
    cat <<EOF
  cervelAI is ready.

  User:           $u
  IP:             ${ip:-<detect: ip a>}
  Shell:          ${CERVELAI_SHELL:-bash} + ${CERVELAI_MULTIPLEXER:-tmux+aoe}
  Categories:     ${selected[*]:-(none beyond base)}
  Agents:         ${CERVELAI_AGENTS:-(none)}
  Editors:        ${CERVELAI_EDITORS:-(none)}
EOF
    [[ -n "${CERVELAI_GIT_FORGES:-}" ]] && printf '  Git forges:     %s\n' "$CERVELAI_GIT_FORGES"
    [[ -n "${CERVELAI_TOKEN_SAVER:-}" ]] && printf '  Token-saver:    %s\n' "$CERVELAI_TOKEN_SAVER"
    [[ -n "${CERVELAI_AGENT_MEMORY:-}" ]] && printf '  Agent memory:   %s\n' "$CERVELAI_AGENT_MEMORY"
    [[ -n "${CERVELAI_AI_TOOLS:-}" ]] && printf '  AI tools:       %s\n' "$CERVELAI_AI_TOOLS"
    [[ -n "${CERVELAI_RUNTIMES:-}" ]] && printf '  Runtimes+:      %s\n' "$CERVELAI_RUNTIMES"
    [[ -n "${CERVELAI_DATA_STACK:-}" ]] && printf '  Data:           %s\n' "$CERVELAI_DATA_STACK"
    [[ -n "${CERVELAI_CONTAINERS:-}" ]] && printf '  Containers:     %s\n' "$CERVELAI_CONTAINERS"
    [[ -n "${CERVELAI_K8S_STACK:-}" ]] && printf '  k8s:            %s\n' "$CERVELAI_K8S_STACK"
    [[ -n "${CERVELAI_CLOUD_STACK:-}" ]] && printf '  Cloud:          %s\n' "$CERVELAI_CLOUD_STACK"
    [[ -n "${CERVELAI_BLOCKCHAIN:-}" ]] && printf '  Blockchain:     %s\n' "$CERVELAI_BLOCKCHAIN"
    [[ -n "${CERVELAI_CLI_EXTRAS:-}" ]] && printf '  CLI extras:     %s\n' "$CERVELAI_CLI_EXTRAS"
    [[ -n "${CERVELAI_SECURITY_TOOLS:-}" ]] && printf '  Security:       %s\n' "$CERVELAI_SECURITY_TOOLS"
    cat <<EOF
  Env/keys:       /home/$u/.config/cervelAI/env
  Notify:         cervel run <cmd>
  Tools quickref: cat /home/$u/AGENTS.md

  Connect:
      ssh $u@${ip:-<lxc-ip>}
      mosh $u@${ip:-<lxc-ip>}

  The cervelai menu greets every interactive login (skip via plain shell).

EOF
}

finalize() {
    local u="${CERVELAI_USER:-agent}"
    local desired="${CERVELAI_SHELL:-bash}"

    # `install -d` as root leaves parents root-owned — fix recursively.
    run chown -R "$u:$u" "/home/$u"

    local desired_bin
    case "$desired" in
        bash | bash-it) desired_bin=bash ;;
        zsh | zsh-omz) desired_bin=zsh ;;
        fish) desired_bin=fish ;;
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
  Env/keys: ~/.config/cervelAI/env
  Notify:   cervel run <cmd>
  Tools:    cat ~/AGENTS.md

MOTD
        } >"$motd"
        log_ok "MOTD set"
    fi
}
