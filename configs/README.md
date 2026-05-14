# configs/ — generic dotfiles

Minimal configs deployed into the `agent` user's home at install time
(`setup.sh#install_configs()`). Deliberately **shell + tmux + mise** only.
**No AI agent config shipped** — bring your own (CLAUDE.md / GEMINI.md /
OpenCode AGENTS.md / Pi) after install.

## Structure

```
configs/
├── README.md                          ← this file
├── bash/.bashrc, .bash_profile         ← default shell: PATH, mise, bash-it, `ai`/`t` aliases
├── zsh/.zshrc, .zshenv                 ← optional shell: oh-my-zsh + mise
├── tmux/.tmux.conf                     ← minimal (reload prefix+r, mouse, 10k scrollback)
├── mise/config.toml                    ← global node lts / python latest
├── bin/ai-run                          ← wrapper: run an agent + ntfy notification on exit
└── snip/filters/                       ← add your own custom YAML filters (if snip is installed)
```

## Why no AI agent config here?

Every dev has their own preferences (language, style, hooks, skills, subagents,
MCP servers…). A generic `AGENTS.md` or example skills would just be noise to
prune. The install provides the agent **binaries** (`claude`, `codex`,
`opencode`, `pi`, `aider`, …); **the config is yours**.

### After install, configure your agents

| Agent | Path to create | Notes |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` + `~/.claude/settings.json` | [docs](https://docs.anthropic.com/claude/docs/claude-code) |
| Gemini CLI | `~/.gemini/GEMINI.md` + `~/.gemini/settings.json` | [docs](https://geminicli.com/docs/) |
| OpenCode | `~/.config/opencode/AGENTS.md` + `opencode.json` | [docs](https://opencode.ai/docs/) |
| Pi.dev | `~/.pi/agent/AGENTS.md` | auto-discovery (`pi --help`) |
| Aider | `~/.aider.conf.yml` or `.aiderconf` | [docs](https://aider.chat/docs/config.html) |

To sync your config across machines: clone your own dotfiles repo from GitHub,
or use `chezmoi` / `stow` / `yadm`.

## Deployment by setup.sh

`setup.sh#install_configs()` deploys via an explicit source→destination mapping
(`install -D`, copy). Each file lands in its real place: `zsh/.zshrc` →
`~/.zshrc`, `mise/config.toml` → `~/.config/mise/config.toml`, `bin/ai-run` →
`~/.local/bin/ai-run`, etc.

## Customization

Edit these files **in the repo**, then re-run `setup.sh`: `install -D`
overwrites the deployed version, so your changes propagate on every run. Don't
edit `/home/agent/.zshrc` directly — the next run would overwrite it.
