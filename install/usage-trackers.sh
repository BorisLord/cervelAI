#!/usr/bin/env bash
# install/usage-trackers.sh — token/cost trackers for AI agents, all via mise:npm.
# tokscale (cross-agent), ccusage + ccstatusline (Claude Code / Codex).

install_usage_trackers_tokscale()    { mise_npm "tokscale"; }
install_usage_trackers_ccusage()     { mise_npm "ccusage"; }
install_usage_trackers_ccstatusline(){ mise_npm "ccstatusline"; }

install_usage_trackers_all() {
    install_usage_trackers_tokscale
    install_usage_trackers_ccusage
    install_usage_trackers_ccstatusline
}
