# Cloud Lab Infrastructure

Platform for running my personal applications / websites in kubernetes.

## Description

This project bootstraps kubernetes in Hetzner Cloud using Talos Linux. It creates Tailscale tags and ACLs needed for secure access to kube API server from devices on the tailnet. It also installs a number of different components on the cluster:

- [Gateway API](https://gateway-api.sigs.k8s.io/) CRDs (Custom Resource Definition)
- [Cilium](https://cilium.io/) - CNI (Container Network Interface) and Gateway API Controller
- [Tailscale Operator](https://tailscale.com/kb/1236/kubernetes-operator) - expose kube api server on the tailnet
- [HCloud CCM (Cloud Controller Manager)](https://github.com/hetznercloud/hcloud-cloud-controller-manager) - native routing with cilium
- [Talos CCM (Cloud Controller Manager)](https://github.com/siderolabs/talos-cloud-controller-manager) - automatic CSR approval

## Prerequisites

### Cloud Accounts

- [Hetzner](https://www.hetzner.com/cloud)
- [Tailscale](https://tailscale.com/)
- [HCP Terraform](https://app.terraform.io/public/signup/account?utm_source=learn&product_intent=terraform) (optional)

### Dependencies

- [Packer](https://developer.hashicorp.com/packer)
- [Terraform](https://developer.hashicorp.com/terraform)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Tailscale CLI](https://tailscale.com/kb/1080/cli)

## Getting Started

- Clone the repository
- Run `export HCLOUD_TOKEN=<tokenvalue>` to set env variable for packer.
- Run `packer/create.sh` to generate a Talos Linux machine image.
- Create a .tfvars file by running `cp example.tfvars .tfvars` and configure values.
- Run `terraform apply -var-file=.tfvars`
- Once cluster is healthy and if your device is connected to the tailnet, you can run `tailscale configure kubeconfig tailscale-operator` to configure your local kubeconfig for connecting to cluster over tailscale DNS.

## HCP Terraform

For storing/managing terraform state I am using [HCP Terraform](https://app.terraform.io/public/signup/account?utm_source=learn&product_intent=terraform) - which is free for personal use. In order to keep the network secure, I am running an [agent](https://developer.hashicorp.com/terraform/cloud-docs/agents) on a dedicated machine in my local network so that it is the only thing that can access the kube / talos api servers outside of my tailnet.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, helpful insight:

- [terraform-hcloud-kubernetes](https://github.com/hcloud-k8s/terraform-hcloud-kubernetes)
- [terraform-hcloud-talos](https://github.com/hcloud-talos/terraform-hcloud-talos)
