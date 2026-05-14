#!/usr/bin/env bash
# install/usage-trackers.sh — token/cost trackers for AI agents. All via mise:npm.
#   tokscale     : cross-agent (22+ agents) — the broadest
#   ccusage      : canonical for Claude Code + Codex (reads their session JSONL)
#   ccstatusline : real-time Claude Code statusline (token/cost/burn-rate)
# Pi, Aider, Gemini, Amp have built-in trackers; tokscale aggregates history.

install_usage_trackers_tokscale()    { mise_npm "tokscale"; }
install_usage_trackers_ccusage()     { mise_npm "ccusage"; }
install_usage_trackers_ccstatusline(){ mise_npm "ccstatusline"; }

install_usage_trackers_all() {
    install_usage_trackers_tokscale
    install_usage_trackers_ccusage
    install_usage_trackers_ccstatusline
}
