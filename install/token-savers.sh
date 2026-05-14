#!/usr/bin/env bash
# install/token-savers.sh — CLI-noise filters that cut tokens fed to AI agents.
#   snip (default) : extensible YAML filters (match + pipeline DSL)
#   rtk            : Rust binary, hardcoded filters for 100+ commands
# Pick one on the agent's PreToolUse hook — not both (their hooks would clash).
# Switch via CERVELAI_TOKEN_SAVER=snip|rtk|both|none (default: snip).
# Security: both install via `curl … master/install.sh | sh` as root (moving
# branch, supply-chain surface). Pin to a tag if you want to harden this.

install_token_savers_snip() {
    if has_cmd snip; then log_skip "snip already installed"; return 0; fi
    log_info "installing snip (YAML filters)"
    run sh -c 'curl -fsSL https://raw.githubusercontent.com/edouard-claude/snip/master/install.sh | sh' \
        || log_warn "snip install failed — check upstream URL"
}

install_token_savers_rtk() {
    mise_present && soft mise_aqua "rtk-ai/rtk" 2>/dev/null && return 0
    if has_cmd rtk; then log_skip "rtk already installed"; return 0; fi
    log_info "installing rtk (curl fallback)"
    run sh -c 'curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh' \
        || log_warn "rtk install failed — check upstream URL"
}

install_token_savers_all() {
    case "${CERVELAI_TOKEN_SAVER:-snip}" in
        snip) install_token_savers_snip ;;
        rtk)  install_token_savers_rtk ;;
        both) install_token_savers_snip; install_token_savers_rtk ;;
        none) log_skip "token-savers: none (CERVELAI_TOKEN_SAVER=none)" ;;
        *)    log_warn "unknown CERVELAI_TOKEN_SAVER=${CERVELAI_TOKEN_SAVER}, defaulting to snip"
              install_token_savers_snip ;;
    esac
}
