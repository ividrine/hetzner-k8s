# hetzner-k8s

Platform for managing kubernetes using Hetzner Cloud VMs.

## Description

This project bootstraps kubernetes in Hetzner Cloud using Talos Linux. It creates Tailscale tags and ACLs needed for secure access to kube API server from devices on the tailnet. It also installs a number of different components on the cluster:

- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Cilium](https://cilium.io/)
- [cert-manager](https://cert-manager.io/)
- [Tailscale Operator](https://tailscale.com/kb/1236/kubernetes-operator)
- [HCloud CCM (Cloud Controller Manager)](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
- [Talos CCM (Cloud Controller Manager)](https://github.com/siderolabs/talos-cloud-controller-manager)

## Prerequisites

### Cloud Accounts

- [Hetzner](https://www.hetzner.com/cloud)
- [Tailscale](https://tailscale.com/)

### Dependencies

- [Packer](https://developer.hashicorp.com/packer)
- [Terraform](https://developer.hashicorp.com/terraform)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Tailscale CLI](https://tailscale.com/kb/1080/cli)
- Optionally you can install [Flux CLI](https://fluxcd.io/flux/cmd/) to add gitops to the cluster after creation.

## Getting Started

1. Create a [Tailscale](https://tailscale.com/) account and add your device to the tailnet.
2. Clone the repository.
3. Set HCLOUD_TOKEN to your Hetzner cloud api token - ex. for bash: `export HCLOUD_TOKEN=<tokenvalue>`
4. Run `packer/create.sh` to generate a Talos Linux machine image snapshot and upload to Hetzner cloud.
5. Create a .tfvars file by running `cp example.tfvars .tfvars` and configure values.
6. Run `terraform apply -var-file=.tfvars`
7. Once cluster is healthy and if your device is connected to the tailnet, you can run `tailscale configure kubeconfig tailscale-operator` to configure your local kubeconfig for connecting to cluster over tailscale DNS.

## Helpful Commands

### Apply/Destroy

```
terraform apply -var-file=.tfvars
terraform destroy -var-file=.tfvars
```

### Output configs

```
terraform output -raw kubeconfig > ~/.kube/config
terraform output -raw talosconfig > ~/.talos/config
```

### Configure kubeconfig with tailscale auth

`tailscale configure kubeconfig <device_name>`

### Machine logs

```
talosctl -n <nodeIp> dmesg
talosctl -n <nodeIp> dmesg | grep error
```

### Bootstrap flux

```
export GITHUB_TOKEN=<your_personal_access_token>
export GITHUB_USER=<your_github_username>

flux bootstrap github \
 --token-auth=false \
 --owner=$GITHUB_USER \
 --repository=ops \
 --branch=main \
 --path=./clusters/production \
 --read-write-key=true \
 --components-extra='image-reflector-controller,image-automation-controller' \
 --personal
```

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, helpful insight:

- [terraform-hcloud-kubernetes](https://github.com/hcloud-k8s/terraform-hcloud-kubernetes)
- [terraform-hcloud-talos](https://github.com/hcloud-talos/terraform-hcloud-talos)
