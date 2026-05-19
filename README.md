<div align="center">

<img src="assets/logo.svg" alt="cervelAI" width="480">

*Pronounced like the French **« cervelet »** (cerebellum) — `/sɛʁ.və.lɛ/`*

### A comfy server, tailored for your AI.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Bash](https://img.shields.io/badge/shell-bash-89e051?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

</div>

---

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)"
```

Run it, grab a coffee. cervelAI installs a sensible default stack for your AI — terminal agents like **Claude Code, Codex, opencode, Gemini CLI and more**, along with the runtimes, memory backends and token-savers they need. A few interactive prompts let you tweak; defaults just work. Add anything else later with `mise use -g <tool>`.

Non-interactive (CI): pass `--lxc` (Proxmox host, requires `pct`) or `--no-lxc` to the one-liner.

## Make it comfy — *the nest*

A single identity (`agent` user). A persistent `shell` tmux session waiting at every SSH login. `cervel help` one keystroke away, `cervel status` to see who's home (lxc + agents + keys + disks). No noise, no surprises, no compile-from-source — `mise` owns every runtime, every binary is precompiled. SSH + Mosh keep the room reachable from anywhere, even your phone. `topgrade` tidies up in one shot.

## Stock the toolbox — *the workshop*

Pick the stack à la carte — **18 opt-in categories** (runtimes, editors, containers, k8s, cloud, data, blockchain, security, ...), sensible defaults pre-selected, zero bloat. Drop a `GITHUB_TOKEN`, sprinkle API keys, the agents introduce themselves and find their toys.

## Power it on — *the dashboard*

`aoe` (Agent of Empires) orchestrates **N agents in parallel** in tmux, each in its own git worktree, with a web dashboard reachable from any device. The token-savers (`snip`, `rtk`) sit between the shell and the model — agents see signal, not stack traces. Six **cross-session memory backends** (`memsearch`, `qmd`, `engram`, `claude-mem`, `mcp-memory-service`, `agentmemory`) so an agent picks up where it left off.

Prefer **zellij** over tmux+aoe? It's offered as a multiplexer option at install (modern Rust, simpler keybinds) — you lose aoe's web dashboard but keep the rest.

## Supported environments

Debian 12+, Ubuntu 22.04+, and any Debian/Ubuntu derivative with systemd as PID 1 (resolved via `ID_LIKE`). Tested on Proxmox LXC and cloud VMs (Hetzner, OVH).

`setup.sh` aborts early if `/run/systemd/system` is missing or the distro isn't Debian-family.

The `agent` user gets `NOPASSWD:ALL` via `/etc/sudoers.d/90-agent` (single-user workstation assumption).

## First login

```bash
ssh  agent@<host-ip>     # IP printed at the end of install
mosh agent@<host-ip>     # roaming-friendly alternative (survives Wi-Fi drops, mobile)
```

You land directly in a persistent multiplexer session named `shell` (tmux or zellij, auto-attached on every login). The `cervel` CLI exposes the cervelAI-specific helpers:

| Command | Does what |
|---|---|
| `cervel help` (`-h`) | logo + cheatsheet (tmux or zellij keybinds, aoe, cervel) |
| `cervel status` (`-s`) | lxc identity, agents installed, API keys, disk usage |
| `cervel ls` | list AI agents currently on PATH |
| `cervel run <cmd>` | wrap a command, ntfy push when it exits (long jobs) |

Everything else is native: `aoe` for the agents TUI (tmux only), `tmux` (`Ctrl-B s/c/d`) or `zellij` (`Ctrl-P d/n`) for session management, `topgrade` to update.

## What you get

<details>
<summary><b>Mandatory</b> — always installed (no prompt)</summary>

| Block | Content |
|---|---|
| Base | apt packages, gum (TUI), mosh, `agent` user, locale en_US.UTF-8 |
| C/C++ base | gcc, g++, make — full tooling is opt-in via `runtimes → c-cpp` |
| mise + topgrade | system-wide polyglot version manager + one-shot update tool |
| Runtimes core | node lts, pnpm, tsc, tsx, python, ruff, uv |
| LSPs universal | bash, yaml, taplo (TOML), marksman (md), typescript-ls, vscode-json-ls, basedpyright |
| LSPs runtime-gated | rust-analyzer, zls, lua-language-server, kotlin-language-server, ruby-lsp — auto-installed only if the matching runtime is opted in (docker LSPs if `containers` is enabled) |
| Search-core | ripgrep, fd, fzf, jq, yq, dasel, gron, ast-grep, bat |
| Git | gh (GitHub CLI), delta |

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
- claude-code, codex, opencode, pi, copilot-cli, crush, gemini-cli, goose, continue, qwen-code, mistral-vibe, deepseek-tui, grok-cli

**`token-savers`** (single-select) — pre-built filters that strip ≥60 % of command output noise before agents see it
- snip — YAML-driven pipelines, 126+ built-in filters (git, cargo, docker, kubectl, …)
- rtk — Rust binary, leaner alternative
- none

**`agent-memory`**
- memsearch, qmd, engram, claude-mem, mcp-memory-service, agentmemory

**`usage-trackers`** (one-shot, all installed) — complementary token-cost visibility
- tokscale — multi-agent dashboard (Claude, Codex, OpenCode, Gemini, Cursor, …) with 2D/3D contribution graphs
- ccusage — Claude Code historical analyzer (daily/weekly/monthly tables from local JSONL)
- ccstatusline — live Claude Code status line (Powerline rendering, real-time metrics)

**`ai-tools`**
- code2prompt, fabric, llm, **agents** (sync AGENTS.md/skills/MCP across CLIs), aichat, markitdown, mcp-inspector, shell-gpt, gptscript, promptfoo

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
- c-cpp, go, rust, bun, deno, zig, java, kotlin, dotnet, dart, scala, lua, ruby, julia, haskell

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
- cairo (Starknet: scarb + sncast via Starknet Foundry)

</details>

Run the install, then `mise ls` on the host shows exactly what was installed — the source of truth, not a manually-maintained list that drifts.

<details>
<summary><b>How it works</b> — flow, layout, idempotence</summary>

`bootstrap.sh` prompts (or accepts `--lxc` / `--no-lxc`) and dispatches:

- **LXC mode** (Proxmox host): `cervelAI-lxc.sh` creates the container (specs prompt, latest `debian-*-standard` template, DHCP wait, push repo inside), then `setup.sh` runs inside.
- **Direct mode** (Debian/Ubuntu host): `setup.sh` runs in place.

**`setup.sh` flow**: distro/systemd checks → base packages → gum prompts (shell, multiplexer, categories) → mandatory baseline (mise, runtimes core, LSPs, search-core, gh, C/C++ toolchain) → selected `install/<cat>.sh` → aoe (if applicable) → deploy `configs/` → API keys prompt → final `topgrade` → summary.

**Layout**: `bootstrap.sh` → `cervelAI-lxc.sh` (LXC only) → `setup.sh` + `menu.sh` → `install/*.sh` (one per category) + `configs/` (dotfiles).

Idempotent: re-runs skip already-installed tools.

</details>

## Updates

Inside the host, just run:

```bash
topgrade
```

That refreshes everything in one shot: apt + mise (all backends) + bash-it/oh-my-zsh + Claude Code **+ cervelAI scripts themselves** (re-fetched from upstream, re-applied idempotently — `configs/topgrade.toml` ships the custom step).

For Proxmox LXC update from the host side (re-run on an existing CTID):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/BorisLord/cervelAI/main/bootstrap.sh)" _ --lxc --update <CTID>
```

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
| `GITHUB_TOKEN` | (prompt) | Lifts the GitHub API rate limit during install |
| `CERVELAI_SHELL` | `bash` | `bash\|bash-it\|zsh\|zsh-omz\|fish\|none` |
| `CERVELAI_MULTIPLEXER` | `tmux+aoe` | `tmux+aoe\|zellij\|none` |
| `CERVELAI_AGENTS` / `_EDITOR` / `_RUNTIMES` / `_AGENT_MEMORY` / `_AI_TOOLS` | (menu) | CSV per sub-menu |
| `CERVELAI_CONTAINERS` / `_K8S_STACK` / `_DATA_STACK` | (menu) | CSV per sub-menu |
| `CERVELAI_CLOUD_STACK` / `_BLOCKCHAIN` / `_CLI_EXTRAS` / `_SECURITY_TOOLS` / `_GIT_FORGES` | (menu) | CSV per sub-menu |
| `CERVELAI_TOKEN_SAVERS` | (menu) | `snip\|rtk\|none` |
| `CERVELAI_LOCALES` | unset | Extra locales to `locale-gen` (CSV, e.g. `fr_FR.UTF-8,de_DE.UTF-8`). Useful when SSH SendEnv ships a non-C `LANG` and perl/python warn otherwise. `en_US.UTF-8` is always generated. |
| `CERVELAI_NO_MENU` | unset | Skip auto-attach to the `shell` tmux session on login |
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
`cervel run`. Skippable if you'd rather manage keys with 1password-cli, vault or
`direnv` later.

## Remote access

The host exposes **SSH** (port 22) and **Mosh** (UDP 60000-61000). Basic connection in [First login](#first-login).

- **Mobile clients**: Termux / Termius (Android), Blink Shell (iOS/iPadOS).
- **Jump host**: `mosh --ssh="ssh -J jump.example.com" agent@<host-ip>`.
- **aoe web dashboard**: `http://<host-ip>:8081` when `multiplexer=tmux+aoe` and at least one agent is installed (`aoe-serve.service` runs as systemd-user with linger).
- **Beyond LAN**: [WireGuard](https://www.wireguard.com/quickstart/) (UDP/443 to dodge mobile carrier shaping) or [Tailscale](https://tailscale.com/) (zero-config, 100 devices free).

## Contributing

PRs and issues welcome. Run `bash check.sh` and `bash smoke.sh` before opening a PR.

## License

Released under the MIT License.
