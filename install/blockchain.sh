#!/usr/bin/env bash

install_blockchain_evm() {
    mise_use "solidity" latest solc
    mise_use "foundry" latest forge
    mise_use "npm:@nomicfoundation/solidity-language-server" latest solidity-language-server
    mise_npm "solhint"
    mise_npm "hardhat"
    mise_use "pipx:slither-analyzer" latest slither
}

install_blockchain_solana() {
    _user_bash 'command -v rustc' &>/dev/null || mise_use "rust"
    mise_use "github:anza-xyz/agave" latest solana
    mise_use "github:coral-xyz/anchor" latest anchor
}

install_blockchain_move() {
    # pin: repo also tags testnet-v*/devnet-v*, mise would pick the latest testnet without a pin.
    mise_use "sui" "mainnet-v1.71.1" sui
    # pin: repo also tags aptos-node-v*, mise would pick the node binary without a pin.
    mise_use "github:aptos-labs/aptos-core" "aptos-cli-v9.2.0" aptos
}

install_blockchain_cosmos() {
    _user_bash 'command -v go' &>/dev/null || mise_use "go"
    mise_use "github:ignite/cli" latest ignite
}

install_blockchain_near() {
    _user_bash 'command -v rustc' &>/dev/null || mise_use "rust"
    mise_use "github:near/near-cli-rs" latest near
}

install_blockchain_cairo() {
    mise_use "scarb" latest scarb
    mise_use "github:foundry-rs/starknet-foundry[bin=sncast]" latest sncast
}

install_blockchain_all() {
    _dispatch_csv blockchain CERVELAI_BLOCKCHAIN "evm,solana,move,cosmos,near,cairo"
}
