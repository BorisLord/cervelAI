#!/usr/bin/env bash
# install/k8s-stack.sh: kubernetes CLIs. CERVELAI_K8S_STACK=<csv|all>.

install_k8s_stack_kubectl() { mise_aqua "kubernetes/kubernetes/kubectl"; }
install_k8s_stack_k9s() { mise_aqua "derailed/k9s"; }
install_k8s_stack_helm() { mise_aqua "helm/helm"; }
install_k8s_stack_kubectx() { mise_aqua "ahmetb/kubectx"; }
install_k8s_stack_kubens() { mise_aqua "ahmetb/kubectx/kubens"; }
install_k8s_stack_kustomize() { mise_aqua "kubernetes-sigs/kustomize"; }
install_k8s_stack_kind() { mise_aqua "kubernetes-sigs/kind"; }
install_k8s_stack_stern() { mise_aqua "stern/stern"; }

install_k8s_stack_all() {
    local csv="${CERVELAI_K8S_STACK:-}"
    [[ "$csv" == "all" ]] && csv="kubectl,k9s,helm,kubectx,kubens,kustomize,kind,stern"
    IFS=',' read -r -a list <<<"$csv"
    for k in "${list[@]}"; do
        k="${k// /}"
        case "$k" in
            kubectl | k9s | helm | kubectx | kubens | kustomize | kind | stern)
                "install_k8s_stack_$k"
                ;;
            none | "") log_skip "no k8s-stack tool requested" ;;
            *) log_warn "unknown k8s-stack in CERVELAI_K8S_STACK: $k (valid: kubectl,k9s,helm,kubectx,kubens,kustomize,kind,stern,none)" ;;
        esac
    done
}
