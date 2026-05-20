#!/usr/bin/env bash
# install/cloud-stack.sh: cloud provider CLIs. CERVELAI_CLOUD_STACK=<csv|all>. All via mise.

install_cloud_stack_aws() { mise_use "aws-cli" latest aws; }
install_cloud_stack_flyctl() { mise_use "flyctl"; }
install_cloud_stack_cloudflared() { mise_use "cloudflared"; }
install_cloud_stack_supabase() { mise_use "supabase"; }
install_cloud_stack_doctl() { mise_use "doctl"; }
install_cloud_stack_hcloud() { mise_use "hcloud"; }
install_cloud_stack_scaleway() { mise_use "scaleway"; }
install_cloud_stack_gcloud() { mise_use "gcloud"; }
install_cloud_stack_azure() {
    if has_cmd az; then
        log_skip "azure-cli already installed"
        return 0
    fi
    log_info "installing azure-cli (Microsoft official Debian installer)"
    run bash -c 'curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash'
}

install_cloud_stack_all() {
    _dispatch_csv cloud-stack CERVELAI_CLOUD_STACK \
        "aws,flyctl,cloudflared,supabase,doctl,hcloud,scaleway,gcloud,azure"
}
