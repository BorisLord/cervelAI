# AGENTS.md — cervelAI host defaults

> **This file is a starter. Tell your human to adapt it to their workflow** —
> add project-specific build/test commands, code style, PR rules, etc. Without
> customization it only describes the LXC tooling, not how to work in any
> given project.

You are operating inside a Debian 13 LXC (Proxmox) pre-loaded for AI coding
agents. When a project has its own `AGENTS.md`, prefer that one; this file is
the fallback when no project context applies.

## Setup

- Per-shell env (PATH, API keys, ntfy topic): sourced automatically from
  `~/.config/cervelAI/env` by bash, zsh, and `ai-run`.
- Switch between installed agents from any shell: `ai <name> [args...]`
  (e.g. `ai claude -p "fix X"`).
- Some tools are opt-in. Run `command -v <tool>` before relying on a binary.

## Build / test / lint

This LXC ships no project. Inside a project, use the project's own commands.
Generic linters available system-wide:

- Shell: `shellcheck <file>` (lint) / `shfmt -d <file>` (format diff) / `bash -n <file>` (syntax)
- TypeScript: `tsc --noEmit` (also `tsx <file>` to run)
- Python: `ruff check` / `basedpyright <path>`
- Markdown: `marksman` (LSP, editor-driven)

## Long-running commands

Wrap any agent run that takes > 30 s with `ai-run`:

```bash
ai-run claude -p "implement feature X"
```

`ai-run` ntfy-pushes when the command exits (topic in `~/.config/cervelAI/env`).

## Update everything

`topgrade`: apt + mise + npm/pipx globals + bash-it/oh-my-zsh + Claude Code, one shot.

## Tooling available

| Category | Tools |
|---|---|
| AI agent CLIs | `claude`, `codex`, `opencode`, `pi`, `aider`, `crush`, `gemini`, `goose`, `cn` (Continue). `ai <name> ...` to switch |
| Runtimes (always) | node, python, pnpm, uv. Node ships `tsc` + `tsx`; Python ships `ruff` |
| Runtimes (opt-in) | go, rust, bun, deno, zig, java, kotlin, dotnet, php, ruby, dart, scala, elixir, erlang, lua |
| Shell | bash + bash-it / zsh + oh-my-zsh / fish. tmux / zellij. `ai`, `t`, `br`/`zr` aliases |
| Search / text | rg, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine, shfmt |
| Editors | vim, neovim (default); emacs, helix, micro (opt-in) |
| LSPs (always) | bash-ls, yaml-ls, taplo (TOML), marksman (md), typescript-ls (TS+JS), vscode-json-languageserver, basedpyright |
| LSPs (runtime-gated) | gopls (go), rust-analyzer (rust), zls (zig), metals (scala), lua-ls (lua), intelephense (php), kotlin-ls, csharp-ls (dotnet), next-ls (elixir), erlang_ls. Built-in: `dart language-server`, `deno lsp`. Java/Ruby: install via editor plugin or `gem install`. |
| LSPs (containers-gated) | docker-langserver, docker-compose-langserver (only if `containers` opt-in is selected) |
| Git | gh, glab, tea, git-delta, lazygit, gitleaks |
| DB (opt-in) | sqlite3, psql, redis-cli, usql |
| HTTP (opt-in) | xh |
| Data (opt-in) | duckdb, miller (`mlr`) |
| Memory (opt-in) | memsearch, qmd, engram (lite) / claude-mem, `memory` (mcp-memory-service), agentmemory (heavy: daemon bootstrap required) |
| Containers (opt-in) | docker, podman, lazydocker |
| Web IDE (opt-in) | code-server (`sudo systemctl start code-server@agent`) |
| Token saver | snip OR rtk (mutually exclusive): PreToolUse hook auto-wired into supported agents (70-90% fewer tokens) |
| Usage trackers (opt-in) | tokscale, ccusage, ccstatusline |
| Orchestrator | `aoe` (Agent of Empires): tmux-based TUI/web dashboard at `:8081`. One tmux session per agent. |

## mise

`mise ls` (installed) / `mise use <lang>@<version>` (per-project pin) / `mise upgrade`.

## Per-editor prompt locations

cervelAI ships **no** prompt. Drop yours at:

| Editor | Path |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` + `~/.claude/settings.json` |
| Codex | `~/.codex/instructions.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |
| Pi.dev | `~/.pi/agent/AGENTS.md` |
| Aider | `~/.aider.conf.yml` |
| Gemini CLI | `~/.gemini/GEMINI.md` + `~/.gemini/settings.json` |
| Crush / Goose / Continue | see their docs |

Project-local: `AGENTS.md` (or `CLAUDE.md`) at repo root. Sync across machines
via your own dotfiles repo (or `chezmoi` / `stow` / `yadm`).

## Reminder

If you're an agent reading this and the human hasn't customized it yet:
flag it. A starter AGENTS.md is fine as a baseline, but project-specific
build/test/style rules belong in a project-level `AGENTS.md`.
