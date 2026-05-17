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
5. [BYOK (Bring Your Own Keys)](#byok-bring-your-own-keys)
6. [Remote access](#remote-access)
7. [How it works](#how-it-works)
8. [Updates](#updates)
9. [Advanced](#advanced)
10. [Contributing](#contributing)
11. [License](#license)

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

## First login

```bash
ssh agent@<lxc-ip>     # IP printed at the end of cervelAI-lxc.sh
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
| `resume` | re-attach to your last tmux session |
| `agents (aoe)` | aoe TUI: every agent in its own tmux session, status at a glance |
| `shell (tmux)` | persistent tmux session named `shell` for scratch work |
| `status` | snapshot of tmux/aoe sessions + mem/load/disk |
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
| **CLI tools** | ripgrep, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine, shfmt, shellcheck, hadolint. |
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

Two phases, idempotent:

1. **Host** (`cervelAI-lxc.sh`): prompts for LXC specs, `pct create`, waits for DHCP, pushes the repo into the LXC.
2. **LXC** (`setup.sh`): gum menu → base + runtimes + selected categories → deploys configs → prompts for API keys → final topgrade.

**Layout**: `bootstrap.sh` (curl one-liner) → `cervelAI-lxc.sh` (phase 1) → `setup.sh` + `menu.sh` (phase 2) → `install/*.sh` (one per category) + `configs/` (dotfiles).

## Updates

Re-fetch the latest cervelAI scripts and apply to an existing LXC:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)" _ --update <CTID>
```

Idempotent: already-installed tools are skipped, only the deltas run.
Also available from inside the LXC: `cervelai-menu` → `update (topgrade)`
refreshes apt + mise + agents (but not the cervelAI scripts themselves).

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
| `CERVELAI_USER` | `agent` | Non-root user created inside the LXC |
| `CERVELAI_SSH_KEY` | (prompt) | Authorised SSH key + sshd key-only hardening |
| `CERVELAI_SELECTED` | (menu) | CSV of categories to install |
| `CERVELAI_SHELL` | `bash` | `bash\|zsh\|fish\|none` |
| `CERVELAI_MULTIPLEXER` | `tmux` | `tmux\|zellij\|none` |
| `CERVELAI_RUNTIMES` | (menu) | CSV of extra runtimes (`go,rust,bun,...`) |
| `CERVELAI_AGENTS` | (menu) | CSV of AI agents |
| `CERVELAI_AGENT_MEMORY` | (menu) | CSV of cross-session memory tools |
| `CERVELAI_EDITORS` | (menu) | CSV: `vim,neovim,emacs,helix,micro` |
| `CERVELAI_GIT_FORGES` | (menu) | CSV: `github,gitlab,gitea` |
| `CERVELAI_TOKEN_SAVER` | (menu) | `snip\|rtk\|none` |
| `CERVELAI_LOCALES` | none | Extra locales via `locale-gen` |
| `CERVELAI_NO_PROMPT` | unset | Skip all interactive prompts |
| `CERVELAI_NO_MENU` | unset | Skip `cervelai-menu` on login (set in `~/.bashrc` to disable) |
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

The LXC exposes **SSH** (port 22) and **Mosh** (UDP 60000-61000). How you
connect is up to you and your infrastructure.

### From a phone

Any SSH/Mosh client works. Examples: **Termux** or **Termius** on Android,
**Blink Shell** on iOS/iPadOS.

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

PRs and issues welcome. Run `bash check.sh` and `bash smoke.sh` before opening a PR.

## License

Released under the MIT License.
