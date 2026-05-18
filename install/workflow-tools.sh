#!/usr/bin/env bash
# install/workflow-tools.sh: dev-loop helpers. One-shot category, all installed when selected.

install_workflow_tools_all() {
    mise_aqua "nektos/act"
    mise_aqua "casey/just"
    mise_aqua "watchexec/watchexec"
}
