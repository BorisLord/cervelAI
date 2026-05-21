#!/usr/bin/env bash

install_cli_extras_sd() { mise_use "sd"; }
install_cli_extras_eza() { mise_use "eza"; }
install_cli_extras_glow() { mise_use "glow"; }
install_cli_extras_zoxide() { mise_use "zoxide"; }
install_cli_extras_tldr() { mise_use "aqua:tealdeer-rs/tealdeer" latest tldr; }
install_cli_extras_hyperfine() { mise_use "hyperfine"; }
install_cli_extras_shfmt() { mise_use "shfmt"; }
install_cli_extras_shellcheck() { mise_use "shellcheck"; }
install_cli_extras_xh() { mise_use "xh"; }
install_cli_extras_typos() { mise_use "typos"; }
install_cli_extras_yazi() { mise_use "yazi"; }
install_cli_extras_act() { mise_use "act"; }
install_cli_extras_just() { mise_use "just"; }
install_cli_extras_watchexec() { mise_use "watchexec"; }
install_cli_extras_hurl() { mise_use "hurl"; }
install_cli_extras_fq() { mise_use "aqua:wader/fq" latest fq; }
install_cli_extras_btop() { mise_use "btop"; }
install_cli_extras_atuin() { mise_use "atuin"; }

install_cli_extras_all() {
    _dispatch_csv cli-extras CERVELAI_CLI_EXTRAS \
        "sd,eza,glow,zoxide,tldr,hyperfine,shfmt,shellcheck,xh,typos,yazi,act,just,watchexec,hurl,fq,btop,atuin"
}
