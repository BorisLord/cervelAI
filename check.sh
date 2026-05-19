#!/usr/bin/env bash
# check.sh: local lint (bash -n + shellcheck + shfmt). Run before commit.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

rc=0
scripts=(setup.sh menu.sh cervelAI-lxc.sh bootstrap.sh check.sh smoke.sh install/*.sh configs/libexec/* configs/profile.d/*.sh)

echo "── bash -n ──"
for f in "${scripts[@]}"; do
    [ -f "$f" ] || continue
    if bash -n "$f" 2>&1; then echo "  ok   $f"; else
        echo "  FAIL $f"
        rc=1
    fi
done

echo "── shellcheck ──"
if command -v shellcheck >/dev/null 2>&1; then
    # SC1090/SC1091: we source runtime-resolved files; shellcheck can't follow.
    shellcheck -e SC1090,SC1091 "${scripts[@]}" || rc=1
    shellcheck -e SC1090,SC1091 -s bash configs/bash/.bashrc configs/bash/.bash_profile || rc=1
else
    echo "  shellcheck not found; 'apt install shellcheck' to enable it"
fi

echo "── shfmt ──"
if command -v shfmt >/dev/null 2>&1; then
    shfmt -d -i 4 -ci "${scripts[@]}" || rc=1
else
    echo "  shfmt not found; 'mise use -g aqua:mvdan/sh' to enable it"
fi

[ "$rc" -eq 0 ] && echo "OK" || echo "FAILED"
exit "$rc"
