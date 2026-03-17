// Machine config spec: https://docs.siderolabs.com/talos/v1.6/reference/configuration/v1alpha1/config
// talos ccm: https://github.com/siderolabs/talos-cloud-controller-manager/blob/main/docs/install.md

locals {

  cluster_domain = "cluster.local"

  talos_primary_endpoint          = local.control_plane_public_ipv4_list[0]
  talos_primary_node_private_ipv4 = local.control_plane_private_ipv4_list[0]

  kube_api_url_internal = "https://${local.cluster_domain}:6443"
  kube_api_url_external = "https://${local.talos_primary_endpoint}:6443"

  kube_prism_host = "127.0.0.1"
  kube_prism_port = 7445

  inline_manifests = [
    local.hcloud_secret_manifest,
    local.hcloud_ccm_manifest,
    local.cilium_manifest,
    local.cert_manager_manifest,
    local.tailscale_manifest
  ]

  talos_manifests = [
    "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_crd_version}/standard-install.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${var.gateway_api_crd_version}/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml",
    "https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/${var.talos_ccm_version}/docs/deploy/cloud-controller-manager.yml"
  ]

  cluster_network = {
    dnsDomain      = local.cluster_domain
    podSubnets     = [var.pod_ipv4_cidr]
    serviceSubnets = [var.service_ipv4_cidr]
    cni            = { name = "none" }
  }

  proxy = {
    disabled = true
  }

  kubePrism = {
    enabled = true
    port    = local.kube_prism_port
  }

  extra_host_entries = [
    {
      ip      = local.control_plane_private_vip_ipv4
      aliases = [local.cluster_domain]
    }
  ]

  kubelet = {
    nodeIP = { validSubnets = [var.node_subnet_ipv4_cidr] }
    extraArgs = {
      cloud-provider             = "external"
      rotate-server-certificates = true
    }
  }

  certificate_san = sort(
    distinct(
      compact(
        concat(
          [local.control_plane_private_vip_ipv4],
          local.control_plane_private_ipv4_list,
          local.control_plane_public_ipv4_list,
          [local.cluster_domain],
          ["127.0.0.1", "::1", "localhost"],
        )
      )
    )
  )

  control_plane_config_patch = {
    for node in local.control_planes : node.name => {
      machine = {
        kubelet  = local.kubelet
        certSANs = local.certificate_san
        features = {
          kubernetesTalosAPIAccess = {
            enabled                     = true,
            allowedRoles                = ["os:reader"],
            allowedKubernetesNamespaces = ["kube-system"]
          }
          kubePrism = local.kubePrism
        }
        network = {
          hostname = node.name
          interfaces = [
            {
              interface = "eth0"
              dhcp      = true
            },
            {
              interface = "eth1"
              dhcp      = true
              vip = {
                ip = local.control_plane_private_vip_ipv4
                hcloud = {
                  apiToken = var.hcloud_token
                }
              }
            }
          ]
          extraHostEntries = local.extra_host_entries
        }
      }
      cluster = {
        proxy           = local.proxy
        network         = local.cluster_network
        inlineManifests = local.inline_manifests
        controllerManager = {
          extraArgs = {
            "cloud-provider" = "external"
            "bind-address"   = "0.0.0.0"
          }
        }
        externalCloudProvider = {
          enabled   = true
          manifests = local.talos_manifests
        }
        apiServer = {
          certSANs = local.certificate_san
        }
      }
    }
  }

  worker_config_patch = {
    for node in local.workers : node.name => {
      machine = {
        kubelet = merge(local.kubelet, length(node.taints) > 0 ? {
          extraConfig = {
            registerWithTaints = node.taints
          }
        } : {})
        certSANs   = local.certificate_san
        nodeLabels = node.labels
        features   = { kubePrism = local.kubePrism }
        network = {
          hostname         = node.name
          extraHostEntries = local.extra_host_entries
          interfaces = [
            {
              interface = "eth0"
              dhcp      = true
            }
          ]
        }
      }
      cluster = {
        network = local.cluster_network
        proxy   = local.proxy
      }
    }
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

# Generate talos machine configurations

data "talos_machine_configuration" "control_plane" {
  for_each = { for control_plane in local.control_planes : control_plane.name => control_plane }

  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.kube_api_url_internal
  config_patches     = [yamlencode(local.control_plane_config_patch[each.value.name])]
  docs               = false
  examples           = false
}

data "talos_machine_configuration" "worker" {
  for_each = { for worker in local.workers : worker.name => worker }

  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.kube_api_url_internal
  config_patches     = [yamlencode(local.worker_config_patch[each.value.name])]
  docs               = false
  examples           = false
}

# Apply machine configs
# https://docs.siderolabs.com/talos/v1.11/configure-your-talos-cluster/system-configuration/editing-machine-configuration

resource "talos_machine_configuration_apply" "control_plane" {
  for_each = { for control_plane in hcloud_server.control_plane : control_plane.name => control_plane }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane[each.key].machine_configuration
  endpoint                    = each.value.ipv4_address
  node                        = tolist(each.value.network)[0].ip
  apply_mode                  = var.talos_machine_configuration_apply_mode

  depends_on = [hcloud_server.control_plane]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for worker in hcloud_server.worker : worker.name => worker }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
  endpoint                    = each.value.ipv4_address
  node                        = tolist(each.value.network)[0].ip
  apply_mode                  = var.talos_machine_configuration_apply_mode

  depends_on = [
    hcloud_server.worker,
    talos_machine_configuration_apply.control_plane
  ]
}

# Bootstrap

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.talos_primary_endpoint
  node                 = local.talos_primary_node_private_ipv4

  depends_on = [
    talos_machine_configuration_apply.control_plane,
    talos_machine_configuration_apply.worker
  ]
}
