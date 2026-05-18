#!/usr/bin/env bash
# install/iac-stack.sh: Infrastructure as Code. Opt-in. All precompiled via aqua.
# OpenTofu = open-source fork of Terraform (post-license change).

install_iac_stack_all() {
    mise_aqua "opentofu/opentofu"
    mise_aqua "pulumi/pulumi"
}
