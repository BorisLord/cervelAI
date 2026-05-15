# cervelAI

[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Proxmox%20LXC-orange)](https://pve.proxmox.com/wiki/Linux_Container)
[![Debian](https://img.shields.io/badge/Debian-13-red)](https://www.debian.org/releases/trixie/)

> Self-hosted Proxmox LXC for terminal AI coding agents — Claude Code, Codex, opencode, Gemini CLI, Aider, Pi.dev, Goose, Crush, Continue — accessible by SSH and Mosh from your laptop, your phone, anywhere.

cervelAI provisions a clean, opinionated **unprivileged Debian 13 LXC**
preloaded with every major terminal AI agent CLI, language runtimes managed by
`mise`, modern CLI tooling (ripgrep, fd, fzf, jq, lazygit, …), editors and a
shell setup. You bring your own API keys; it brings everything else.

The LXC is the **remote interactive workspace** of a human driving AI coding
agents from anywhere — reachable over **SSH / Mosh**, with **`ntfy` push
notifications** when a long agent run finishes.

## Why cervelAI?

If you're a homelabber who codes — and you want your AI agents reachable from
your phone in the metro, your iPad on the couch, or any laptop, *without*
renting someone else's cloud — you need a remote, self-hosted dev environment.
That's what cervelAI provisions: one well-curated LXC on your Proxmox, your
keys, your tunnel, your sovereignty.

Built for:

- **Homelabbers** who already run Proxmox and want a turnkey workspace for AI coding agents.
- **Solo devs** who want to fire a long agent run, walk away, and get an `ntfy` push when it's done.
- **Remote-first nomads** who code from anywhere — train, café, phone — over SSH/Mosh through a VPN they control.

Not built for: enterprise multi-tenancy, replacing Coder / Gitpod / GitHub
Codespaces, or hosting end users. cervelAI is **one person, one workspace,
KISS**.

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

> **Recommended — `GITHUB_TOKEN`:** `setup.sh` prompts for one, or `export GITHUB_TOKEN` before running. Lifts the GitHub API rate limit (60→5000 req/h) that `mise` and agent installers otherwise hit mid-install. No scopes needed.

## What you get

- **9 AI agent CLIs** — Claude Code, Codex, opencode, Pi.dev, Aider, Crush, Gemini CLI, Goose, Continue. All but Claude Code (which self-updates) are `mise`-managed, so `mise upgrade` keeps them current.
- **Language runtimes via `mise`** — `node`, `python`, `pnpm` and `uv` always installed (infrastructure); 15 more languages opt-in
- **Modern CLI tools** — ripgrep, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine
- **Editors** — vim + neovim by default; emacs, helix, micro optional
- **LSPs (auto-installed)** — bash, yaml, taplo (TOML), marksman (md), typescript-language-server (TS+JS), vscode-json-languageserver, basedpyright. Per-runtime: gopls, rust-analyzer, zls, metals (scala), lua-ls, intelephense (php), kotlin-ls, csharp-ls (.NET), next-ls (elixir), erlang_ls. Docker LSPs (dockerfile + docker-compose) only if `containers` is selected. Java/Ruby: install yourself (jdtls / `gem install ruby-lsp`).
- **Git tooling** — gh/glab/tea forge CLIs + git-delta + lazygit + gitleaks (secret scanning)
- **Shell** — bash + bash-it (zsh/fish optional), tmux
- **Remote-friendly** — SSH + Mosh, optional key-only sshd hardening
- **`ai-run`** — wrap any command to get an `ntfy` push notification when it exits
- **`topgrade`** — one command to update everything (apt + mise + npm/pipx globals + bash-it/oh-my-zsh + Claude Code)
- **Opt-in extras** — code-server, Docker/Podman/distrobox + lazydocker, token savers (snip/rtk), usage trackers (tokscale, ccusage), DB clients (sqlite/psql/redis/usql), HTTP (xh), data tools (duckdb, miller)
- **Opt-in agent memory** — cross-session recall, none pre-selected. Lite (CLI on-demand): `memsearch`, `qmd`, `engram`. Heavy (daemon, manual bootstrap): `claude-mem`, `mcp-memory-service`, `agentmemory`.

## How it works

Two phases:

1. **`cervelAI-lxc.sh`** — runs as root on the Proxmox host. Provisions the
   unprivileged LXC (`pct create`), starts it, waits for the IP, pushes the
   project into the LXC (`tar` piped through `pct exec`), then runs phase 2.
2. **`setup.sh`** — runs inside the LXC. Sources the thematic `install/*.sh`
   scripts for the selected categories, deploys the generic dotfiles from
   `configs/`, prompts for API keys, configures Mosh. Idempotent — re-running
   is safe.

Repo layout:

- `bootstrap.sh` — curl one-liner installer
- `cervelAI-lxc.sh` — phase 1 (Proxmox host)
- `setup.sh` + `menu.sh` — phase 2 (inside the LXC) + interactive `gum` menus
- `install/*.sh` — one file per category (shell, search, editor, git-tools, runtimes, agents, …) — opt-in via the menu
- `configs/` — dotfiles deployed to the LXC (bash/zsh/tmux/mise + `ai-run` + `AGENTS.md`)

Non-interactive scripting mode: `dev_mode=nomenu CERVELAI_SELECTED=shell,search,agents bash setup.sh`.

## BYOK (Bring Your Own Keys)

After install, an interactive prompt collects API keys — but **only the ones the
agents you installed can actually use** (no agents selected → no prompt):

- `ANTHROPIC_API_KEY` — Claude Code, Pi, and any multi-provider agent
- `OPENAI_API_KEY` — Codex, and any multi-provider agent
- `GEMINI_API_KEY` — Gemini CLI
- `OPENROUTER_API_KEY` — multi-provider agents (opencode, Aider, Crush, Goose, Continue)

The multi-provider agents (opencode, Aider, Crush, Goose, Continue) accept any
one of `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `OPENROUTER_API_KEY` — pick the
provider you want each agent to use. The prompt asks for the union of keys the
agents you installed can read.

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

Not handled by this script — configure on your firewall or in the LXC:

- **[WireGuard](https://www.wireguard.com/quickstart/)** — best performance, full sovereignty (tip: listen on UDP/443 to dodge carrier shaping on mobile).
- **[Tailscale](https://tailscale.com/)** — zero-config, MagicDNS, 100 devices free.

## Contributing

cervelAI is a community-friendly KISS project — **issues and pull requests are
very welcome**, whatever your level. A few light guidelines :

- **Run the gates** before opening a PR:
  ```bash
  bash check.sh    # bash -n + shellcheck
  bash smoke.sh    # setup.sh dryrun in a throwaway Debian 13 (needs Docker)
  ```
- **Keep KISS in mind** — simplest thing that works. Three similar lines beat a premature abstraction.
- **Document the WHY in commit messages**, not the WHAT (the diff speaks for itself).
- **Small focused PRs** merge faster than large refactors. Open an issue first if you're unsure.

Found a bug, want a new AI agent supported, hit a Proxmox / Debian edge case?
Open an issue — even a one-paragraph report helps. Got an opinion on the
architecture or layout? Discussions tab welcome.

## License

Released under the MIT License.
