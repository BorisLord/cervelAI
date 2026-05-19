#!/usr/bin/env bash
# cervelAI-lxc.sh: phase 1, provisions a Proxmox LXC. Run as root on the host.
# Usage:
#   bash cervelAI-lxc.sh                    # interactive
#   bash cervelAI-lxc.sh --update <CTID>    # re-push + re-run setup.sh
#   dev_mode=nomenu bash cervelAI-lxc.sh    # installs everything
#   dev_mode=trace,dryrun bash cervelAI-lxc.sh

set -uo pipefail
export LC_ALL=C # silences perl locale warnings from pct/pveam
trap 'printf "\n[ ABORT ] interrupted (Ctrl+C), LXC may be partially created\n" >&2; exit 130' INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUSH_DIR="/opt/cervelAI"

DEV_MODE="${dev_mode:-}"
in_dev_mode() { [[ ",${DEV_MODE}," == *",$1,"* ]]; }
in_dev_mode trace && set -x
DRY_RUN=0
in_dev_mode dryrun && DRY_RUN=1

_color() { printf '\033[%sm' "$1"; }
log_info() { printf '%s[ INFO ]%s %s\n' "$(_color '1;34')" "$(_color 0)" "$*"; }
log_ok() { printf '%s[  OK  ]%s %s\n' "$(_color '1;32')" "$(_color 0)" "$*"; }
log_skip() { printf '%s[ SKIP ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*"; }
log_warn() { printf '%s[ WARN ]%s %s\n' "$(_color '1;33')" "$(_color 0)" "$*" >&2; }
log_err() { printf '%s[ ERR  ]%s %s\n' "$(_color '1;31')" "$(_color 0)" "$*" >&2; }
log_step() { printf '\n%s━━━ %s ━━━%s\n' "$(_color '1;36')" "$*" "$(_color 0)"; }

run() {
    if ((DRY_RUN)); then
        printf '%s[DRYRUN]%s %s\n' "$(_color '1;35')" "$(_color 0)" "$*"
    else
        "$@"
    fi
}

push_and_setup() {
    local _ctid="$1" _ct_user="$2" _ssh_key="$3"

    log_step "pushing setup files into LXC"
    run pct exec "$_ctid" -- mkdir -p "$PUSH_DIR"
    log_info "uploading ${SCRIPT_DIR}/ to ${PUSH_DIR}/"
    if ((DRY_RUN)); then
        log_info "(dryrun: skipping tar/push)"
    else
        # pct has no recursive push: tar | pct exec tar -x.
        tar -C "$SCRIPT_DIR" --exclude=.git --exclude=.gitkeep \
            --exclude=.memsearch --exclude=plan -cf - . |
            pct exec "$_ctid" -- tar -C "$PUSH_DIR" -xf -
    fi
    log_ok "files pushed to $PUSH_DIR inside LXC"

    # GITHUB_TOKEN dodges the GitHub API rate limit that 403s tool installs mid-run.
    local _gh_env=()
    [[ -n "${GITHUB_TOKEN:-}" ]] && _gh_env=("GITHUB_TOKEN=${GITHUB_TOKEN}")

    log_step "running setup.sh inside LXC"
    run pct exec "$_ctid" -- env \
        "dev_mode=${DEV_MODE}" \
        "CERVELAI_USER=${_ct_user}" \
        "CERVELAI_SSH_KEY=${_ssh_key}" \
        "${_gh_env[@]}" \
        bash "${PUSH_DIR}/setup.sh" ||
        {
            log_err "setup.sh failed inside the LXC, see the errors above"
            exit 1
        }
    log_ok "setup.sh completed"
}

[[ $EUID -eq 0 ]] || {
    log_err "must run as root on Proxmox host"
    exit 1
}
command -v pct &>/dev/null || {
    log_err "'pct' not found, not on a Proxmox host?"
    exit 1
}
command -v pveam &>/dev/null || {
    log_err "'pveam' not found"
    exit 1
}

PVE_VER=$(pveversion | grep -oE 'pve-manager/[0-9.]+' | head -1 | cut -d/ -f2 | cut -d. -f1)
if ! [[ "$PVE_VER" =~ ^(8|9)$ ]]; then
    log_warn "Proxmox VE $PVE_VER detected (expected 8 or 9), continuing anyway"
fi

UPDATE_CTID=""
while (($#)); do
    case "$1" in
        --update)
            shift
            UPDATE_CTID="${1:-}"
            [[ -n "$UPDATE_CTID" ]] || {
                log_err "--update needs a CTID"
                exit 1
            }
            ;;
        -h | --help)
            sed -n '2,8p' "$0"
            exit 0
            ;;
        *) log_warn "unknown arg: $1" ;;
    esac
    shift
done

if [[ -n "$UPDATE_CTID" ]]; then
    pct status "$UPDATE_CTID" &>/dev/null ||
        {
            log_err "CTID $UPDATE_CTID does not exist"
            exit 1
        }
    log_step "updating LXC $UPDATE_CTID"
    run pct start "$UPDATE_CTID" 2>/dev/null || true
    push_and_setup "$UPDATE_CTID" "${CERVELAI_USER:-agent}" ""
    log_ok "LXC $UPDATE_CTID updated"
    exit 0
fi

# /dev/tty explicitly so it works under `bash -c "$(curl ...)"`.
prompt_default() {
    local var="$1" question="$2" def="$3" val=""
    read -r -p "$question [$def]: " val </dev/tty
    printf -v "$var" '%s' "${val:-$def}"
}

log_step "cervelAI LXC provisioning"

log_info "storage available for the container rootfs:"
pvesm status --content rootdir 2>/dev/null |
    awk 'NR>1 {printf "         %-18s %-9s %8.1f GiB free\n", $1, $2, $6/1024/1024}'

DEFAULT_CTID="$(pvesh get /cluster/nextid 2>/dev/null || true)"
# Prefer copy-on-write pools (btrfs/zfs) for rootfs; fall back to any active.
DEFAULT_STORAGE="$(pvesm status --content rootdir 2>/dev/null |
    awk 'NR>1 && $3=="active" && $2 ~ /^(btrfs|zfspool)$/ {print $1; exit}')"
[[ -z "$DEFAULT_STORAGE" ]] && DEFAULT_STORAGE="$(pvesm status --content rootdir 2>/dev/null |
    awk 'NR>1 && $3=="active" {print $1; exit}')"
DEFAULT_TMPL_STORAGE="$(pvesm status --content vztmpl 2>/dev/null |
    awk 'NR>1 && $3=="active" {print $1; exit}')"

prompt_default CTID "Container ID (CTID):" "${DEFAULT_CTID:-100}"
prompt_default HOSTNAME "Hostname:" "cervelai"
prompt_default VCPU "vCPU cores:" "4"
prompt_default RAM_MB "RAM (MB):" "6144"
prompt_default SWAP_MB "Swap (MB, 0 to disable):" "512"
prompt_default STORAGE "Proxmox storage for the rootfs:" "${DEFAULT_STORAGE:-local-lvm}"
prompt_default DISK_GB "Disk size (GB):" "50"
prompt_default BRIDGE "Network bridge:" "vmbr0"
prompt_default CT_USER "User to create inside LXC:" "agent"
prompt_default TEMPLATE_STORAGE "Storage for the LXC template:" "${DEFAULT_TMPL_STORAGE:-local}"

SSH_KEY_FILE="/root/.ssh/id_ed25519.pub"
[[ -f "$SSH_KEY_FILE" ]] || SSH_KEY_FILE="/root/.ssh/id_rsa.pub"
if [[ -f "$SSH_KEY_FILE" ]]; then
    SSH_PUB_KEY="$(cat "$SSH_KEY_FILE")"
    log_info "using SSH key from $SSH_KEY_FILE"
else
    log_warn "no SSH key in /root/.ssh/, add one manually after install"
    SSH_PUB_KEY=""
fi

log_step "selecting Debian template (latest matching CERVELAI_TEMPLATE_PATTERN)"
TEMPLATE_PATTERN="${CERVELAI_TEMPLATE_PATTERN:-debian-[0-9]+-standard}"
TEMPLATE_NAME=$(pveam available --section system 2>/dev/null |
    awk -v pat="$TEMPLATE_PATTERN" '$0 ~ pat {print $2}' | sort -V | tail -1)

if [[ -z "$TEMPLATE_NAME" ]]; then
    log_err "no template matching '$TEMPLATE_PATTERN' available via pveam, run 'pveam update' first?"
    exit 1
fi

TEMPLATE_PATH="${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE_NAME}"

if pveam list "$TEMPLATE_STORAGE" 2>/dev/null | grep -q "$TEMPLATE_NAME"; then
    log_skip "template ${TEMPLATE_NAME} already on ${TEMPLATE_STORAGE}"
else
    log_info "downloading template ${TEMPLATE_NAME}"
    run pveam download "$TEMPLATE_STORAGE" "$TEMPLATE_NAME"
fi

log_step "creating LXC ${CTID}"
if pct status "$CTID" &>/dev/null; then
    log_err "CTID $CTID already exists, pick another one"
    exit 1
fi

# keyctl=1 + nesting=1: systemd + Docker/Podman work inside unprivileged LXC (uns isolation still holds).
run pct create "$CTID" "$TEMPLATE_PATH" \
    --hostname "$HOSTNAME" \
    --cores "$VCPU" \
    --memory "$RAM_MB" \
    --swap "$SWAP_MB" \
    --rootfs "${STORAGE}:${DISK_GB}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=dhcp" \
    --features "keyctl=1,nesting=1" \
    --unprivileged 1 \
    --onboot 1 \
    --start 1 \
    --ostype debian ||
    {
        log_err "pct create failed, check the parameters above and re-run"
        exit 1
    }

log_ok "LXC $CTID created and started"

log_step "waiting for LXC IP (DHCP)"
LXC_IP=""
for _ in {1..60}; do
    LXC_IP=$(pct exec "$CTID" -- ip -4 -o addr show eth0 2>/dev/null |
        awk '{print $4}' | cut -d/ -f1 | head -1 || true)
    [[ -n "$LXC_IP" ]] && break
    sleep 1
done

if [[ -z "$LXC_IP" ]]; then
    log_err "no IP after 60s, check Proxmox network or DHCP"
    exit 1
fi
log_ok "LXC IP: $LXC_IP"

push_and_setup "$CTID" "$CT_USER" "$SSH_PUB_KEY"

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
      pct destroy $CTID          # CAREFUL: deletes the LXC

  Update (re-push + re-run setup.sh):
      bash cervelAI-lxc.sh --update $CTID

EOF
log_ok "done"
