#!/usr/bin/env bash
# bootstrap.sh — cervelAI one-liner installer, run as root on the Proxmox host:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)"
#
# Fetches the project (GitHub tarball — no git needed) into a temp dir, then runs
# phase 1 (cervelAI-lxc.sh), which is interactive. Override: CERVELAI_REPO
# (default BorisLord/cervelAI), CERVELAI_REF (default main).

set -euo pipefail

REPO="${CERVELAI_REPO:-BorisLord/cervelAI}"
REF="${CERVELAI_REF:-main}"
TARBALL="https://github.com/${REPO}/archive/refs/heads/${REF}.tar.gz"

[[ $EUID -eq 0 ]]           || { echo "cervelAI: run as root on the Proxmox host" >&2; exit 1; }
command -v pct  >/dev/null  || { echo "cervelAI: 'pct' not found — not a Proxmox host?" >&2; exit 1; }
command -v curl >/dev/null  || { echo "cervelAI: 'curl' required" >&2; exit 1; }
command -v tar  >/dev/null  || { echo "cervelAI: 'tar' required" >&2; exit 1; }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "cervelAI: downloading ${REPO}@${REF}…"
curl -fsSL "$TARBALL" | tar -xz --strip-components=1 -C "$workdir"

[[ -f "$workdir/cervelAI-lxc.sh" ]] \
    || { echo "cervelAI: unexpected archive (cervelAI-lxc.sh missing) — check CERVELAI_REPO/CERVELAI_REF" >&2; exit 1; }

echo "cervelAI: launching phase 1…"
bash "$workdir/cervelAI-lxc.sh" "$@"
