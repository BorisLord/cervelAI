#!/usr/bin/env bash
# install/_prompts.sh: interactive prompts for GITHUB_TOKEN + per-agent API keys.

# GITHUB_TOKEN lifts the 60→5000 req/h rate limit that mise + installers hit mid-run.
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
    if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
        log_warn "no TTY, skipping GITHUB_TOKEN prompt (installs may hit the GitHub rate limit)"
        return 0
    fi
    log_step "GitHub token (recommended, lifts the GitHub API rate limit during install)"
    log_info "create one with no scopes at https://github.com/settings/tokens"
    local val
    if has_cmd gum; then
        val="$(gum input --password --prompt="  GITHUB_TOKEN (leave empty to skip): " </dev/tty)" || val=""
    else
        read -r -s -p "  GITHUB_TOKEN (leave empty to skip): " val </dev/tty || val=""
        printf '\n'
    fi
    if [[ -n "$val" ]]; then
        export GITHUB_TOKEN="$val"
        log_ok "GITHUB_TOKEN set"
    else
        log_skip "GITHUB_TOKEN skipped, installs may hit the GitHub rate limit"
    fi
}

_agent_keys() {
    case "$1" in
        claude-code | pi) echo "ANTHROPIC_API_KEY" ;;
        codex) echo "OPENAI_API_KEY" ;;
        gemini-cli) echo "GEMINI_API_KEY" ;;
        qwen-code) echo "DASHSCOPE_API_KEY" ;;
        mistral-vibe) echo "MISTRAL_API_KEY" ;;
        deepseek-tui) echo "DEEPSEEK_API_KEY" ;;
        grok-cli) echo "XAI_API_KEY" ;;
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

    local agents="${CERVELAI_AGENTS:-}"
    [[ "$agents" == "all" ]] && agents="claude-code,codex,opencode,pi,crush,gemini-cli,goose,continue,qwen-code,mistral-vibe,deepseek-tui,grok-cli"
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

    if ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
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
        if has_cmd gum; then
            val="$(gum input --password --prompt="  ${k}: " --placeholder="leave empty to skip" </dev/tty)" || val=""
        else
            read -r -s -p "  ${k}: " val </dev/tty || val=""
            printf '\n'
        fi
        if [[ -n "$val" ]]; then
            printf 'export %s=%q\n' "$k" "$val" >>"$envfile"
            log_ok "${k} written"
        else
            log_skip "${k} skipped"
        fi
    done
}
