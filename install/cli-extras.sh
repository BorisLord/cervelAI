#!/usr/bin/env bash
# install/cli-extras.sh: human-facing CLI extras. CERVELAI_CLI_EXTRAS=<csv|all>. Search-core stays in install/search.sh (mandatory, AI uses it).

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

install_cli_extras_all() {
    _dispatch_csv cli-extras CERVELAI_CLI_EXTRAS \
        "sd,eza,glow,zoxide,tldr,hyperfine,shfmt,shellcheck,xh,typos,yazi"
}
