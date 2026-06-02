#!/usr/bin/env bash

# Paperclip (paperclipai) — open-source orchestrator that runs a team of AI agents as a
# "company" (org chart, budgets, issues). Web UI + API on :3100, embedded Postgres.
#
# Opt-in sibling of aoe (NOT a category) — and deliberately the odd one out in cervelAI:
#   - STATEFUL: embedded Postgres + per-company data under the agent's ~/.paperclip.
#   - STORES SECRETS: a generated BETTER_AUTH_SECRET, plus whatever model keys you wire into
#     its adapters. This breaks cervelAI's "disposable / no secrets" promise, so it's never bundled
#     in "all": it installs only via the menu toggle (default No) or CERVELAI_PAPERCLIP=1.
#     Wiping the box still wipes everything — just know it has state.
#
# Why it fits anyway: its local adapters (opencode_local / claude_local / codex_local / …) drive
# the very agent CLIs cervelAI already installs, and it runs as the same `agent` user so it reuses
# their authenticated logins. Installing as that user (not root-global) also means the bundled
# @embedded-postgres dir is agent-owned, sidestepping the root-owned-symlink EACCES that bites a
# global install.

install_paperclip_cli() {
    # Node prebuilt binaries (and embedded-postgres) link libatomic; absent on a minimal Debian.
    apt_install libatomic1
    if _user_bash "command -v paperclipai" &>/dev/null; then
        log_skip "paperclipai already on PATH"
        return 0
    fi
    # Install with npm, NOT cervelAI's default pnpm. paperclipai pulls native modules — sqlite3 (its
    # install script fetches an N-API prebuilt via prebuild-install) and @embedded-postgres (postinstall
    # hydrates the bundled Postgres binary). pnpm 11 blocks dependency build scripts by default, so the
    # bindings end up missing and the server can't start; npm runs them, so the native deps are ready.
    # Same MISE_NPM_PACKAGE_MANAGER=npm escape hatch the pnpm bootstrap uses in install/runtimes.sh.
    run _user_bash "MISE_NPM_PACKAGE_MANAGER=npm mise use -g npm:paperclipai@latest"
}

# Authenticated/private + bind lan: reachable on the LAN, login required (Better Auth). Idempotent —
# re-running keeps the existing config. State lands in the agent's ~/.paperclip/.
install_paperclip_onboard() {
    _user_bash "command -v paperclipai" &>/dev/null || {
        log_warn "paperclipai not on PATH, skip onboard"
        return 0
    }
    # timeout: onboard --yes should set up (DB init + config) and exit; bound it so a hang
    # (e.g. if it ever foregrounds the server) can't wedge the whole cervelAI run.
    log_info "paperclip onboard (authenticated/private, bind lan)"
    soft _user_bash "timeout 180 paperclipai onboard --yes --bind lan"
}

# User systemd service (mirrors aoe-serve.service): `paperclipai run` as the agent, lingered so it
# survives logout and starts on boot. No PAPERCLIP_PUBLIC_URL hardcoded (DHCP) — auth URL mode is
# 'auto'; grab the first-admin link with `paperclipai auth bootstrap-ceo`.
install_paperclip_service() {
    local u home unit_dir src uid xdg
    u="$(_user)"
    home="/home/$u"
    unit_dir="$home/.config/systemd/user"
    src="${CONFIGS_DIR}/systemd/paperclip-serve.service"
    [[ -r "$src" ]] || {
        log_warn "configs/systemd/paperclip-serve.service missing, skip"
        return 0
    }
    log_info "deploying paperclip-serve.service (user=$u) + enabling linger"
    run install -D -m 644 -o "$u" -g "$u" "$src" "$unit_dir/paperclip-serve.service"
    run chown -R "$u:$u" "$home/.config/systemd"
    soft run loginctl enable-linger "$u"
    uid="$(id -u "$u")"
    xdg="/run/user/$uid"
    for _ in {1..20}; do
        [[ -S "$xdg/systemd/private" ]] && break
        sleep 0.5
    done
    soft run sudo -u "$u" XDG_RUNTIME_DIR="$xdg" systemctl --user daemon-reload
    soft run sudo -u "$u" XDG_RUNTIME_DIR="$xdg" systemctl --user enable --now paperclip-serve.service
}

install_paperclip_all() {
    install_paperclip_cli || {
        log_warn "paperclipai install failed, skipping onboard + service"
        return 0
    }
    install_paperclip_onboard
    install_paperclip_service
    log_ok "Paperclip → http://<host-ip>:3100 · first admin: 'paperclipai auth bootstrap-ceo'"
}
