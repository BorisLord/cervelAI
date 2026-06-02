Debian/Ubuntu host pre-loaded for AI coding agents (cervelAI). A project's own `AGENTS.md` overrides this. This is a **starter** — customize it; project build/test/style belong in a project-level `AGENTS.md`.

## Token-saver — prefix shell commands

cervelAI installs **`snip`** or **`rtk`** (chosen at install): a PreToolUse filter that strips ~70-90 % of verbose CLI output before it reaches you. Detect once per session with `command -v snip || command -v rtk`, then prefix every command (`snip <cmd>`). Passthrough when no filter matches (always safe); drop the prefix if it fails or hides info you need.

## Prefer agent-aware tools (gitignore-aware, less noise)

| Use | Not |
|---|---|
| `rg` | `grep -r` |
| `fd` | `find . -name` |
| `jq` / `gron` / `yq` / `dasel` | `python -c "import json/yaml…"` |
| Read / Edit / Write tools | `cat`, `head`, `tail`, `sed -i`, `echo > file` |

`bat`/`delta` only when piping to the user's terminal (they add ANSI). Reference `file:line` rather than pasting code that goes stale.

## Discover & run

```bash
mise ls            # installed tools — the source of truth (baseline + opt-in)
cervel ls/status   # AI agents on PATH · host + stack + sessions
cervel run <cmd>   # wrap a long job, ntfy push on exit
cervel help        # tmux / aoe / cervel cheatsheet
aoe                # parallel agents in tmux + web dashboard (`aoe url`)
topgrade           # update mise + user-space (apt/system = root's job)
<tool> --help      # confirm flags before non-trivial use
```

Baseline always present: C/C++ (gcc/g++/make), node/pnpm/python/uv (+ tsc/tsx/ruff), rg/fd/fzf/jq/yq/dasel/gron/ast-grep/bat, gh/delta, LSPs (bash/yaml/taplo/marksman/typescript/json/basedpyright). Everything else is opt-in.

## Add a tool

`mise use -g <spec>`, in this order: `aqua:<o>/<r>` (~3500 precompiled) → `github:<o>/<r>` (`[bin=<name>]` if needed) → `npm:<pkg>` → `pipx:<pkg>` → `apt` (OS-level only: daemons, C/C++ toolchain). Avoid `go:` / `cargo:` — they compile from source.

## This file is shared across agents

Symlinked at install to each installed agent's prompt path — edit `~/AGENTS.md`, all pick it up:

| Agent | Path |
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
| Crush · Qwen · DeepSeek · Droid · Hermes · Kiro | check docs, symlink manually |

Symlinks cover only the prompt file. For MCP / skills / slash-command sync across agents, the `ai-tools` **`agents`** package ([amtiYo/agents](https://github.com/amtiYo/agents)) is default-on. Format ref: [AGENTS.md](https://agents.md/).

## Verify, don't guess

CLI flags, package names and APIs drift between versions. Confirm with `<tool> --help`, `man`, or the official docs (WebFetch the homepage) before anything non-trivial — "I think this flag exists" is never enough.
