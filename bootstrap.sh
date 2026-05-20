#!/usr/bin/env bash
# Usage: bash -c "$(curl -fsSL .../bootstrap.sh)" [_ --lxc | _ --no-lxc]
# Override: CERVELAI_REPO (default BorisLord/cervelAI), CERVELAI_REF (default main).

set -euo pipefail

REPO="${CERVELAI_REPO:-BorisLord/cervelAI}"
REF="${CERVELAI_REF:-main}"
# archive/${REF}.tar.gz resolves branches AND tags; refs/heads/ only resolves branches.
TARBALL="https://github.com/${REPO}/archive/${REF}.tar.gz"

MODE=""
PASSTHRU=()
for arg in "$@"; do
    case "$arg" in
        --no-lxc) MODE=direct ;;
        --lxc) MODE=lxc ;;
        _) ;; # bash -c "$0" _ placeholder for $0
        *) PASSTHRU+=("$arg") ;;
    esac
done

[[ $EUID -eq 0 ]] || {
    echo "cervelAI: run as root" >&2
    exit 1
}
command -v curl >/dev/null || {
    echo "cervelAI: 'curl' required" >&2
    exit 1
}
command -v tar >/dev/null || {
    echo "cervelAI: 'tar' required" >&2
    exit 1
}

if [[ -z "$MODE" ]]; then
    echo "=== cervelAI bootstrap ==="
    echo
    echo "  [1] Create a new unprivileged LXC on this Proxmox host"
    echo "  [2] Install directly on THIS machine (Debian/Ubuntu)"
    echo
    while [[ -z "$MODE" ]]; do
        read -r -p "Choice: " choice </dev/tty
        case "$choice" in
            1) MODE=lxc ;;
            2) MODE=direct ;;
            *) echo "cervelAI: invalid choice '$choice' (expected 1 or 2)" >&2 ;;
        esac
    done
fi

if [[ "$MODE" == "lxc" ]] && ! command -v pct >/dev/null; then
    echo "cervelAI: LXC mode requires 'pct' (not a Proxmox host)" >&2
    exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "cervelAI: downloading ${REPO}@${REF}..."
curl -fsSL "$TARBALL" | tar -xz --strip-components=1 -C "$workdir"

if [[ "$MODE" == "direct" ]]; then
    [[ -f "$workdir/setup.sh" ]] || {
        echo "cervelAI: unexpected archive (setup.sh missing)" >&2
        exit 1
    }
    echo "cervelAI: running setup.sh directly..."
    bash "$workdir/setup.sh" "${PASSTHRU[@]}"
else
    [[ -f "$workdir/cervelAI-lxc.sh" ]] || {
        echo "cervelAI: unexpected archive (cervelAI-lxc.sh missing)" >&2
        exit 1
    }
    echo "cervelAI: launching phase 1 (LXC)..."
    bash "$workdir/cervelAI-lxc.sh" "${PASSTHRU[@]}"
fi
