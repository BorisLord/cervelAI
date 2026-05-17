# cervelAI

[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Proxmox%20LXC-orange)](https://pve.proxmox.com/wiki/Linux_Container)
[![Debian](https://img.shields.io/badge/Debian-13-red)](https://www.debian.org/releases/trixie/)

> Self-hosted Proxmox LXC for terminal AI coding agents (Claude Code, Codex, opencode, Gemini CLI, Aider, Pi.dev, Goose, Crush, Continue), accessible by SSH and Mosh from your laptop, your phone, anywhere.

## Contents

1. [Why cervelAI?](#why-cervelai)
2. [Quick start](#quick-start)
3. [First login](#first-login)
4. [What you get](#what-you-get)
5. [How it works](#how-it-works)
6. [Configuration](#configuration)
7. [BYOK (Bring Your Own Keys)](#byok-bring-your-own-keys)
8. [Remote access](#remote-access)
9. [Contributing](#contributing)
10. [License](#license)

## Why cervelAI?

One well-curated, **unprivileged Debian 13 LXC** on your Proxmox, preloaded with
every major terminal AI coding agent, language runtimes via `mise`, modern CLI
tooling and a shell setup. Reachable from your phone in the metro, your iPad on
the couch, or any laptop, over SSH/Mosh through your own VPN. You bring API
keys; it brings everything else.

**One person, one workspace, KISS.** Not built for enterprise multi-tenancy or
to replace Coder / Gitpod / Codespaces.

## Quick start

On the Proxmox host, **as root**:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)"
```

Forking? Override `CERVELAI_REPO` / `CERVELAI_REF` (see [Configuration](#configuration)).

Prefer to read before you run? Manual variant:

```bash
curl -fsSL https://github.com/BorisLord/cervelAI/archive/refs/heads/main.tar.gz | tar -xz
bash cervelAI-main/cervelAI-lxc.sh
```

See [How it works](#how-it-works) for the install flow.

## First login

After the installer finishes, connect to the new LXC:

```bash
ssh agent@<lxc-ip>     # IP printed at the end of cervelAI-lxc.sh
```

You land on the **cervelai menu** (gum TUI): `resume / agents (aoe) / shell
(tmux) / status / update / plain shell`. Pick `agents` to launch the aoe
dashboard, `shell` for a persistent tmux scratch, `plain shell` to skip the
menu for this session. See [Menu bypass](#menu-bypass-runtime) to disable
permanently.

## What you get

| Category | Content |
|---|---|
| **AI agent CLIs** | claude (Anthropic), codex (OpenAI), opencode, pi.dev, aider, crush, gemini-cli, goose, continue. `mise upgrade` keeps them current. |
| **Runtimes (always)** | node, python, pnpm, uv (with tsc, tsx, ruff). |
| **Runtimes (opt-in)** | go, rust, bun, deno, zig, java, kotlin, dotnet, php, ruby, dart, scala, elixir, erlang, lua. |
| **LSPs (always)** | bash, yaml, taplo (TOML), marksman (md), typescript-ls (TS+JS), vscode-json-ls, basedpyright. |
| **LSPs (runtime-gated)** | gopls, rust-analyzer, zls, metals, lua-ls, intelephense, kotlin-ls, csharp-ls, next-ls, erlang_ls. Docker LSPs when `containers` is selected. Java/Ruby: BYO. |
| **CLI tools** | ripgrep, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine, shfmt. |
| **Editors** | vim, neovim (default); emacs, helix, micro (opt-in). |
| **Git** | gh, glab, tea, git-delta, lazygit, gitleaks. |
| **Shell** | bash + bash-it (zsh/fish opt-in), tmux. |
| **Remote** | SSH + Mosh, optional key-only sshd hardening. |
| **Agent orchestration** | `aoe` (Agent of Empires) TUI/web dashboard, one tmux session per AI agent. Skipped if no AI agent installed. |
| **Notifications** | `ai-run <cmd>`: ntfy push when the command exits. |
| **Updates** | `topgrade`: apt + mise + npm/pipx globals + bash-it/oh-my-zsh + Claude Code, one shot. |
| **Opt-in extras** | code-server, Docker/Podman + lazydocker, token savers (snip/rtk), usage trackers (tokscale, ccusage, ccstatusline), DB clients (sqlite/psql/redis/usql), HTTP (xh), data (duckdb, miller). |
| **Opt-in agent memory** | lite: memsearch, qmd, engram. heavy: claude-mem, mcp-memory-service, agentmemory. |

## How it works

Two phases:

```
┌──────────────────────────────────────────────────────────────────┐
│ Phase 1: cervelAI-lxc.sh — runs on Proxmox host as root          │
│                                                                  │
│   prompts for LXC specs (CTID, hostname, vCPU, RAM, ...)         │
│         │                                                        │
│         ▼                                                        │
│   pct create  →  pct start  →  wait for DHCP  →  tar | pct exec  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ Phase 2: setup.sh — runs inside the LXC                          │
│                                                                  │
│   gum menu (Categories)                                          │
│         │                                                        │
│         ▼                                                        │
│   install/base.sh → install/runtimes.sh → install/<cat>.sh ...   │
│         │                                                        │
│         ▼                                                        │
│   deploy configs/  →  prompt API keys  →  finalize               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

Idempotent: re-run anytime, or `bash cervelAI-lxc.sh --update <CTID>` to
re-push the repo and re-run `setup.sh` on an existing LXC.

**Repo layout:**

- `bootstrap.sh`: curl one-liner installer
- `cervelAI-lxc.sh`: phase 1 (Proxmox host)
- `setup.sh` + `menu.sh`: phase 2 + interactive gum menus
- `install/*.sh`: one file per category, opt-in via the menu
- `configs/`: dotfiles deployed to the LXC

## Configuration

### Environment variables

All `CERVELAI_*` overrides recognised by `setup.sh`. Set them before invoking
(`VAR=x bash setup.sh`) or `export` them in `bootstrap.sh`. Unset = interactive
prompt or sensible default.

| Variable | Type | Default | Effect |
|---|---|---|---|
| `CERVELAI_USER` | name | `agent` | Non-root user created inside the LXC |
| `CERVELAI_SSH_KEY` | pubkey | (prompt) | Authorised SSH key + key-only sshd hardening |
| `CERVELAI_SELECTED` | CSV of categories | (menu) | Skip the category menu (e.g. `shell,search,agents,orchestrator`) |
| `CERVELAI_SHELL` | `bash\|zsh\|fish\|none` | `bash` (+ bash-it) | Login shell |
| `CERVELAI_MULTIPLEXER` | `tmux\|zellij\|none` | `tmux` | Terminal multiplexer |
| `CERVELAI_RUNTIMES` | CSV | (menu) | Extra runtimes beyond node/python/pnpm/uv (e.g. `go,rust,bun`) |
| `CERVELAI_AGENTS` | CSV | (menu) | AI agents (`claude-code,codex,opencode,pi,aider,crush,gemini-cli,goose,continue,all,none`) |
| `CERVELAI_AGENT_MEMORY` | CSV | (menu) | Cross-session memory tools (`memsearch,qmd,engram,claude-mem,mcp-memory-service,agentmemory,all,none`) |
| `CERVELAI_EDITORS` | CSV | (menu) | `vim,neovim,emacs,helix,micro` |
| `CERVELAI_GIT_FORGES` | CSV | (menu) | `github,gitlab,gitea` |
| `CERVELAI_TOKEN_SAVER` | `snip\|rtk\|none` | (menu, `snip` in nomenu) | Token-saver CLI |
| `CERVELAI_NO_PROMPT` | `1` | unset | Skip all interactive prompts (TTY-less / CI use) |
| `CERVELAI_REPO` | `<owner>/<repo>` | `BorisLord/cervelAI` | Used by `bootstrap.sh` only (fork your own) |
| `CERVELAI_REF` | git ref | `main` | Branch/tag fetched by `bootstrap.sh` |

Non-interactive scripting: `dev_mode=nomenu CERVELAI_SELECTED=shell,search,agents bash setup.sh`.

To skip the agent orchestrator, omit `orchestrator` from `CERVELAI_SELECTED`.

### Post-install tweaks

**GITHUB_TOKEN** (recommended): `export GITHUB_TOKEN` before running, or let
`setup.sh` prompt for one. Lifts the GitHub API rate limit (60 to 5000 req/h)
that `mise` and agent installers otherwise hit mid-install. No scopes needed.

**Extra locales** (`CERVELAI_LOCALES=fr_FR.UTF-8,...`): generates additional
locales via `locale-gen`. Useful only to silence the perl warning when an SSH
client sends a non-C LANG via SendEnv. Debian's default `C.UTF-8` is enough
for the LXC itself.

**Final topgrade** (automatic): `setup.sh` runs `topgrade` at the end of install
to catch apt security updates missed by the Debian template. Always on (skipped
only in dryrun mode).

### Menu bypass (runtime)

After install, `cervelai-menu` greets every interactive login. Choose `plain
shell` to skip it for that session (sets `CERVELAI_NO_MENU=1`), or `export
CERVELAI_NO_MENU=1` in `~/.bashrc` to bypass it permanently.

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

The LXC exposes **SSH** (port 22) and **Mosh** (UDP 60000-61000). How you
connect is up to you and your infrastructure.

### From a phone

| OS | App | Notes |
|---|---|---|
| Android | **Haven (GlassHaven)** (F-Droid, free) | SSH + Mosh + userspace WireGuard/Tailscale tunnels. |
| Android | **Termux** (F-Droid) | `pkg install mosh openssh`, then `mosh agent@<lxc-ip>`. |
| Android | **Termius** | Polished, SSH/Mosh, multi-device sync. Paid (~$10/mo). |
| iOS / iPadOS | **Blink Shell** | The de facto iPad standard. ~$20/yr. |
| iOS / iPadOS | **a-Shell** | Free, OSS. No Mosh. |

### From a laptop

```bash
ssh agent@<lxc-ip>           # standard
mosh agent@<lxc-ip>          # resilient to network changes
mosh --ssh="ssh -J jump.example.com" agent@<lxc-ip>   # via ProxyJump
```

### aoe web dashboard

When the `orchestrator` category is selected and at least one AI agent is
installed, `aoe-serve.service` (systemd user, linger enabled) exposes the aoe
dashboard at `http://<lxc-ip>:8081` over the LAN. Use it from your phone or
laptop browser to watch agents in real time.

### Networking beyond the LAN

Configure on your firewall or in the LXC:

- **[WireGuard](https://www.wireguard.com/quickstart/)**: best performance, full sovereignty (tip: listen on UDP/443 to dodge carrier shaping on mobile).
- **[Tailscale](https://tailscale.com/)**: zero-config, MagicDNS, 100 devices free.

## Contributing

**Issues and pull requests are welcome**, whatever your level. Light guidelines:

- **Run the gates** before opening a PR:
  ```bash
  bash check.sh    # bash -n + shellcheck
  bash smoke.sh    # setup.sh dryrun in a throwaway Debian 13 (needs Docker)
  ```
- **Keep KISS in mind**: simplest thing that works. Three similar lines beat a premature abstraction.
- **Document the WHY in commit messages**, not the WHAT (the diff speaks for itself).
- **Small focused PRs** merge faster than large refactors. Open an issue first if you're unsure.

Found a bug, want a new AI agent supported, hit a Proxmox / Debian edge case?
Open an issue: even a one-paragraph report helps.

## License

Released under the MIT License.
