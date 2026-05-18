#!/usr/bin/env bash
# install/blockchain.sh: blockchain dev bundles. CERVELAI_BLOCKCHAIN=<csv|all>. All precompiled.

install_blockchain_evm() {
    mise_use "github:ethereum/solidity" latest solc
    mise_aqua "foundry-rs/foundry"
    mise_use "npm:@nomicfoundation/solidity-language-server" latest solidity-language-server
    mise_npm "solhint"
    mise_use "pipx:slither-analyzer" latest slither
}

# Rust required: Solana programs compile to BPF.
install_blockchain_solana() {
    _user_bash 'command -v rustc' &>/dev/null || mise_use "rust"
    mise_use "github:anza-xyz/agave" latest solana
    mise_use "github:coral-xyz/anchor" latest anchor
}

install_blockchain_move() {
    mise_use "github:MystenLabs/sui" latest sui
    mise_use "github:aptos-labs/aptos-core" latest aptos
}

# Go required: custom Cosmos modules are Go packages.
install_blockchain_cosmos() {
    _user_bash 'command -v go' &>/dev/null || mise_use "go"
    mise_use "github:cosmos/gaia" latest gaiad
    mise_use "github:ignite/cli" latest ignite
}

# Rust required: NEAR smart contracts compile to WASM via Rust.
install_blockchain_near() {
    _user_bash 'command -v rustc' &>/dev/null || mise_use "rust"
    mise_use "github:near/near-cli-rs" latest near
}

install_blockchain_cairo() {
    mise_use "github:software-mansion/scarb" latest scarb
    mise_use "github:xJonathanLEI/starkli" latest starkli
}

install_blockchain_all() {
    local csv="${CERVELAI_BLOCKCHAIN:-}"
    [[ "$csv" == "all" ]] && csv="evm,solana,move,cosmos,near,cairo"
    IFS=',' read -r -a list <<<"$csv"
    for b in "${list[@]}"; do
        b="${b// /}"
        case "$b" in
            evm | solana | move | cosmos | near | cairo)
                "install_blockchain_$b"
                ;;
            none | "") log_skip "no blockchain bundle requested" ;;
            *) log_warn "unknown bundle in CERVELAI_BLOCKCHAIN: $b (valid: evm,solana,move,cosmos,near,cairo,none)" ;;
        esac
    done
}
