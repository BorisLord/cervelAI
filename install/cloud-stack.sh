#!/usr/bin/env bash
# install/cloud-stack.sh: cloud provider CLIs. CERVELAI_CLOUD_STACK=<csv|all>. All via mise.

install_cloud_stack_aws() { mise_aqua "aws/aws-cli"; }
install_cloud_stack_flyctl() { mise_aqua "superfly/flyctl"; }
install_cloud_stack_cloudflared() { mise_aqua "cloudflare/cloudflared"; }
# github: backend used because aqua-registry's supabase asset pattern is stale (missing version).
install_cloud_stack_supabase() { mise_use "github:supabase/cli[bin=supabase]" latest supabase; }
install_cloud_stack_doctl() { mise_aqua "digitalocean/doctl"; }
install_cloud_stack_hcloud() { mise_aqua "hetznercloud/cli"; }
install_cloud_stack_scaleway() { mise_aqua "scaleway/scaleway-cli"; }
install_cloud_stack_gcloud() { mise_use "vfox:mise-plugins/vfox-gcloud" latest gcloud; }
# pipx blocked: azure-cli depends on prerelease azure-batch==15.0.0b1, uv rejects prereleases.
install_cloud_stack_azure() {
    if has_cmd az; then
        log_skip "azure-cli already installed"
        return 0
    fi
    log_info "installing azure-cli (Microsoft official Debian installer)"
    run bash -c 'curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash'
}

install_cloud_stack_all() {
    local csv="${CERVELAI_CLOUD_STACK:-}"
    [[ "$csv" == "all" ]] && csv="aws,flyctl,cloudflared,supabase,doctl,hcloud,scaleway,gcloud,azure"
    IFS=',' read -r -a list <<<"$csv"
    for c in "${list[@]}"; do
        c="${c// /}"
        case "$c" in
            aws | flyctl | cloudflared | supabase | doctl | hcloud | scaleway | gcloud | azure)
                "install_cloud_stack_$c"
                ;;
            none | "") log_skip "no cloud CLI requested" ;;
            *) log_warn "unknown cloud CLI in CERVELAI_CLOUD_STACK: $c (valid: aws,flyctl,cloudflared,supabase,doctl,hcloud,scaleway,gcloud,azure,none)" ;;
        esac
    done
}
