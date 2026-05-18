#!/usr/bin/env bash
# install/token-savers.sh: CLI-noise filters for AI agents.
# CERVELAI_TOKEN_SAVER=snip|rtk|none. Mutually exclusive: their PreToolUse hooks clash.

install_token_savers_snip() { mise_use "github:edouard-claude/snip"; }
install_token_savers_rtk() { mise_aqua "rtk-ai/rtk"; }

_snip_init_one() {
    local target
    case "$1" in
        claude-code) target="claude-code" ;;
        codex) target="codex" ;;
        gemini-cli) target="gemini" ;;
        pi) target="pi" ;;
        *) return 0 ;;
    esac
    log_info "snip init --agent $target"
    run _user_bash "snip init --agent $target"
}

_rtk_init_one() {
    local cmd
    case "$1" in
        claude-code) cmd="rtk init -g" ;;
        codex) cmd="rtk init -g --codex" ;;
        gemini-cli) cmd="rtk init -g --gemini" ;;
        *) return 0 ;;
    esac
    log_info "$cmd"
    run _user_bash "$cmd"
}

_init_token_saver() {
    local tool="$1" agents="${CERVELAI_AGENTS:-}"
    [[ "$agents" == "all" ]] && agents="claude-code,codex,opencode,pi,crush,gemini-cli,goose,continue,qwen-code,mistral-vibe,deepseek-tui,grok-cli"
    [[ -z "$agents" ]] && {
        log_skip "$tool init: no AI agents installed"
        return 0
    }
    local -a list
    IFS=',' read -r -a list <<<"$agents"
    local a
    for a in "${list[@]}"; do
        a="${a// /}"
        case "$tool" in
            snip) _snip_init_one "$a" ;;
            rtk) _rtk_init_one "$a" ;;
        esac
    done
}

install_token_savers_all() {
    case "${CERVELAI_TOKEN_SAVER:-snip}" in
        snip)
            install_token_savers_snip
            _init_token_saver snip
            ;;
        rtk)
            install_token_savers_rtk
            _init_token_saver rtk
            ;;
        none) log_skip "token-savers: none (CERVELAI_TOKEN_SAVER=none)" ;;
        *)
            log_warn "unknown CERVELAI_TOKEN_SAVER=${CERVELAI_TOKEN_SAVER} (valid: snip,rtk,none), defaulting to snip"
            install_token_savers_snip
            _init_token_saver snip
            ;;
    esac
}
