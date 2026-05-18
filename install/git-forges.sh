#!/usr/bin/env bash
# install/git-forges.sh: thin wrapper — implementation lives in install/git-tools.sh
# (which also exposes install_git_tools_core, the mandatory portion called by setup.sh).
# shellcheck disable=SC1091
source "${INSTALL_DIR}/git-tools.sh"
install_git_forges_all() { install_git_tools_all; }
