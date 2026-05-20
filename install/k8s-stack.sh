#!/usr/bin/env bash
# install/k8s-stack.sh: kubernetes CLIs. CERVELAI_K8S_STACK=<csv|all>.

install_k8s_stack_kubectl() { mise_use "kubectl"; }
install_k8s_stack_k9s() { mise_use "k9s"; }
install_k8s_stack_helm() {
    mise_use "helm" || return
    # Seed a repo so topgrade's `helm repo update` has something to refresh (else it errors).
    soft _user_bash "helm repo list 2>/dev/null | grep -q '^helm-stable' \
        || helm repo add helm-stable https://charts.helm.sh/stable >/dev/null"
}
install_k8s_stack_kubectx() { mise_use "kubectx"; }
install_k8s_stack_kubens() { mise_use "kubens"; }
install_k8s_stack_kustomize() { mise_use "kustomize"; }
install_k8s_stack_kind() { mise_use "kind"; }
install_k8s_stack_stern() { mise_use "stern"; }

install_k8s_stack_all() {
    _dispatch_csv k8s-stack CERVELAI_K8S_STACK \
        "kubectl,k9s,helm,kubectx,kubens,kustomize,kind,stern"
}
