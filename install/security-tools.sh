#!/usr/bin/env bash

install_security_tools_sops() { mise_use "sops"; }
install_security_tools_age() { mise_use "age"; }
install_security_tools_syft() { mise_use "syft"; }
install_security_tools_cosign() { mise_use "cosign"; }
install_security_tools_gitleaks() { mise_use "gitleaks"; }
install_security_tools_trivy() { mise_use "trivy"; }
install_security_tools_kingfisher() { mise_use "github:mongodb/kingfisher[bin=kingfisher]" latest kingfisher; }
install_security_tools_dotenvx() { mise_use "dotenvx"; }
install_security_tools_varlock() { mise_use "npm:varlock" latest varlock; }
install_security_tools_infisical() { mise_use "infisical" latest infisical; }

install_security_tools_all() {
    _dispatch_csv security-tools CERVELAI_SECURITY_TOOLS \
        "sops,age,gitleaks,trivy,syft,cosign,kingfisher,varlock,dotenvx,infisical"
}
