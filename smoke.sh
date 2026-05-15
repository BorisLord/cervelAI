#!/usr/bin/env bash
# smoke.sh — smoke tests, run by hand before commit:
#   1. menu.sh survives being sourced from a function (interactive-path scope)
#   2. setup.sh exits clean (0) in dryrun inside a throwaway Debian 13 (needs Docker)
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

rc=0

# ── 1. menu.sh sourced from a function (like setup.sh does) — catches a
# non-global `declare` regression without needing a TTY.
echo "── smoke: menu.sh scope (source-in-function) ──"
if (
    set -uo pipefail
    ALL_CATEGORIES=(shell search editor git-tools agents)
    OPTIONAL_CATEGORIES=(token-savers usage-trackers ide-web containers)
    _src() { source menu.sh; }
    _src
    [[ -n "${_MENU_DESC[shell]:-}" ]]   || exit 1
    [[ -n "${_MENU_DEFAULT_ON[*]:-}" ]] || exit 1
    declare -F menu_select menu_runtimes_select menu_agents_select >/dev/null || exit 1
); then
    echo "smoke OK — menu.sh survives source-in-function"
else
    echo "smoke FAIL — menu.sh scope broken (declare not -g?)"
    rc=1
fi

# ── 2. setup.sh dryrun in a throwaway Debian 13.
if ! command -v docker >/dev/null 2>&1; then
    echo "── smoke: setup.sh dryrun — SKIPPED (Docker not found) ──"
    echo "         otherwise, on a Debian 13 host as root:"
    echo "         dev_mode=dryrun,nomenu CERVELAI_NO_PROMPT=1 CERVELAI_SELECTED=all bash setup.sh"
    exit "$rc"
fi

echo "── smoke: setup.sh dryrun in debian:13 ──"
if docker run --rm -v "$PWD:/cervelAI:ro" -w /cervelAI \
        -e dev_mode=dryrun,nomenu -e CERVELAI_NO_PROMPT=1 -e CERVELAI_SELECTED=all \
        debian:13 bash setup.sh; then
    echo "smoke OK — setup.sh exits clean (0) in dryrun"
else
    echo "smoke FAIL — setup.sh did not exit clean in dryrun"
    rc=1
fi

exit "$rc"
