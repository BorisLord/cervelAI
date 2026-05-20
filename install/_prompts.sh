#!/usr/bin/env bash

prompt_github_token() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log_skip "GITHUB_TOKEN already set, used for mise + GitHub API"
        export GITHUB_TOKEN
        return 0
    fi
    if [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || ((DRY_RUN)); then
        log_skip "GITHUB_TOKEN prompt (CERVELAI_NO_PROMPT=1 or dryrun)"
        return 0
    fi
    # under pct exec the /dev/tty inode exists but opening it fails.
    if ! (: </dev/tty) 2>/dev/null; then
        log_warn "no TTY, skipping GITHUB_TOKEN prompt (installs may hit the GitHub rate limit)"
        return 0
    fi
    log_step "GitHub token (recommended, lifts the GitHub API rate limit during install)"
    log_info "not persisted — used only to install everything (most tools download from GitHub), never written to disk"
    log_info "create one with no scopes at https://github.com/settings/tokens"
    local val
    read -r -s -p "  GITHUB_TOKEN (leave empty to skip): " val </dev/tty || val=""
    printf '\n'
    if [[ -n "$val" ]]; then
        export GITHUB_TOKEN="$val"
        log_ok "GITHUB_TOKEN received (${#val} chars), used for this install only (not saved)"
    else
        log_skip "GITHUB_TOKEN skipped, installs may hit the GitHub rate limit"
    fi
    sleep 1
}
