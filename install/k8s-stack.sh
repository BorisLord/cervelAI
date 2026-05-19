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
    _dispatch_csv k8s-stack CERVELAI_K8S_STACK \
        "kubectl,k9s,helm,kubectx,kubens,kustomize,kind,stern"
}
