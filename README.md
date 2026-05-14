# cervelAI

![license](https://img.shields.io/badge/license-MIT-blue)
![platform](https://img.shields.io/badge/platform-Proxmox%20LXC-orange)
![Debian](https://img.shields.io/badge/Debian-13-red)

> Spin up a ready-to-use Proxmox LXC for coding with terminal AI agents — from your laptop, from your phone, from anywhere.

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
bash -c "$(curl -fsSL https://raw.githubusercontent.com/youruser/cervelAI/main/bootstrap.sh)"
```

Replace `youruser` with your GitHub account — in **two places**: the URL above
**and** the `CERVELAI_REPO` variable at the top of `bootstrap.sh`.

Prefer to read before you run? The manual variant is more auditable and
recommended on a production host:

```bash
curl -fsSL https://github.com/youruser/cervelAI/archive/refs/heads/main.tar.gz | tar -xz
bash cervelAI-main/cervelAI-lxc.sh
```

The script first **asks for** the LXC specs: CTID, hostname, vCPU, RAM, disk,
Proxmox storage, network bridge, username (default `agent`). Then, inside the
LXC, a **whiptail menu** lets you pick exactly which tools, AI agents, runtimes,
editors, git forges and shell to install — nothing is forced on you.

## What you get

- **9 AI agent CLIs** — Claude Code, Codex, opencode, Pi.dev, Aider, Crush, Gemini CLI, Goose, Continue
- **Language runtimes via `mise`** — 18 languages available; `node` + `python` by default, the rest opt-in
- **Modern CLI tools** — ripgrep, fd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, zoxide, hyperfine
- **Editors** — vim + neovim by default; emacs, helix, micro optional
- **Git tooling** — gh/glab/tea forge CLIs + git-delta + lazygit
- **Shell** — bash + bash-it (zsh/fish optional), tmux, starship
- **Remote-friendly** — SSH + Mosh, optional key-only sshd hardening
- **`ai-run`** — wrap any command to get an `ntfy` push notification when it exits
- **Opt-in extras** — code-server, Docker/Podman/distrobox, token savers (snip/rtk), usage trackers (tokscale, ccusage)

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
├── menu.sh                            ← whiptail menus (interactive setup)
├── install/                           ← thematic scripts, sourced by setup.sh
│   ├── base.sh           (essential packages, mosh, whiptail)
│   ├── shell.sh          (bash-it / oh-my-zsh / fish, tmux / zellij)
│   ├── search.sh         (rg, fd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, zoxide, hyperfine)
│   ├── editor.sh         (vim|neovim|emacs|helix|micro via CERVELAI_EDITORS)
│   ├── git-tools.sh      (gh|glab|tea via CERVELAI_GIT_FORGES + git-delta + lazygit)
│   ├── runtimes.sh       (mise + 18 languages, default node@lts + python@latest)
│   ├── python-tools.sh   (uv + ruff)
│   ├── node-tools.sh     (pnpm, typescript, tsx — opt-in)
│   ├── agents.sh         (the 9 AI agent CLIs)
│   ├── token-savers.sh   (snip | rtk via CERVELAI_TOKEN_SAVER — opt-in)
│   ├── usage-trackers.sh (tokscale + ccusage + ccstatusline — opt-in)
│   ├── ide-web.sh        (code-server — opt-in)
│   └── containers.sh     (docker, podman, distrobox — opt-in)
└── configs/                           ← dotfiles + scripts deployed into the LXC
    ├── bash/.bashrc, .bash_profile    (default shell: PATH, mise, `ai`/`t` aliases)
    ├── zsh/.zshrc, .zshenv            (optional shell: oh-my-zsh + mise)
    ├── tmux/.tmux.conf
    ├── mise/config.toml
    ├── bin/ai-run                     (run an agent + ntfy notification on exit)
    └── snip/filters/                  (add your own YAML filters here)
```

### Install modes

| Mode | Behaviour |
|---|---|
| **Interactive (default)** | A whiptail menu picks the categories, then sub-menus pick the individual AI agents, runtimes, editors, git forges and shell. No agents pre-selected. |
| **`dev_mode=nomenu`** | Non-interactive. Installs everything by default, or the categories in `CERVELAI_SELECTED` (e.g. `CERVELAI_SELECTED=shell,search,agents` + `CERVELAI_AGENTS=claude-code,opencode`). |

### `dev_mode` env var (CSV)

| Flag | Effect |
|---|---|
| `trace` | `set -x` everywhere |
| `dryrun` | Prints actions, runs nothing |
| `nomenu` | Bypass whiptail, read `CERVELAI_*` env vars |

Example: `dev_mode=trace,dryrun bash setup.sh`.

## BYOK (Bring Your Own Keys)

After install, an interactive prompt collects your API keys:

- `ANTHROPIC_API_KEY` (Claude Code)
- `OPENAI_API_KEY` (Codex CLI, opencode)
- `GEMINI_API_KEY` (Gemini CLI)
- `OPENROUTER_API_KEY` (multi-provider)
- `GROQ_API_KEY` (fast, limited free tier)

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
| Mode | Interactive whiptail menu (default); `dev_mode=nomenu` + `CERVELAI_SELECTED` for scripting |
| User | Single-user `agent` (configurable), sudo NOPASSWD |
| Specs | Always prompted (vCPU/RAM/disk/storage/bridge) |
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
