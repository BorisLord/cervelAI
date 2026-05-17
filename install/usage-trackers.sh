#!/usr/bin/env bash
# install/usage-trackers.sh: token/cost trackers for AI agents. All via mise:npm.
# tokscale (cross-agent), ccusage + ccstatusline (Claude Code / Codex).

install_usage_trackers_all() {
    mise_npm "tokscale"
    mise_npm "ccusage"
    mise_npm "ccstatusline"
}
