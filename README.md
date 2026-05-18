<div align="center">

<img src="assets/logo.svg" alt="cervelAI" width="480">

*Pronounced like the French **« cervelet »** (cerebellum) — `/sɛʁ.və.lɛ/`*

### Your AI coding agents, self-hosted. Anywhere, any device.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Bash](https://img.shields.io/badge/shell-bash-89e051?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

</div>

---

**12 terminal AI agents** — Claude Code · Codex · opencode · Gemini CLI · Pi.dev · Crush · Goose · Continue · Qwen Code · Mistral Vibe · DeepSeek TUI · Grok CLI

**Run them in parallel** via `aoe` (tmux + web dashboard) · **Save 70–90 % tokens** with `snip` / `rtk` · **Cross-session memory** (6 backends) · **Access from anywhere** (SSH + Mosh, phone-friendly)

**Make it your own stack** — 18 opt-in categories à la carte (runtimes, editors, containers, k8s, cloud, data, blockchain, ...), sensible defaults pre-selected, no bloat.

**All managed by `mise`, all precompiled** — no compile-from-source, no waiting on cargo/go, one `topgrade` updates everything.

**Deploy on** Proxmox LXC · Debian/Ubuntu cloud VM · bare-metal — same install scripts.

## Why cervelAI?

A personal AI coding workstation that delivers four concrete value props out of the box:

- **Saves tokens** : `snip` / `rtk` PreToolUse hooks cut 70-90 % of the noise piped to agents (file listings, command output, etc.)
- **Runs agents in parallel** : `aoe` orchestrator + tmux supervise N agents at once with real-time status (running / waiting / idle / error), with a web dashboard reachable from your phone
- **Persists context across sessions** : 6 memory backends (lite : `memsearch`, `qmd`, `engram` ; heavy : `claude-mem`, `mcp-memory-service`, `agentmemory`) so agents remember previous decisions
- **Works from anywhere** : SSH + Mosh, mobile clients, persistent tmux/aoe sessions survive disconnects

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

Non-interactive (CI, scripting): pass `--lxc` (Proxmox host, requires `pct`) or `--no-lxc` (install in place) to the bootstrap one-liner above.

## Supported environments

Debian 12+, Ubuntu 22.04+, and any Debian/Ubuntu derivative with systemd as PID 1 (resolved via `ID_LIKE`). Tested on Proxmox LXC and cloud VMs (Hetzner, OVH).

`setup.sh` aborts early if `/run/systemd/system` is missing or the distro isn't Debian-family.

The `agent` user gets `NOPASSWD:ALL` via `/etc/sudoers.d/90-agent` — fine for a personal LXC/VM, remove it if you share the host.

## First login

```bash
ssh agent@<host-ip>     # IP printed at the end of install
```

You land on the `cervelai-menu`:

| Choice | Does what |
|---|---|
| `resume (last session)` | re-attach to your last multiplexer session |
| `agents (aoe)` | aoe TUI: every agent in its own tmux session, status at a glance |
| `shell (<mux>)` | persistent session named `shell` for scratch work |
| `status` | snapshot of multiplexer/aoe sessions + mem/load/disk |
| `update (topgrade)` | runs `topgrade` (apt + mise + bash-it/oh-my-zsh + Claude Code) |
| `plain shell` | bypass the menu for this session (set `CERVELAI_NO_MENU=1` to disable permanently) |

## What you get

<details>
<summary><b>Mandatory</b> — always installed (no prompt)</summary>

| Block | Content |
|---|---|
| Base | apt packages, gum (TUI), mosh, `agent` user, locale en_US.UTF-8 |
| mise + topgrade | system-wide polyglot version manager + one-shot update tool |
| Runtimes core | node lts, pnpm, tsc, tsx, python, ruff, uv |
| LSPs universal | bash, yaml, taplo (TOML), marksman (md), typescript-ls, vscode-json-ls, basedpyright |
| LSPs runtime-gated | gopls, rust-analyzer, zls, lua-ls, kotlin-ls, ruby-lsp (if matching runtime present) |
| Search-core | ripgrep, fd, fzf, jq, yq, dasel, gron, ast-grep, bat, delta |
| Git | gh (GitHub CLI) |

</details>

<details>
<summary><b>Workspace setup</b> — 2 always-asked prompts (single-select)</summary>

**Login shell** — bash · bash-it · zsh · zsh-omz · fish

**Terminal multiplexer** — tmux+aoe · zellij · none

</details>

### Opt-in categories (18) — multi-select via menu

<details>
<summary><b>AI &amp; assistance</b> — agents · token-savers · agent-memory · usage-trackers · ai-tools</summary>

**`agents`** — AI agent CLIs
- claude-code, codex, opencode, pi, crush, gemini-cli, goose, continue, qwen-code, mistral-vibe, deepseek-tui, grok-cli

**`token-savers`** (single-select)
- snip — YAML pipelines, 60-90% token savings
- rtk — Rust binary, 100+ commands built-in
- none

**`agent-memory`**
- memsearch, qmd, engram, claude-mem, mcp-memory-service, agentmemory

**`usage-trackers`** (one-shot, all installed)
- tokscale, ccusage, ccstatusline

**`ai-tools`**
- code2prompt, fabric, llm, ttok, aichat, markitdown, mcp-inspector, shell-gpt, gptscript

</details>

<details>
<summary><b>Workspace</b> — editor · ide-web</summary>

**`editor`**
- vim, neovim, emacs, micro

**`ide-web`** (one-shot)
- code-server (browser-based VS Code, installed + systemd unit, not auto-started)

</details>

<details>
<summary><b>Languages &amp; build</b> — runtimes · workflow-tools</summary>

**`runtimes`** — extras (node/python always installed)
- go, rust, bun, deno, zig, java, kotlin, dotnet, dart, scala, lua, ruby, julia, haskell

**`workflow-tools`** (one-shot, all installed)
- act (GitHub Actions local), just (task runner), watchexec (file watcher)

</details>

<details>
<summary><b>DevOps &amp; Infra</b> — containers · k8s-stack · iac-stack · cloud-stack</summary>

**`containers`**
- docker, lazydocker, hadolint, podman, dive

**`k8s-stack`**
- kubectl, k9s, helm, kubectx, kubens, kustomize, kind, stern

**`iac-stack`** (one-shot, all installed)
- opentofu, pulumi

**`cloud-stack`**
- aws, flyctl, cloudflared, supabase, doctl, hcloud, scaleway, gcloud, azure

</details>

<details>
<summary><b>Data</b> — data-stack</summary>

**`data-stack`**
- sqlite3, pgcli, duckdb, postgresql-client, redis-tools, usql, mlr, mycli, litecli, lazysql

</details>

<details>
<summary><b>Productivity &amp; polish</b> — cli-extras</summary>

**`cli-extras`** — modern CLI extras (search-core already mandatory)
- eza, zoxide, tldr, yazi, glow, sd, hyperfine, shfmt, shellcheck, xh, typos

</details>

<details>
<summary><b>Security</b> — security-tools</summary>

**`security-tools`**
- sops (encrypt YAML/JSON/.env with age/KMS)
- age (modern file encryption CLI)
- kingfisher (AI-aware secret scanner — Anthropic/OpenAI/Gemini/...)
- varlock (AI-safe .env: schemas for agents, secrets for humans)
- dotenvx (encrypted .env files)
- infisical (centralized secret manager CLI)
- teller (multi-backend secret fetcher)
- trivy (CVE/IaC/secrets/SBOM scanner)
- gitleaks (committed-secret scanner)
- syft (SBOM generator)
- cosign (sign/verify images + artifacts)

</details>

<details>
<summary><b>Niche</b> — git-forges · blockchain</summary>

**`git-forges`** (gh + delta already mandatory)
- lazygit, gitlab (glab)

**`blockchain`**
- evm (Ethereum: solc + foundry + LSP + slither + solhint)
- solana (agave validator/CLI + anchor)
- move (Sui + Aptos, ~1 GB)
- cosmos (Cosmos SDK: gaiad + ignite)
- near (near-cli-rs)
- cairo (Starknet: scarb + starkli)

</details>

Run the install, then `mise ls` on the host shows exactly what was installed — that's the source of truth, not a manually-maintained list that drifts.

### Backbone
- Full `~/.bashrc`, `~/.zshrc`, `~/.tmux.conf` deployed (configs/)
- `ai-run <cmd>` wrapper: ntfy push when command exits (topic in `~/.config/cervelAI/env`)

## How it works

`bootstrap.sh` is the entry point. It prompts (or accepts `--lxc` / `--no-lxc`) and dispatches:

**LXC mode** (Proxmox host):
1. `cervelAI-lxc.sh`: prompts for LXC specs, picks the latest `debian-*-standard` template (overridable via `CERVELAI_TEMPLATE_PATTERN`), `pct create`, waits DHCP, pushes the repo inside.
2. `setup.sh` runs inside the LXC.

**Direct mode** (Debian/Ubuntu host):
1. `setup.sh` runs in place (no container, no extra layer).

**`setup.sh`** (both modes):
- Distro/systemd checks → base packages → gum prompts (shell, multiplexer, categories + sub-menus) → mandatory baseline (mise, runtimes core, LSPs, search-core, gh) → selected `install/<cat>.sh` → aoe (if applicable) → deploy `configs/` → prompt API keys → final `topgrade` → summary.

**Layout**: `bootstrap.sh` → `cervelAI-lxc.sh` (LXC mode only) → `setup.sh` + `menu.sh` → `install/*.sh` (one per category) + `configs/` (dotfiles).

Idempotent: re-runs skip already-installed tools.

## Updates

Re-run the bootstrap to refresh scripts + tools (LXC mode adds `--update <CTID>`):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)" _ --no-lxc
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)" _ --lxc --update <CTID>
```

Or **tool-only refresh** (no script re-fetch): inside the host, `cervelai-menu` → `update (topgrade)` runs `apt` + `mise` (all backends) + bash-it/oh-my-zsh.

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

The menu fills every `CERVELAI_*` automatically. Set them by hand only for CI / headless / fork overrides.

| Variable | Default | Effect |
|---|---|---|
| `CERVELAI_NO_PROMPT` | unset | Skip interactive prompts (CI) |
| `CERVELAI_SELECTED` | (menu) | CSV of opt-in categories (or `all`) |
| `CERVELAI_SSH_KEY` | (prompt) | Pubkey added to `agent`, plus sshd key-only hardening |
| `CERVELAI_USER` | `agent` | Non-root user created on the host |
| `CERVELAI_LOCALES` | none | Extra locales via `locale-gen` |
| `GITHUB_TOKEN` | (prompt) | Lifts the GitHub API rate limit during install |
| `CERVELAI_SHELL` | `bash` | `bash\|bash-it\|zsh\|zsh-omz\|fish\|none` |
| `CERVELAI_MULTIPLEXER` | `tmux+aoe` | `tmux+aoe\|zellij\|none` |
| `CERVELAI_AGENTS` / `_EDITORS` / `_RUNTIMES` / `_AGENT_MEMORY` / `_AI_TOOLS` | (menu) | CSV per sub-menu |
| `CERVELAI_CONTAINERS` / `_K8S_STACK` / `_DATA_STACK` | (menu) | CSV per sub-menu |
| `CERVELAI_CLOUD_STACK` / `_BLOCKCHAIN` / `_CLI_EXTRAS` / `_SECURITY_TOOLS` / `_GIT_FORGES` | (menu) | CSV per sub-menu |
| `CERVELAI_TOKEN_SAVER` | (menu) | `snip\|rtk\|none` |
| `CERVELAI_NO_MENU` | unset | Skip `cervelai-menu` on login |
| `CERVELAI_TEMPLATE_PATTERN` | `debian-[0-9]+-standard` | LXC mode only: pveam regex |
| `CERVELAI_REPO` / `CERVELAI_REF` | `BorisLord/cervelAI` / `main` | `bootstrap.sh` only (forks) |

`topgrade` runs automatically at install end. Skipped only in dryrun.
</details>

## BYOK (Bring Your Own Keys)

After install, an interactive prompt collects API keys, but **only the ones the
agents you installed can actually use** (no agents selected: no prompt):

| Key | Agents needing it |
|---|---|
| `ANTHROPIC_API_KEY` | Claude Code, Pi, any multi-provider agent |
| `OPENAI_API_KEY` | Codex, any multi-provider agent |
| `GEMINI_API_KEY` | Gemini CLI |
| `OPENROUTER_API_KEY` | Multi-provider agents (opencode, Crush, Goose, Continue) |
| `MISTRAL_API_KEY` | Mistral Vibe |
| `DEEPSEEK_API_KEY` | DeepSeek TUI |
| `DASHSCOPE_API_KEY` | Qwen Code (Alibaba) |
| `XAI_API_KEY` | Grok CLI |

Multi-provider agents (opencode, Crush, Goose, Continue) accept any of
`ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `OPENROUTER_API_KEY` — pick the
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

When `multiplexer=tmux+aoe` (default) and at least one AI agent is installed,
`aoe-serve.service` (systemd user, linger enabled) exposes the aoe dashboard at
`http://<host-ip>:8081` over the LAN. Use it from your phone or laptop browser
to watch agents in real time.

### Networking beyond the LAN

Configure on your firewall or on the host:

- **[WireGuard](https://www.wireguard.com/quickstart/)**: best performance, full sovereignty (tip: listen on UDP/443 to dodge carrier shaping on mobile).
- **[Tailscale](https://tailscale.com/)**: zero-config, MagicDNS, 100 devices free.

## Contributing

PRs and issues welcome. Run `bash check.sh` and `bash smoke.sh` before opening a PR.

## License

Released under the MIT License.
