#!/usr/bin/env bash
# check.sh — local lint: bash -n + shellcheck on the project scripts.
# Run before commit, or wire into CI.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

rc=0
scripts=(setup.sh menu.sh cervelAI-lxc.sh bootstrap.sh check.sh smoke.sh install/*.sh configs/bin/*)

echo "── bash -n ──"
for f in "${scripts[@]}"; do
    [ -f "$f" ] || continue
    if bash -n "$f" 2>&1; then echo "  ok   $f"; else echo "  FAIL $f"; rc=1; fi
done

echo "── shellcheck ──"
if command -v shellcheck >/dev/null 2>&1; then
    # SC1090/SC1091 excluded — this project sources runtime-resolved files.
    shellcheck -e SC1090,SC1091 "${scripts[@]}" || rc=1
    shellcheck -e SC1090,SC1091 -s bash configs/bash/.bashrc configs/bash/.bash_profile || rc=1
else
    echo "  shellcheck not found — 'apt install shellcheck' to enable it"
fi

[ "$rc" -eq 0 ] && echo "OK" || echo "FAILED"
exit "$rc"
