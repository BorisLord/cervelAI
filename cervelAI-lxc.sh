#!/usr/bin/env bash
# cervelAI-lxc.sh — phase 1: provisions a Proxmox LXC. Run as root on the host.
#
# Usage:
#   bash cervelAI-lxc.sh                    # interactive — pick tools in a menu
#   dev_mode=nomenu bash cervelAI-lxc.sh    # non-interactive, installs everything
#   dev_mode=trace,dryrun bash cervelAI-lxc.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── dev_mode ─────────────────────────────────────────────────────────────────
DEV_MODE="${dev_mode:-}"
in_dev_mode() { [[ ",${DEV_MODE}," == *",$1,"* ]]; }
in_dev_mode trace && set -x
DRY_RUN=0; in_dev_mode dryrun && DRY_RUN=1

# ─── logging ──────────────────────────────────────────────────────────────────
_c() { printf '\033[%sm' "$1"; }
log_info() { printf '%s[ INFO ]%s %s\n' "$(_c '1;34')" "$(_c 0)" "$*"; }
log_ok()   { printf '%s[  OK  ]%s %s\n' "$(_c '1;32')" "$(_c 0)" "$*"; }
log_skip() { printf '%s[ SKIP ]%s %s\n' "$(_c '1;33')" "$(_c 0)" "$*"; }
log_warn() { printf '%s[ WARN ]%s %s\n' "$(_c '1;33')" "$(_c 0)" "$*" >&2; }
log_err()  { printf '%s[ ERR  ]%s %s\n' "$(_c '1;31')" "$(_c 0)" "$*" >&2; }
log_step() { printf '\n%s━━━ %s ━━━%s\n' "$(_c '1;36')" "$*" "$(_c 0)"; }

run() {
    if (( DRY_RUN )); then
        printf '%s[DRYRUN]%s %s\n' "$(_c '1;35')" "$(_c 0)" "$*"
    else
        "$@"
    fi
}

# ─── guards ───────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || { log_err "must run as root on Proxmox host"; exit 1; }
command -v pct &>/dev/null || { log_err "'pct' not found — not on a Proxmox host?"; exit 1; }
command -v pveam &>/dev/null || { log_err "'pveam' not found"; exit 1; }

PVE_VER=$(pveversion | grep -oE 'pve-manager/[0-9.]+' | head -1 | cut -d/ -f2 | cut -d. -f1)
if ! [[ "$PVE_VER" =~ ^(8|9)$ ]]; then
    log_warn "Proxmox VE $PVE_VER detected (expected 8 or 9) — continuing anyway"
fi

# ─── parse args ───────────────────────────────────────────────────────────────
while (( $# )); do
    case "$1" in
        -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
        *) log_warn "unknown arg: $1" ;;
    esac
    shift
done

# ─── prompts (no defaults — the user decides) ─────────────────────────────────
prompt_required() {
    local var="$1" question="$2" val=""
    while [[ -z "$val" ]]; do
        read -r -p "$question " val
    done
    printf -v "$var" '%s' "$val"
}

prompt_default() {
    local var="$1" question="$2" def="$3" val=""
    read -r -p "$question [$def]: " val
    printf -v "$var" '%s' "${val:-$def}"
}

log_step "cervelAI LXC provisioning"
prompt_required CTID       "Container ID (CTID):"
prompt_required HOSTNAME   "Hostname:"
prompt_required VCPU       "vCPU cores:"
prompt_required RAM_MB     "RAM (MB):"
prompt_required DISK_GB    "Disk size (GB):"
prompt_required STORAGE    "Proxmox storage (e.g. local-lvm):"
prompt_default  BRIDGE     "Network bridge:" "vmbr0"
prompt_default  CT_USER    "User to create inside LXC:" "agent"
prompt_default  TEMPLATE_STORAGE "Storage for the LXC template:" "local"

# SSH key — picks up the host's root public key by default.
SSH_KEY_FILE="/root/.ssh/id_ed25519.pub"
[[ -f "$SSH_KEY_FILE" ]] || SSH_KEY_FILE="/root/.ssh/id_rsa.pub"
if [[ -f "$SSH_KEY_FILE" ]]; then
    SSH_PUB_KEY="$(cat "$SSH_KEY_FILE")"
    log_info "using SSH key from $SSH_KEY_FILE"
else
    log_warn "no SSH key found in /root/.ssh/ — you'll need to add one manually after"
    SSH_PUB_KEY=""
fi

# ─── Debian 13 template ───────────────────────────────────────────────────────
log_step "ensuring Debian 13 template available"
TEMPLATE_NAME=$(pveam available --section system 2>/dev/null \
    | awk '/debian-13-standard/ {print $2}' | sort -V | tail -1)

if [[ -z "$TEMPLATE_NAME" ]]; then
    log_err "no debian-13-standard template available via pveam — run 'pveam update' first?"
    exit 1
fi

TEMPLATE_PATH="${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE_NAME}"

if pveam list "$TEMPLATE_STORAGE" 2>/dev/null | grep -q "$TEMPLATE_NAME"; then
    log_skip "template ${TEMPLATE_NAME} already on ${TEMPLATE_STORAGE}"
else
    log_info "downloading template ${TEMPLATE_NAME}"
    run pveam download "$TEMPLATE_STORAGE" "$TEMPLATE_NAME"
fi

# ─── create LXC ───────────────────────────────────────────────────────────────
log_step "creating LXC ${CTID}"
if pct status "$CTID" &>/dev/null; then
    log_err "CTID $CTID already exists — pick another one"
    exit 1
fi

# Features: keyctl=1 (keeps systemd happy), nesting=0 (security).
# For Docker inside the LXC, enable nesting=1 manually afterwards.
run pct create "$CTID" "$TEMPLATE_PATH" \
    --hostname "$HOSTNAME" \
    --cores "$VCPU" \
    --memory "$RAM_MB" \
    --swap 512 \
    --rootfs "${STORAGE}:${DISK_GB}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=dhcp" \
    --features "keyctl=1,nesting=0" \
    --unprivileged 1 \
    --onboot 1 \
    --start 1 \
    --ostype debian

log_ok "LXC $CTID created and started"

# ─── wait for IP ──────────────────────────────────────────────────────────────
log_step "waiting for LXC IP (DHCP)"
LXC_IP=""
for _ in {1..60}; do
    LXC_IP=$(pct exec "$CTID" -- ip -4 -o addr show eth0 2>/dev/null \
        | awk '{print $4}' | cut -d/ -f1 | head -1 || true)
    [[ -n "$LXC_IP" ]] && break
    sleep 1
done

if [[ -z "$LXC_IP" ]]; then
    log_err "no IP after 60s — check Proxmox network or DHCP"
    exit 1
fi
log_ok "LXC IP: $LXC_IP"

# ─── push project files ───────────────────────────────────────────────────────
log_step "pushing setup files into LXC"
PUSH_DIR="/opt/cervelAI"
run pct exec "$CTID" -- mkdir -p "$PUSH_DIR"

# pct has no recursive push, so we tar | pct exec tar -x.
log_info "uploading ${SCRIPT_DIR}/ → ${PUSH_DIR}/"
if (( DRY_RUN )); then
    log_info "(dryrun: skipping tar/push)"
else
    tar -C "$SCRIPT_DIR" --exclude=.git --exclude=.gitkeep -cf - . \
        | pct exec "$CTID" -- tar -C "$PUSH_DIR" -xf -
fi
log_ok "files pushed to $PUSH_DIR inside LXC"

# ─── run setup.sh ─────────────────────────────────────────────────────────────
# setup.sh is interactive by default; the host TTY propagates through pct exec.
# For a non-interactive run, pass dev_mode=nomenu (forwarded below).
log_step "running setup.sh inside LXC"
run pct exec "$CTID" -- env \
    "dev_mode=${DEV_MODE}" \
    "CERVELAI_USER=${CT_USER}" \
    "CERVELAI_SSH_KEY=${SSH_PUB_KEY}" \
    bash "${PUSH_DIR}/setup.sh"

log_ok "setup.sh completed"

# ─── post-install summary ─────────────────────────────────────────────────────
log_step "summary"
cat <<EOF

  CTID:     $CTID
  Hostname: $HOSTNAME
  IP:       $LXC_IP
  User:     $CT_USER

  Connect:
      ssh ${CT_USER}@${LXC_IP}
      mosh ${CT_USER}@${LXC_IP}

  Manage:
      pct enter $CTID            # shell inside LXC as root
      pct stop $CTID
      pct start $CTID
      pct destroy $CTID          # CAREFUL — deletes the LXC

  Re-run setup:
      pct exec $CTID -- bash ${PUSH_DIR}/setup.sh

EOF
log_ok "done"
