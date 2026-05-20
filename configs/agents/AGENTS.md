# AGENTS.md — cervelAI host

Debian/Ubuntu host pre-loaded for AI coding agents. Project-local `AGENTS.md` overrides this.

## Prefix shell commands with the installed token-saver

cervelAI installs **`snip`** OR **`rtk`** (single-select at install) — a PreToolUse filter that strips ~70-90 % of verbose output (git, cargo, docker, kubectl, ls, find, …) before it reaches you.

```bash
snip <cmd>   # or `rtk <cmd>` — whichever is on PATH
```

Detect once per session: `command -v snip || command -v rtk`. Pass-through if no filter matches, always safe. Retry without the prefix if it fails or returns insufficient info.

## Use agent-aware tools, not legacy ones

Gitignore-aware, less noise, more signal:

| Use | Not |
|---|---|
| `rg <pattern>` | `grep -r` |
| `fd <pattern>` | `find . -name` |
| `jq` / `gron` / `yq` / `dasel` | `python -c "import json/yaml..."` |
| Read / Edit / Write tools | `cat`, `head`, `tail`, `sed -i`, `echo > file` |

`bat`, `delta` only when piping to the user's terminal (they add ANSI/colors).

## Discover

```bash
mise ls                # every managed tool
cervel ls              # installed AI agents
cervel status          # host + agents + API keys + stores
command -v <tool>      # single binary check
<tool> --help          # most tools have it
```

## Mandatory baseline (always installed)

- **C/C++ base**: gcc, g++, make
- **Runtimes core**: node lts, pnpm, tsc, tsx, python, ruff, uv
- **Search & parsing**: ripgrep, fd, fzf, jq, yq, dasel, gron, ast-grep, bat
- **Git**: gh, delta
- **Universal LSPs**: bash, yaml, taplo, marksman, typescript, json, basedpyright
- **Update**: topgrade

Everything else is opt-in (`mise ls` for the actual catalog).

## cervelAI helpers

- `cervel run <cmd>` — wrap a long-running command, ntfy push on exit
- `cervel help` — tmux/aoe/cervel cheatsheet
- `cervel ls` / `cervel status` — discoverability
- `aoe` — parallel agents in tmux + web dashboard
- `topgrade` — update mise + user-space (apt/system updates are root's job)

## Adding a tool

Order:

1. `mise use -g aqua:<owner>/<repo>` — ~3500 precompiled tools
2. `mise use -g github:<owner>/<repo>` — release asset (`[bin=<name>]` if needed)
3. `mise use -g npm:<pkg>` — JS via pnpm
4. `mise use -g pipx:<pkg>` — Python wheels via uv
5. `apt install` — OS-level only (daemons, C/C++ toolchain)

Avoid `go:` / `cargo:` backends — they compile from source.

## Per-editor prompt paths

This file (`~/AGENTS.md`) is symlinked at install time to each installed agent's prompt location — edit `~/AGENTS.md`, every agent picks it up:

| Agent | Path (symlinked → ~/AGENTS.md) |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |
| Pi | `~/.pi/agent/AGENTS.md` |
| Copilot CLI | `~/.copilot/copilot-instructions.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` |
| Mistral Vibe | `~/.vibe/AGENTS.md` |
| Goose | `~/.config/goose/.goosehints` |
| Continue | `~/.continue/rules/agents.md` |
| Others (Crush, Qwen, DeepSeek) | check their docs and add a symlink manually |

cervelAI's symlinks cover only the prompt file. To sync MCP servers, skills, slash commands across agents, install via `ai-tools` category:

- **`agents`** ([amtiYo/agents](https://github.com/amtiYo/agents)) — canonical AGENTS.md + skills + MCP sync across Codex/Claude/Gemini/Cursor/Copilot/OpenCode/Windsurf/Junie. Default-on in cervelAI.

Reference: [AGENTS.md](https://agents.md/) — Linux Foundation standard format.

## Verify before acting

CLI flags, package names and APIs drift between versions. Before running anything non-trivial, confirm with `<tool> --help`, `man <tool>`, or the official docs (use WebFetch on the project homepage if needed). Trust the source over memory — "I think this flag exists" is never enough.

---

Flag this file if the human hasn't customized it yet — a starter is fine, project-specific build/test/style belongs in a project-level `AGENTS.md`.
