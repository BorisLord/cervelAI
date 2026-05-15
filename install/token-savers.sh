#!/usr/bin/env bash
# install/token-savers.sh — CLI-noise filters that cut tokens fed to AI agents.
# CERVELAI_TOKEN_SAVER=snip|rtk|both|none (default: snip). Pick one for the
# agent's PreToolUse hook — not both, their hooks would clash.

install_token_savers_snip() { mise_use "github:edouard-claude/snip"; }
install_token_savers_rtk()  { mise_aqua "rtk-ai/rtk"; }

# Silent for agents snip doesn't know about (opencode/aider/crush/goose/continue).
_snip_init_one() {
    local target
    case "$1" in
        claude-code) target="claude-code" ;;
        codex)       target="codex" ;;
        gemini-cli)  target="gemini" ;;
        pi)          target="pi" ;;
        *) return 0 ;;
    esac
    log_info "snip init --agent $target"
    run _user_bash "snip init --agent $target"
}

_rtk_init_one() {
    local cmd
    case "$1" in
        claude-code) cmd="rtk init -g" ;;
        codex)       cmd="rtk init -g --codex" ;;
        gemini-cli)  cmd="rtk init -g --gemini" ;;
        *) return 0 ;;
    esac
    log_info "$cmd"
    run _user_bash "$cmd"
}

_init_token_saver() {
    local tool="$1" agents="${CERVELAI_AGENTS:-}"
    [[ "$agents" == "all" ]] && agents="claude-code,codex,opencode,pi,aider,crush,gemini-cli,goose,continue"
    [[ -z "$agents" ]] && { log_skip "$tool init — no AI agents installed"; return 0; }
    local -a list; IFS=',' read -r -a list <<< "$agents"
    local a
    for a in "${list[@]}"; do
        a="${a// /}"
        case "$tool" in
            snip) _snip_init_one "$a" ;;
            rtk)  _rtk_init_one  "$a" ;;
        esac
    done
}

install_token_savers_all() {
    case "${CERVELAI_TOKEN_SAVER:-snip}" in
        snip) install_token_savers_snip; _init_token_saver snip ;;
        rtk)  install_token_savers_rtk;  _init_token_saver rtk ;;
        # both: install both binaries, but init snip only — their hooks collide.
        both) install_token_savers_snip; install_token_savers_rtk; _init_token_saver snip ;;
        none) log_skip "token-savers: none (CERVELAI_TOKEN_SAVER=none)" ;;
        *)    log_warn "unknown CERVELAI_TOKEN_SAVER=${CERVELAI_TOKEN_SAVER}, defaulting to snip"
              install_token_savers_snip; _init_token_saver snip ;;
    esac
}
