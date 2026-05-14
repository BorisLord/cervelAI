#!/usr/bin/env bash
# install/node-tools.sh — global Node tooling: pnpm, typescript (tsc), tsx.
# Most Node tools live per-project in devDependencies; this is the global minimum.
# All via mise (core registry for pnpm, npm backend for ts/tsx).

install_node_tools_pnpm()       { mise_use "pnpm" "latest"; }
install_node_tools_typescript() { mise_npm "typescript"; }
install_node_tools_tsx()        { mise_npm "tsx"; }

install_node_tools_all() {
    install_node_tools_pnpm
    install_node_tools_typescript
    install_node_tools_tsx
}
