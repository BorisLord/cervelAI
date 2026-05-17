# cervelAI

[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Proxmox%20LXC%20%7C%20Debian%20%7C%20Ubuntu-orange)](#supported-environments)
[![systemd](https://img.shields.io/badge/init-systemd-red)](https://systemd.io/)

> Self-hosted dev environment for terminal AI coding agents (Claude Code, Codex, opencode, Gemini CLI, Aider, Pi.dev, Goose, Crush, Continue), accessible by SSH and Mosh from your laptop, your phone, anywhere. Deploy as a Proxmox LXC, or install directly on any Debian/Ubuntu host (cloud VM, bare-metal, derivative).

## Contents

1. [Why cervelAI?](#why-cervelai)
2. [Quick start](#quick-start)
3. [Supported environments](#supported-environments)
4. [First login](#first-login)
5. [What you get](#what-you-get)
6. [BYOK (Bring Your Own Keys)](#byok-bring-your-own-keys)
7. [Remote access](#remote-access)
8. [How it works](#how-it-works)
9. [Updates](#updates)
10. [Advanced](#advanced)
11. [Contributing](#contributing)
12. [License](#license)

## Why cervelAI?

A personal AI coding workstation that delivers four concrete value props out of the box:

- **Saves tokens** : `snip` / `rtk` PreToolUse hooks cut 70-90 % of the noise piped to agents (file listings, command output, etc.)
- **Runs agents in parallel** : `aoe` orchestrator + tmux supervise N agents at once with real-time status (running / waiting / idle / error), with a web dashboard reachable from your phone
- **Persists context across sessions** : 6 memory backends (lite : `memsearch`, `qmd`, `engram` ; heavy : `claude-mem`, `mcp-memory-service`, `agentmemory`) so agents remember previous decisions
- **Works from anywhere** : SSH + Mosh, mobile clients, persistent tmux/aoe sessions survive disconnects

Plus the basics : 9 terminal agents (BYOK any provider), `mise`-managed runtimes + LSPs, modern CLI stack, optional Docker/code-server/DB/data tools, idempotent installer.

Two deploy modes, same install scripts :
- **Proxmox LXC** : isolated unprivileged container, ~5 min provision, minimal overhead
- **Direct install** : Debian/Ubuntu cloud VM or bare-metal, no virt layer

**One person, one workspace, KISS.** Self-hosted, your hardware, your keys, no lock-in. Not built for enterprise multi-tenancy or to replace Coder / Gitpod / Codespaces.

## Quick start

As root on the target host (Proxmox host, cloud VM, bare-metal Debian/Ubuntu),
the one-liner prompts which mode to use:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)"
```

```
=== cervelAI bootstrap ===

  [1] Create a new unprivileged LXC on this Proxmox host
  [2] Install directly on THIS machine (Debian/Ubuntu)

Choice:
```

Force a mode non-interactively (CI, scripting):

```bash
# Proxmox host, create an LXC
bash -c "$(curl -fsSL .../bootstrap.sh)" _ --lxc

# Cloud VM / bare-metal, install in place
bash -c "$(curl -fsSL .../bootstrap.sh)" _ --no-lxc
```

Option `[1]` only works on a Proxmox host (`pct` required); it errors clearly otherwise.

## Supported environments

| What | Status | Notes |
|---|---|---|
| **Debian 12+** | Primary target | All current and future releases |
| **Ubuntu 22.04+** | First-class | Including Kubuntu/Xubuntu/Lubuntu |
| **Debian derivatives** (LMDE, Kali, Parrot, MX-with-systemd, Raspberry Pi OS, …) | Supported via `ID_LIKE=debian` | Pi OS: ARM64 mostly works, a few aqua/mise tools may lack ARM builds |
| **Ubuntu derivatives** (Mint, Pop!_OS, elementary, Zorin, KDE Neon, …) | Supported via `ID_LIKE=ubuntu` | Docker repo auto-routed to `linux/ubuntu` |
| **Proxmox host** | Used as deploy target (creates LXC) | Or pick option `[2]` to install on the host itself |
| **Not supported** | Devuan, MX-on-sysvinit, Tails, WSL-without-systemd | Hard requirement: systemd as PID 1 |

`setup.sh` aborts early if `/run/systemd/system` is missing or the distro isn't Debian-family.

The `agent` user gets `NOPASSWD:ALL` via `/etc/sudoers.d/90-agent` — fine for a personal LXC/VM, remove it if you share the host.

## First login

```bash
ssh agent@<host-ip>     # IP printed at the end of install
```

You land on the `cervelai-menu`:

```
  cervelai entry
> resume (last session)
  agents (aoe)
  shell (tmux)
  status
  update (topgrade)
  plain shell
```

| Choice | Does what |
|---|---|
| `resume` | re-attach to your last multiplexer session |
| `agents (aoe)` | aoe TUI: every agent in its own tmux session, status at a glance |
| `shell (<mux>)` | persistent session named `shell` for scratch work (label reflects `CERVELAI_MULTIPLEXER`) |
| `status` | snapshot of multiplexer/aoe sessions + mem/load/disk |
| `update (topgrade)` | `apt` + `mise` + `npm`/`pipx` globals + agents in one shot |
| `plain shell` | bypass the menu for this session (set `CERVELAI_NO_MENU=1` to disable permanently) |

## What you get

| Category | Content |
|---|---|
| **AI agent CLIs** | claude (Anthropic), codex (OpenAI), opencode, pi.dev, aider, crush, gemini-cli, goose, continue. `mise upgrade` keeps them current. |
| **Runtimes (always)** | node, python, pnpm, uv (with tsc, tsx, ruff). |
| **Runtimes (opt-in)** | go, rust, bun, deno, zig, java, kotlin, dotnet, php, ruby, dart, scala, elixir, erlang, lua. |
| **LSPs (always)** | bash, yaml, taplo (TOML), marksman (md), typescript-ls (TS+JS), vscode-json-ls, basedpyright. |
| **LSPs (runtime-gated)** | gopls, rust-analyzer, zls, metals, lua-ls, intelephense, kotlin-ls, csharp-ls, next-ls, erlang_ls. Docker LSPs when `containers` is selected. Java/Ruby: BYO. |
| **Modern CLI** (always) | ripgrep, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine, shfmt, shellcheck, xh. AI & human friendly. |
| **Editors** (opt-in) | vim, neovim, emacs, helix, micro. |
| **Git** (always) | delta + lazygit + gitleaks + your choice of forge CLI(s) at install: GitHub (`gh`), GitLab (`glab`), Gitea/Codeberg/Forgejo (`tea`). Default: `gh`. |
| **Shell** (always) | bash + bash-it + tmux (`CERVELAI_SHELL=zsh\|fish`, `CERVELAI_MULTIPLEXER=zellij\|none`). |
| **Backbone** | `mise` (polyglot version manager), `gum` (TUI prompts), full `~/.bashrc` / `~/.zshrc` / `~/.tmux.conf`. |
| **Remote** | SSH + Mosh, optional key-only sshd hardening. |
| **Agent orchestration** | `aoe` (Agent of Empires) TUI/web dashboard, one tmux session per AI agent. **Requires tmux**; skipped if `CERVELAI_MULTIPLEXER=zellij\|none` or no AI agent installed. |
| **Notifications** | `ai-run <cmd>`: ntfy push when the command exits. |
| **Updates** | `topgrade`: apt + mise + npm/pipx globals + bash-it/oh-my-zsh + Claude Code, one shot. |
| **Opt-in extras** | code-server, Docker/Podman + lazydocker, token savers (snip/rtk), usage trackers (tokscale, ccusage, ccstatusline), data-stack (sqlite/psql/redis/usql + duckdb/miller). |
| **Opt-in agent memory** | lite: memsearch, qmd, engram. heavy: claude-mem, mcp-memory-service, agentmemory. |
| **Opt-in AI tools** | `markitdown` (PDF/DOCX/PPT → MD), `fabric` (curated prompt patterns), `mcp-inspector` (debug MCP), `code2prompt` (pack repo → LLM text), `mods` (LLM in bash pipes), `ttok` (count tokens before send). |

## How it works

`bootstrap.sh` is the entry point. It prompts (or accepts `--lxc` / `--no-lxc`) and dispatches:

**LXC mode** (Proxmox host):
1. `cervelAI-lxc.sh`: prompts for LXC specs, picks the latest `debian-*-standard` template (overridable via `CERVELAI_TEMPLATE_PATTERN`), `pct create`, waits DHCP, pushes the repo inside.
2. `setup.sh` runs inside the LXC.

**Direct mode** (Debian/Ubuntu host):
1. `setup.sh` runs in place (no container, no extra layer).

**`setup.sh`** (both modes):
- Distro + systemd checks → base packages → gum category menu → selected `install/<cat>.sh` → deploy `configs/` → prompt API keys → final `topgrade` → ready-to-use summary.

Idempotent: re-run anytime. Already-installed tools are skipped.

**Layout**: `bootstrap.sh` → `cervelAI-lxc.sh` (LXC mode only) → `setup.sh` + `menu.sh` → `install/*.sh` (one per category) + `configs/` (dotfiles).

## Updates

**LXC mode** (re-push scripts + re-run setup, from the Proxmox host):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)" _ --lxc --update <CTID>
```

**Direct mode** (re-run setup on the target host, in place):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)" _ --no-lxc
```

Idempotent in both cases: already-installed tools are skipped.

**Tool-only refresh** (without re-fetching cervelAI scripts): inside the host,
`cervelai-menu` → `update (topgrade)` runs `apt` + `mise` + `npm`/`pipx` globals + bash-it/oh-my-zsh.

## Advanced

The menu drives the install. Env vars only matter for forks, CI, or skipping
prompts. The one you may want set upfront is `GITHUB_TOKEN` (any GitHub PAT,
no scopes) to dodge the 60 req/h API rate limit during install.

<details>
<summary>Headless / CI install</summary>

```bash
dev_mode=nomenu CERVELAI_NO_PROMPT=1 CERVELAI_SELECTED=all bash setup.sh
```
</details>

<details>
<summary>Full <code>CERVELAI_*</code> env reference</summary>

Set before `setup.sh` runs. Unset = interactive prompt or sensible default.

| Variable | Default | Effect |
|---|---|---|
| `CERVELAI_USER` | `agent` | Non-root user created on the host |
| `CERVELAI_SSH_KEY` | (prompt) | Authorised SSH key + sshd key-only hardening |
| `CERVELAI_SELECTED` | (menu) | CSV of opt-in categories to install |
| `CERVELAI_SHELL` | `bash` | Always-installed: `bash\|zsh\|fish\|none` |
| `CERVELAI_MULTIPLEXER` | `tmux` | Always-installed: `tmux\|zellij\|none` |
| `CERVELAI_GIT_FORGES` | `github` | Always-installed: `github,gitlab,gitea,none` |
| `CERVELAI_RUNTIMES` | (menu) | CSV of extra runtimes (`go,rust,bun,...`) |
| `CERVELAI_AGENTS` | (menu) | CSV of AI agents |
| `CERVELAI_AGENT_MEMORY` | (menu) | CSV of cross-session memory tools |
| `CERVELAI_EDITORS` | (menu) | CSV: `vim,neovim,emacs,helix,micro` |
| `CERVELAI_TOKEN_SAVER` | (menu) | `snip\|rtk\|none` |
| `CERVELAI_LOCALES` | none | Extra locales via `locale-gen` |
| `CERVELAI_NO_PROMPT` | unset | Skip all interactive prompts |
| `CERVELAI_NO_MENU` | unset | Skip `cervelai-menu` on login (set in `~/.bashrc` to disable) |
| `CERVELAI_TEMPLATE_PATTERN` | `debian-[0-9]+-standard` | LXC mode only: regex for `pveam available` template selection (e.g. `ubuntu-24.04-standard`) |
| `CERVELAI_REPO` | `BorisLord/cervelAI` | `bootstrap.sh` only (forks) |
| `CERVELAI_REF` | `main` | Branch/tag for `bootstrap.sh` |

`topgrade` runs automatically at install end. Skipped only in dryrun.
</details>

## BYOK (Bring Your Own Keys)

After install, an interactive prompt collects API keys, but **only the ones the
agents you installed can actually use** (no agents selected: no prompt):

- `ANTHROPIC_API_KEY`: Claude Code, Pi, any multi-provider agent
- `OPENAI_API_KEY`: Codex, any multi-provider agent
- `GEMINI_API_KEY`: Gemini CLI
- `OPENROUTER_API_KEY`: multi-provider agents (opencode, Aider, Crush, Goose, Continue)

The multi-provider agents (opencode, Aider, Crush, Goose, Continue) accept any
one of `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `OPENROUTER_API_KEY`; pick the
provider you want each agent to use.

Written to `~agent/.config/cervelAI/env` (mode 600), sourced by bash, zsh and
`ai-run`. Skippable if you'd rather manage keys with 1password-cli, vault or
`direnv` later.

## Remote access

The host exposes **SSH** (port 22) and **Mosh** (UDP 60000-61000). How you
connect is up to you and your infrastructure.

### From a phone

Any SSH/Mosh client works. Examples: **Termux** or **Termius** on Android,
**Blink Shell** on iOS/iPadOS.

### From a laptop

```bash
ssh agent@<host-ip>           # standard
mosh agent@<host-ip>          # resilient to network changes
mosh --ssh="ssh -J jump.example.com" agent@<host-ip>   # via ProxyJump
```

### aoe web dashboard

When the `orchestrator` category is selected and at least one AI agent is
installed, `aoe-serve.service` (systemd user, linger enabled) exposes the aoe
dashboard at `http://<host-ip>:8081` over the LAN. Use it from your phone or
laptop browser to watch agents in real time.

### Networking beyond the LAN

Configure on your firewall or on the host:

- **[WireGuard](https://www.wireguard.com/quickstart/)**: best performance, full sovereignty (tip: listen on UDP/443 to dodge carrier shaping on mobile).
- **[Tailscale](https://tailscale.com/)**: zero-config, MagicDNS, 100 devices free.

## Contributing

PRs and issues welcome. Run `bash check.sh` and `bash smoke.sh` before opening a PR.

## License

Released under the MIT License.
