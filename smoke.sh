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
    CATEGORIES=(editor agents orchestrator token-savers usage-trackers ide-web containers data-stack agent-memory ai-tools)
    _src() { source menu.sh; }
    _src
    [[ -n "${_MENU_DEFAULT_OFF[*]:-}" ]] || exit 1
    for cat in "${CATEGORIES[@]}"; do
        [[ -n "${_MENU_DESC[$cat]:-}" ]] || {
            echo "missing _MENU_DESC[$cat]"
            exit 1
        }
    done
    declare -F menu_select menu_runtimes_select menu_agents_select >/dev/null || exit 1
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
