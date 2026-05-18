#!/usr/bin/env bash
# smoke.sh: pre-commit smoke tests.
#   1. menu.sh survives source-in-function (catches non-global `declare`)
#   2. setup.sh exits 0 in dryrun inside debian:13 Docker (skipped if no Docker)
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

rc=0

echo "── smoke: menu.sh scope (source-in-function) ──"
if (
    set -uo pipefail
    # Mirror CATEGORIES from setup.sh: catches a new cat missing from menu.sh's _MENU_DESC.
    CATEGORIES=(agents token-savers agent-memory usage-trackers ai-tools editor ide-web runtimes workflow-tools containers k8s-stack iac-stack cloud-stack data-stack cli-extras security-tools git-forges blockchain)
    _src() { source menu.sh; }
    _src
    [[ -n "${_MENU_DEFAULT_OFF[*]:-}" ]] || exit 1
    for cat in "${CATEGORIES[@]}"; do
        [[ -n "${_MENU_DESC[$cat]:-}" ]] || {
            echo "missing _MENU_DESC[$cat]"
            exit 1
        }
    done
    declare -F \
        menu_select \
        menu_shell_select menu_multiplexer_select \
        menu_runtimes_select menu_agents_select menu_editor_select \
        menu_token_savers_select menu_agent_memory_select menu_ai_tools_select \
        menu_data_stack_select menu_containers_select menu_k8s_stack_select \
        menu_cloud_stack_select menu_blockchain_select \
        menu_cli_extras_select menu_security_tools_select menu_git_forges_select \
        >/dev/null || exit 1
); then
    echo "smoke OK : menu.sh survives source-in-function"
else
    echo "smoke FAIL : menu.sh scope broken (declare not -g?)"
    rc=1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "── smoke: setup.sh dryrun : SKIPPED (Docker not found) ──"
    echo "         otherwise, on a Debian 13 host as root:"
    echo "         dev_mode=dryrun,nomenu CERVELAI_NO_PROMPT=1 CERVELAI_SELECTED=all bash setup.sh"
    exit "$rc"
fi

echo "── smoke: setup.sh dryrun in debian:13 ──"
if docker run --rm -v "$PWD:/cervelAI:ro" -w /cervelAI \
    -e dev_mode=dryrun,nomenu -e CERVELAI_NO_PROMPT=1 -e CERVELAI_SELECTED=all \
    debian:13 bash setup.sh; then
    echo "smoke OK : setup.sh exits clean (0) in dryrun"
else
    echo "smoke FAIL : setup.sh did not exit clean in dryrun"
    rc=1
fi

exit "$rc"
