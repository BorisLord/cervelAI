#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

rc=0

echo "── smoke: menu.sh scope (source-in-function) ──"
if (
    set -uo pipefail
    CATEGORIES=(agents token-savers agent-memory usage-trackers ai-tools editor runtimes containers k8s-stack cloud-stack data-stack cli-extras security-tools git-tools blockchain)
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
        menu_cli_extras_select menu_security_tools_select menu_git_tools_select \
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

# install_configs must be re-run safe: deploy once, then preserve user edits (incl. the .bashrc
# /etc/skel special-case) and backfill the provenance stamp on pre-stamp (upgraded) boxes.
echo "── smoke: install_configs idempotency in debian:13 ──"
if docker run --rm -i -v "$PWD:/cervelAI:ro" debian:13 bash -s <<'IDEM'; then
set -uo pipefail
CONFIGS_DIR=/cervelAI/configs
DRY_RUN=0
_user() { printf testuser; }
run() { [ "$1" = sudo ] && return 0; "$@"; }   # skip the libexec sudo symlink; not under test
log_info() { :; }; log_ok() { :; }; log_skip() { :; }; log_warn() { :; }; log_step() { :; }
_deploy_libexec() { :; }
useradd -m testuser
# shellcheck disable=SC1091
source /cervelAI/install/_user.sh
H=/home/testuser
grep -qF 'config/cervelAI/env' "$H/.bashrc" && { echo "pre: stock .bashrc already marked"; exit 1; }
install_configs
grep -qF 'config/cervelAI/env' "$H/.bashrc" || { echo "run1: stock .bashrc not replaced"; exit 1; }
[ -e "$H/.config/cervelAI/provisioned" ] || { echo "run1: stamp not written"; exit 1; }
printf '\n# USER-EDIT\n' >>"$H/.bashrc"
printf '\n# USER-EDIT\n' >>"$H/AGENTS.md"
install_configs
grep -qF 'USER-EDIT' "$H/.bashrc" || { echo "re-run clobbered .bashrc"; exit 1; }
grep -qF 'USER-EDIT' "$H/AGENTS.md" || { echo "re-run clobbered AGENTS.md"; exit 1; }
# upgrade path: pre-stamp box (managed file + edit, no stamp) must be preserved + backfilled
useradd -m olduser
_user() { printf olduser; }
install -D -m 644 -o olduser -g olduser /cervelAI/configs/agents/AGENTS.md /home/olduser/AGENTS.md
printf '\n# OLD-EDIT\n' >>/home/olduser/AGENTS.md
install_configs
grep -qF 'OLD-EDIT' /home/olduser/AGENTS.md || { echo "upgrade clobbered AGENTS.md"; exit 1; }
[ -e /home/olduser/.config/cervelAI/provisioned ] || { echo "upgrade: stamp not backfilled"; exit 1; }
echo "container: idempotency assertions passed"
IDEM
    echo "smoke OK : install_configs preserves edits on re-run + upgrade"
else
    echo "smoke FAIL : install_configs idempotency broken"
    rc=1
fi

exit "$rc"
