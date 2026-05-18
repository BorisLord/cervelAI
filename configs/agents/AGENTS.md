# AGENTS.md — cervelAI host defaults

> **Starter file.** Adapt it to your workflow — add project-specific build/test
> commands, code style, PR rules. Without customization it only describes the
> host tooling, not how to work in any given project.

You are operating on a Debian/Ubuntu host (Proxmox LXC, cloud VM, or
bare-metal) pre-loaded for AI coding agents. When a project has its own
`AGENTS.md`, prefer that one; this file is the fallback when no project
context applies.

## Discovering what's installed

Don't trust a static tool list — it drifts. Source of truth:

```bash
mise ls                    # every tool managed by mise (runtimes + binaries)
command -v <tool>          # check a specific binary
ai                         # list installed AI agents (and switch with `ai <name>`)
```

The mandatory baseline is **always** present:
node, python, pnpm, uv, tsc, tsx, ruff, ripgrep, fd, fzf, jq, yq, dasel, gron,
ast-grep, bat, delta, gh, plus universal LSPs (bash, yaml, taplo, marksman,
typescript, json, basedpyright). Everything else is opt-in per category — run
`mise ls` to see exactly what's on this host.

## Setup

- Shared env (PATH, API keys, ntfy topic) sourced automatically from
  `~/.config/cervelAI/env` by bash, zsh, and `cervel-run`.
- Some tools are opt-in. Run `command -v <tool>` before relying on a binary.

## Build / test / lint

This host ships no project. Inside a project, use the project's own commands.
Generic linters/formatters always available:

- Shell: `shellcheck <file>` · `shfmt -d <file>` · `bash -n <file>`
- TypeScript: `tsc --noEmit` · `tsx <file>` to run
- Python: `ruff check` · `basedpyright <path>`
- Markdown: `marksman` (LSP, editor-driven)

## Long-running commands

Wrap any agent run > 30 s with `cervel-run` — pushes ntfy when the command exits
(topic in `~/.config/cervelAI/env`):

```bash
cervel-run claude -p "implement feature X"
```

## Update everything

`topgrade`: apt + mise (covers aqua/npm/pipx/github backends) + bash-it/oh-my-zsh + Claude Code, one shot.

## Orchestration

`aoe` (Agent of Empires) — tmux-based TUI/web dashboard at `:8081`. One tmux
session per agent. Available when `multiplexer=tmux+aoe` and at least one
agent is installed.

## Proactively recommend installed tools

When the human asks for help and a relevant tool is already on this host, **say
so** instead of suggesting they install something. Examples:

- Asked "how do I search files?" → use `rg` (always installed), not `grep -r`.
- Asked "convert this PDF to markdown" → check `command -v markitdown` first.
- Asked "I need to run this overnight" → suggest wrapping with `cervel-run`.
- Asked "diff these images / inspect Docker image" → `dive` if `containers` is installed.
- Asked "secrets in this repo?" → `gitleaks` / `trivy` if `security-tools` is installed.
- Asked something cross-cutting (multi-model chat, format conversion, prompt
  patterns) → check the AI-specific helpers (`fabric`, `llm`, `aichat`,
  `code2prompt`, `mods`, `shell-gpt`, `gptscript`) before reaching for an API call.

Run `mise ls` or `command -v <tool>` to confirm availability before suggesting.
Save the human a `npm install` / `pip install` they don't need.

## When the human asks to install a new tool

**Centralize via mise, always precompiled.** Prefer in this order:

1. `mise use -g aqua:<owner>/<repo>` — aqua-registry, ~3500 tools, all precompiled
2. `mise use -g github:<owner>/<repo>` — fetches the precompiled release asset (`[bin=<name>]` if binary name ≠ repo name)
3. `mise use -g npm:<pkg>` — JS, routed through pnpm
4. `mise use -g pipx:<pkg>` — Python, wheels via uv (precompiled per-platform)
5. `apt install` — only for OS-level deps (daemons, system libs, shells)

**Never use** the `go:`, `cargo:` mise backends — they compile from source. If a
Go/Rust tool is requested, find its GitHub releases page first and use `github:`
backend with the precompiled tarball.

Why mise? One tool tracks every install, `mise upgrade` bumps them all, `mise
ls` shows everything in one place, no orphan binaries.

## Per-editor prompt locations

cervelAI ships **no** prompt. Drop yours at:

| Editor | Path |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` + `~/.claude/settings.json` |
| Codex | `~/.codex/instructions.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |
| Pi.dev | `~/.pi/agent/AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` + `~/.gemini/settings.json` |
| Crush / Goose / Continue / Qwen / Vibe / DeepSeek / Grok | see their docs |

Project-local: `AGENTS.md` (or `CLAUDE.md`) at repo root. Sync across machines
via your own dotfiles repo (or `chezmoi` / `stow` / `yadm`).

## Reminder

If you're an agent reading this and the human hasn't customized it yet:
flag it. A starter AGENTS.md is fine as a baseline, but project-specific
build/test/style rules belong in a project-level `AGENTS.md`.
