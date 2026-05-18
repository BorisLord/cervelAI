#!/usr/bin/env bash
# install/cli-extras.sh: human-facing modern CLI tools. CERVELAI_CLI_EXTRAS=<csv|all>.
# Split from search.sh — search-core stays mandatory (AI uses it), these are nice-to-have.

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
    local csv="${CERVELAI_CLI_EXTRAS:-}"
    [[ "$csv" == "all" ]] && csv="sd,eza,glow,zoxide,tldr,hyperfine,shfmt,shellcheck,xh,typos,yazi"
    IFS=',' read -r -a list <<<"$csv"
    for c in "${list[@]}"; do
        c="${c// /}"
        case "$c" in
            sd | eza | glow | zoxide | tldr | hyperfine | shfmt | shellcheck | xh | typos | yazi)
                "install_cli_extras_$c"
                ;;
            none | "") log_skip "no cli-extras tool requested" ;;
            *) log_warn "unknown cli-extras in CERVELAI_CLI_EXTRAS: $c (valid: sd,eza,glow,zoxide,tldr,hyperfine,shfmt,shellcheck,xh,typos,yazi,none)" ;;
        esac
    done
}
