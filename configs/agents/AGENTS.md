# cervelAI — Agent Quickstart

Debian 13 LXC pre-loaded for AI coding agents. Some tools are opt-in — run
`command -v <tool>` to confirm.

## Tools

| Category | Tools |
|---|---|
| AI agent CLIs | `claude`, `codex`, `opencode`, `pi`, `aider`, `crush`, `gemini`, `goose`, `cn` (Continue). `ai <name> …` to switch |
| Runtimes (always) | node, python, pnpm, uv. Node ships `tsc` + `tsx`; Python ships `ruff` |
| Runtimes (opt-in) | go, rust, bun, deno, zig, java, kotlin, dotnet, php, ruby, dart, scala, elixir, erlang, lua |
| Shell | bash + bash-it · zsh + oh-my-zsh · fish. tmux / zellij. `ai`, `t`, `br`/`zr` aliases |
| Search / text | rg, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, typos, bat, eza, glow, zoxide, tldr, hyperfine |
| Editors | vim, neovim (default); emacs, helix, micro (opt-in) |
| Git | gh, glab, tea, git-delta, lazygit, gitleaks |
| DB (opt-in) | sqlite3, psql, redis-cli, usql |
| HTTP (opt-in) | xh |
| Data (opt-in) | duckdb, miller (`mlr`) |
| Containers (opt-in) | docker, podman, distrobox, lazydocker |
| Web IDE (opt-in) | code-server (`sudo systemctl start code-server@agent`) |
| Token saver | snip or rtk — PreToolUse hook auto-wired into supported agents (-70 to -90 % tokens) |
| Usage trackers (opt-in) | tokscale, ccusage, ccstatusline |

## Notifications + keys

- `ai-run <cmd>` → runs, then pushes via `ntfy` on exit. Topic in `~/.config/cervelAI/env`.
- API keys live in `~/.config/cervelAI/env` (mode 600), sourced by every shell + `ai-run`.

## mise

`mise ls` (installed) · `mise use <lang>@<version>` (per-project pin) · `mise upgrade`.

## Set your own rules per editor

cervelAI ships **no** prompt — drop yours at:

| Editor | Path |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` + `~/.claude/settings.json` |
| Codex | `~/.codex/instructions.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |
| Pi.dev | `~/.pi/agent/AGENTS.md` |
| Aider | `~/.aider.conf.yml` |
| Gemini CLI | `~/.gemini/GEMINI.md` + `~/.gemini/settings.json` |
| Crush / Goose / Continue | see their docs |

Project-local : `AGENTS.md` (or `CLAUDE.md`) at repo root. Sync across machines
via your own dotfiles repo (or `chezmoi` / `stow` / `yadm`).
