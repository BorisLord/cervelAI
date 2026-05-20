#!/usr/bin/env bash

install_search_all() {
    mise_use "ripgrep" latest rg
    mise_use "fd"
    mise_use "fzf"
    mise_use "jq"
    mise_use "yq"
    mise_use "dasel"
    mise_use "gron"
    mise_use "ast-grep"
    mise_use "bat"
}
