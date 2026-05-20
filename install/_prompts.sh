#!/usr/bin/env bash
# install/_prompts.sh: interactive prompts for GITHUB_TOKEN + per-agent API keys.

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
    # Open /dev/tty before reading: under pct exec the inode exists but opening it fails.
    if ! (: </dev/tty) 2>/dev/null; then
        log_warn "no TTY, skipping GITHUB_TOKEN prompt (installs may hit the GitHub rate limit)"
        return 0
    fi
    log_step "GitHub token (recommended, lifts the GitHub API rate limit during install)"
    log_info "create one with no scopes at https://github.com/settings/tokens"
    local val
    read -r -s -p "  GITHUB_TOKEN (leave empty to skip): " val </dev/tty || val=""
    printf '\n'
    if [[ -n "$val" ]]; then
        export GITHUB_TOKEN="$val"
        log_ok "GITHUB_TOKEN received (${#val} chars), saved to ~/.config/cervelAI/env"
    else
        log_skip "GITHUB_TOKEN skipped, installs may hit the GitHub rate limit"
    fi
    sleep 1
}

_agent_keys() {
    case "$1" in
        claude-code | pi) echo "ANTHROPIC_API_KEY" ;;
        codex) echo "OPENAI_API_KEY" ;;
        gemini-cli) echo "GEMINI_API_KEY" ;;
        qwen-code) echo "DASHSCOPE_API_KEY" ;;
        mistral-vibe) echo "MISTRAL_API_KEY" ;;
        deepseek-tui) echo "DEEPSEEK_API_KEY" ;;
        opencode | crush | goose | continue)
            echo "ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY"
            ;;
    esac
}

prompt_api_keys() {
    local u
    u="$(_user)"
    local envfile="/home/$u/${ENV_FILE_REL}"

    if [[ "${CERVELAI_NO_PROMPT:-0}" == "1" ]] || ((DRY_RUN)); then
        log_skip "API keys prompt (CERVELAI_NO_PROMPT=1 or dryrun)"
        return 0
    fi
    [[ -e "$envfile" ]] || {
        log_warn "env file missing, skip API keys"
        return 0
    }

    # shellcheck source=/dev/null
    declare -F cervelai_agent_packages_csv >/dev/null || source "${CONFIGS_DIR}/libexec/agents-registry"
    local agents="${CERVELAI_AGENTS:-}"
    [[ "$agents" == "all" ]] && agents="$(cervelai_agent_packages_csv)"
    if [[ -z "$agents" ]]; then
        log_skip "no AI agents installed, skipping API key prompt"
        return 0
    fi

    local -a want=() agent_list kv
    local a k val
    IFS=',' read -r -a agent_list <<<"$agents"
    for a in "${agent_list[@]}"; do
        a="${a// /}"
        read -r -a kv <<<"$(_agent_keys "$a")"
        for k in "${kv[@]}"; do
            [[ " ${want[*]} " == *" $k "* ]] || want+=("$k")
        done
    done
    ((${#want[@]})) || {
        log_skip "no provider keys to prompt"
        return 0
    }

    want=(GITHUB_TOKEN "${want[@]}")

    if ! (: </dev/tty) 2>/dev/null; then
        log_warn "no TTY, skipping API key entry"
        log_warn "→ add them manually to $envfile, or re-run setup.sh via 'pct enter'"
        return 0
    fi

    log_step "API keys for the agents you installed (optional, leave empty to skip)"
    for k in "${want[@]}"; do
        if grep -q "^export ${k}=" "$envfile" 2>/dev/null; then
            log_skip "${k} already present"
            continue
        fi
        read -r -s -p "  ${k} (leave empty to skip): " val </dev/tty || val=""
        printf '\n'
        if [[ -n "$val" ]]; then
            printf 'export %s=%q\n' "$k" "$val" >>"$envfile"
            log_ok "${k} received (${#val} chars), saved to ~/.config/cervelAI/env"
        else
            log_skip "${k} skipped"
        fi
    done
}
