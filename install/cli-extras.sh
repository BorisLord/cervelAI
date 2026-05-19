#!/usr/bin/env bash
# install/cli-extras.sh: human-facing CLI extras. CERVELAI_CLI_EXTRAS=<csv|all>. Search-core stays in install/search.sh (mandatory, AI uses it).

install_cli_extras_sd() { mise_aqua "chmln/sd"; }
install_cli_extras_eza() { mise_aqua "eza-community/eza"; }
install_cli_extras_glow() { mise_aqua "charmbracelet/glow"; }
install_cli_extras_zoxide() { mise_aqua "ajeetdsouza/zoxide"; }
install_cli_extras_tldr() { mise_use "aqua:tealdeer-rs/tealdeer" latest tldr; }
install_cli_extras_hyperfine() { mise_aqua "sharkdp/hyperfine"; }
install_cli_extras_shfmt() { mise_aqua "mvdan/sh"; }
install_cli_extras_shellcheck() { mise_aqua "koalaman/shellcheck"; }
install_cli_extras_xh() { mise_aqua "ducaale/xh"; }
install_cli_extras_typos() { mise_aqua "crate-ci/typos"; }
install_cli_extras_yazi() { mise_aqua "sxyazi/yazi"; }

install_cli_extras_all() {
    _dispatch_csv cli-extras CERVELAI_CLI_EXTRAS \
        "sd,eza,glow,zoxide,tldr,hyperfine,shfmt,shellcheck,xh,typos,yazi"
}
