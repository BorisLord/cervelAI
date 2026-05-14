#!/usr/bin/env bash
# install/python-tools.sh — global standalone Python tools: uv + ruff (Astral, Rust).
# uv replaces pip/poetry/virtualenv/pipx/pyenv; ruff replaces flake8/isort/black.
# pytest, mypy, … stay per-project (`uv tool install` or `uv run`).

install_python_tools_uv()   { mise_aqua "astral-sh/uv"; }
install_python_tools_ruff() { mise_aqua "astral-sh/ruff"; }

install_python_tools_all() {
    install_python_tools_uv
    install_python_tools_ruff
}
