#!/usr/bin/env bash
# smoke.sh — smoke test: runs setup.sh in dryrun inside a throwaway Debian 13
# and checks it exits clean (0). Dryrun touches nothing (run() only prints).
# Requires Docker — setup.sh needs root + Debian 13.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

if ! command -v docker >/dev/null 2>&1; then
    echo "smoke: Docker required (setup.sh needs root + Debian 13) — test skipped."
    echo "       otherwise, on a Debian 13 host as root:"
    echo "       dev_mode=dryrun,nomenu CERVELAI_NO_PROMPT=1 bash setup.sh"
    exit 0
fi

echo "── smoke: setup.sh dryrun in debian:13 ──"
if docker run --rm -v "$PWD:/cervelAI:ro" -w /cervelAI \
        -e dev_mode=dryrun,nomenu -e CERVELAI_NO_PROMPT=1 -e CERVELAI_SELECTED=all \
        debian:13 bash setup.sh; then
    echo "smoke OK — setup.sh exits clean (0) in dryrun"
    exit 0
fi
echo "smoke FAIL — setup.sh did not exit clean in dryrun"
exit 1
