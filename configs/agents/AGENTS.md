# cervelAI — Agent Quickstart

You're in a Debian 13 LXC pre-loaded for AI coding agents. Tools are wired;
rules are up to you.

## Available in this VM

- **AI agent CLIs**: `ai claude|codex|opencode|pi|aider|crush|gemini|goose|cn …`
- **Runtimes via `mise`** — node/python/pnpm/uv always; more on demand (`mise ls`).
  Per-project pinning in `.mise.toml`.
- **Modern CLI**: rg, fd, sd, fzf, jq, yq, dasel, gron, ast-grep, bat, eza, glow, zoxide, tldr, hyperfine.
- **Git**: gh / glab / tea, git-delta, lazygit, gitleaks.
- **Token saver** (`snip` or `rtk`): PreToolUse hook auto-wired into the agents
  that support it (claude-code, codex, gemini, pi for snip). Filters command
  output before it reaches the LLM context — typically -70 to -90 %.
- **Notifications**: `ai-run <cmd>` runs the command then sends an `ntfy` push
  on exit. Topic in `~/.config/cervelAI/env` — subscribe on your phone.
- **API keys**: `~/.config/cervelAI/env` (mode 600), sourced by every shell + `ai-run`.

## Set your own rules per editor

cervelAI ships **no** prompt or rules — every dev's style and skills differ.
Drop yours at the path your AI editor reads:

| Editor                | Global rules                                       |
|-----------------------|----------------------------------------------------|
| Claude Code           | `~/.claude/CLAUDE.md` + `~/.claude/settings.json`  |
| Codex                 | `~/.codex/instructions.md`                         |
| OpenCode              | `~/.config/opencode/AGENTS.md`                     |
| Pi.dev                | `~/.pi/agent/AGENTS.md`                            |
| Aider                 | `~/.aider.conf.yml`                                |
| Gemini CLI            | `~/.gemini/GEMINI.md` + `~/.gemini/settings.json`  |
| Crush / Goose / Continue | see their respective docs                       |

For **project-local** rules, drop `AGENTS.md` (or `CLAUDE.md` for Claude Code)
at the repo root — most agents pick it up automatically.

To sync rules across machines: clone your own dotfiles repo, or use
`chezmoi` / `stow` / `yadm`.
