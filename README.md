# cervelAI

[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Proxmox%20LXC-orange)](https://pve.proxmox.com/wiki/Linux_Container)
[![Debian](https://img.shields.io/badge/Debian-13-red)](https://www.debian.org/releases/trixie/)

> Spin up a ready-to-use Proxmox LXC for coding with terminal AI agents from your laptop, from your phone, from anywhere.

cervelAI provisions an unprivileged Debian 13 LXC preloaded with every terminal
AI agent CLI (Claude Code, Codex, opencode, Pi.dev, Aider, Crush, Gemini CLI,
Goose, Continue), language runtimes via `mise`, modern CLI tooling, editors and
a shell setup. You bring your own API keys; it brings everything else.

The LXC is the **interactive workspace** of a human driving AI agents from
anywhere — reachable over SSH/Mosh, with `ntfy` notifications when a long agent
run finishes.

## Quick start

On the Proxmox host, **as root**. One-liner — fetches the project (tarball, no
`git` needed) then runs the provisioner:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)"
```

Forking it? Point the installer at your own repo with `CERVELAI_REPO` /
`CERVELAI_REF`, or edit those defaults at the top of `bootstrap.sh`.

Prefer to read before you run? The manual variant is more auditable and
recommended on a production host:

```bash
curl -fsSL https://github.com/BorisLord/cervelAI/archive/refs/heads/main.tar.gz | tar -xz
bash cervelAI-main/cervelAI-lxc.sh
```

The script first **prompts for** the LXC specs (CTID, hostname, vCPU, RAM, disk,
storage, bridge, username) — every field has a sensible default (next free CTID,
a btrfs/zfs pool when available, …) and the rootfs-capable storages are listed,
so you can just hit Enter through them. Then,
inside the LXC, an interactive **`gum` menu** lets you pick exactly which tools,
AI agents, runtimes, editors, git forges and shell to install — arrow keys to
move, Space to toggle, Enter to confirm. Nothing is forced on you.

> **Recommended — `GITHUB_TOKEN`:** `setup.sh` prompts for a GitHub token early
> on. You can also `export GITHUB_TOKEN` before running — it is forwarded into
> the LXC and the prompt is skipped. `mise` and several agent installers hammer
> the GitHub API; a token lifts the 60-request/hour unauthenticated limit to
> 5000/h, well clear of what a full install needs. A token with no scopes
> (public read-only) is enough.
>
> ```bash
> GITHUB_TOKEN=ghp_xxx bash cervelAI-main/cervelAI-lxc.sh
> ```

## What you get

- **9 AI agent CLIs** — Claude Code, Codex, opencode, Pi.dev, Aider, Crush, Gemini CLI, Goose, Continue. All but Claude Code (which self-updates) are `mise`-managed, so `mise upgrade` keeps them current.
- **Language runtimes via `mise`** — `node`, `python`, `pnpm` and `uv` always installed (infrastructure); 15 more languages opt-in
- **Modern CLI tools** — ripgrep, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine
- **Editors** — vim + neovim by default; emacs, helix, micro optional
- **Git tooling** — gh/glab/tea forge CLIs + git-delta + lazygit + gitleaks (secret scanning)
- **Shell** — bash + bash-it (zsh/fish optional), tmux
- **Remote-friendly** — SSH + Mosh, optional key-only sshd hardening
- **`ai-run`** — wrap any command to get an `ntfy` push notification when it exits
- **Opt-in extras** — code-server, Docker/Podman/distrobox + lazydocker, token savers (snip/rtk), usage trackers (tokscale, ccusage)

## How it works

Two phases:

1. **`cervelAI-lxc.sh`** — runs as root on the Proxmox host. Provisions the
   unprivileged LXC (`pct create`), starts it, waits for the IP, pushes the
   project into the LXC (`tar` piped through `pct exec`), then runs phase 2.
2. **`setup.sh`** — runs inside the LXC. Sources the thematic `install/*.sh`
   scripts for the selected categories, deploys the generic dotfiles from
   `configs/`, prompts for API keys, configures Mosh. Idempotent — re-running
   is safe.

```
cervelAI/
├── bootstrap.sh                       ← one-liner installer (curl) — fetches the project + runs phase 1
├── cervelAI-lxc.sh                    ← phase 1, Proxmox host
├── setup.sh                           ← phase 2, guest LXC (orchestrator)
├── menu.sh                            ← gum-backed menus (interactive setup)
├── install/                           ← thematic scripts, sourced by setup.sh
│   ├── base.sh           (essential packages, mosh, sshd, gum)
│   ├── shell.sh          (bash-it / oh-my-zsh / fish, tmux / zellij)
│   ├── search.sh         (rg, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine)
│   ├── editor.sh         (vim|neovim|emacs|helix|micro via CERVELAI_EDITORS)
│   ├── git-tools.sh      (gh|glab|tea via CERVELAI_GIT_FORGES + git-delta + lazygit + gitleaks)
│   ├── runtimes.sh       (mise system-wide + node/python/pnpm/uv always — node ships tsc/tsx, python ships ruff — +15 langs opt-in)
│   ├── agents.sh         (the 9 AI agent CLIs — mise-managed except Claude Code)
│   ├── token-savers.sh   (snip | rtk via CERVELAI_TOKEN_SAVER — opt-in)
│   ├── usage-trackers.sh (tokscale + ccusage + ccstatusline — opt-in)
│   ├── ide-web.sh        (code-server — opt-in)
│   └── containers.sh     (docker, podman, distrobox, lazydocker — opt-in)
└── configs/                           ← dotfiles + scripts deployed into the LXC
    ├── agents/AGENTS.md               (quickstart → ~/AGENTS.md: VM tools + per-editor rules paths)
    ├── bash/.bashrc, .bash_profile    (default shell: PATH, mise, `ai`/`t` aliases)
    ├── zsh/.zshrc, .zshenv            (optional shell: oh-my-zsh + mise)
    ├── tmux/.tmux.conf
    ├── mise/config.toml               (settings only — mise owns [tools])
    └── bin/ai-run                     (run an agent + ntfy notification on exit)
```

### Install modes

| Mode | Behaviour |
|---|---|
| **Interactive (default)** | A `gum` menu picks the categories, then sub-menus pick the individual AI agents, runtimes, editors, git forges and shell. No agents pre-selected. |
| **`dev_mode=nomenu`** | Non-interactive. Installs everything by default, or the categories in `CERVELAI_SELECTED` (e.g. `CERVELAI_SELECTED=shell,search,agents` + `CERVELAI_AGENTS=claude-code,opencode`). |

### `dev_mode` env var (CSV)

| Flag | Effect |
|---|---|
| `trace` | `set -x` everywhere |
| `dryrun` | Prints actions, runs nothing |
| `nomenu` | Bypass the menu, read `CERVELAI_*` env vars |

Example: `dev_mode=trace,dryrun bash setup.sh`.

## BYOK (Bring Your Own Keys)

After install, an interactive prompt collects API keys — but **only the ones the
agents you installed can actually use** (no agents selected → no prompt):

- `ANTHROPIC_API_KEY` — Claude Code, Pi, and any multi-provider agent
- `OPENAI_API_KEY` — Codex, and any multi-provider agent
- `GEMINI_API_KEY` — Gemini CLI
- `OPENROUTER_API_KEY` — multi-provider agents (opencode, Aider, Crush, Goose, Continue)

Written to `~agent/.config/cervelAI/env` (mode 600), sourced by bash, zsh and
`ai-run`. Skippable if you'd rather manage keys with 1password-cli, vault or
`direnv` later.

## Remote access

The LXC exposes **SSH** (port 22) and **Mosh** (UDP 60000-61000). How you
connect is up to you and your infrastructure.

### From a phone

| OS | App | Notes |
|---|---|---|
| Android | **Haven (GlassHaven)** — F-Droid, free | SSH + Mosh + userspace WireGuard/Tailscale tunnels. |
| Android | **Termux** — F-Droid | `pkg install mosh openssh`, then `mosh agent@<lxc-ip>`. |
| Android | **Termius** | Polished, SSH/Mosh, multi-device sync. Paid (~$10/mo). |
| iOS / iPadOS | **Blink Shell** | The de facto iPad standard. ~$20/yr. |
| iOS / iPadOS | **a-Shell** | Free, OSS. No Mosh. |

### From a laptop

```bash
ssh agent@<lxc-ip>           # standard
mosh agent@<lxc-ip>          # resilient to network changes
mosh --ssh="ssh -J jump.example.com" agent@<lxc-ip>   # via ProxyJump
```

### Networking (beyond the LAN)

Several options, **not set up by this script** — configure them on your firewall
or in the LXC:

- **WireGuard** — best performance and sovereignty. [Docs](https://www.wireguard.com/quickstart/).
- **Tailscale** — zero-config, MagicDNS, 100 devices free. [tailscale.com](https://tailscale.com/).
- **NetBird** — self-hostable OSS alternative to Tailscale. [netbird.io](https://netbird.io/).
- **Cloudflare Tunnel** — handy for HTTP, **unsuitable for SSH/Mosh** (TCP-only, no UDP).

## Development

No automatic CI (deliberate). Two gates to run by hand:

```bash
bash check.sh    # lint: bash -n + shellcheck (instant, anywhere)
bash smoke.sh    # smoke: setup.sh dryrun in a throwaway Debian 13 (needs Docker)
```

## Design decisions

| Topic | Choice |
|---|---|
| Format | Unprivileged Debian 13 Trixie LXC |
| Architecture | Everything on the OS, no Docker in the LXC by default |
| Mode | Interactive `gum` menu (default); `dev_mode=nomenu` + `CERVELAI_SELECTED` for scripting |
| User | Single-user `agent` (configurable), sudo NOPASSWD |
| Specs | Prompted with sensible defaults — Enter through to accept |
| BYOK | Post-install prompt, keys in `~/.config/cervelAI/env` |
| Notifications | `ai-run <cmd>` runs, then notifies via ntfy on exit |
| Idempotence | Re-run = "already installed" everywhere |
| Layout pattern | Omakub-lite (thematic `install/` + `configs/`) |

## Out of scope

- No Proxmox VM (LXC only).
- No VPN/tunnel setup (just mosh-server + open SSH/Mosh ports).
- No Docker by default (opt-in in the menu).
- No web IDE by default (code-server opt-in in the menu).
- No multi-user, no Coder-style multi-workspace.
- No UI/dashboard.

## Contributing

Issues and PRs welcome. Run `bash check.sh` before submitting — it must pass
clean. Keep the KISS spirit: simplest thing that works, no premature
abstraction.

## License

Released under the MIT License.
