#!/usr/bin/env bash
# install/iac-stack.sh: Infrastructure as Code. Opt-in. OpenTofu = OSS fork of Terraform.

install_iac_stack_all() {
    mise_aqua "opentofu/opentofu"
    mise_aqua "pulumi/pulumi"
}
