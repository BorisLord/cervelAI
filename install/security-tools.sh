#!/usr/bin/env bash
# install/security-tools.sh: secrets + signing + SBOM + AI-aware tooling.
# CERVELAI_SECURITY_TOOLS=<csv|all>.

install_security_tools_sops() { mise_aqua "getsops/sops"; }
install_security_tools_age() { mise_aqua "FiloSottile/age"; }
install_security_tools_syft() { mise_aqua "anchore/syft"; }
install_security_tools_cosign() { mise_aqua "sigstore/cosign"; }
install_security_tools_gitleaks() { mise_aqua "gitleaks/gitleaks"; }
install_security_tools_trivy() { mise_aqua "aquasecurity/trivy"; }
# AI-aware scanner with 35+ provider rules (Anthropic/OpenAI/Gemini/Mistral/...).
install_security_tools_kingfisher() { mise_use "github:mongodb/kingfisher[bin=kingfisher]" latest kingfisher; }
install_security_tools_teller() { mise_aqua "tellerops/teller"; }
install_security_tools_dotenvx() { mise_aqua "dotenvx/dotenvx"; }
install_security_tools_varlock() { mise_use "npm:varlock" latest varlock; }
install_security_tools_infisical() { mise_use "github:Infisical/cli[bin=infisical]" latest infisical; }

install_security_tools_all() {
    local csv="${CERVELAI_SECURITY_TOOLS:-}"
    [[ "$csv" == "all" ]] && csv="sops,age,gitleaks,trivy,syft,cosign,kingfisher,varlock,dotenvx,infisical,teller"
    IFS=',' read -r -a list <<<"$csv"
    for s in "${list[@]}"; do
        s="${s// /}"
        case "$s" in
            sops | age | syft | cosign | gitleaks | trivy | kingfisher | teller | dotenvx | varlock | infisical)
                "install_security_tools_$s"
                ;;
            none | "") log_skip "no security-tools requested" ;;
            *) log_warn "unknown security-tools in CERVELAI_SECURITY_TOOLS: $s (valid: sops,age,gitleaks,trivy,syft,cosign,kingfisher,varlock,dotenvx,infisical,teller,none)" ;;
        esac
    done
}
