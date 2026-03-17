# Cluster Info

variable "cluster_name" {
  type    = string
  description = "Name of the kubernetes cluster"
}

# Secrets

variable "hcloud_token" {
  type        = string
  sensitive   = true
  description = "Hetzner cloud API token"
}

variable "tailscale_api_key" {
  type        = string
  sensitive   = true
  description = "Used to create the necessary ACLs and OAuth client for tailscale operator"
}

variable "tailscale_tailnet" {
  type        = string
  sensitive   = true
  description = "The id of the Tailscale tailnet to use"
}

# Network

variable "network_ipv4_cidr" {
  type        = string
  description = "IPv4 CIDR for the main network"
}

variable "node_subnet_zone" {
  type        = string
  description = "Zone for the node subnet"
}

variable "node_subnet_ipv4_cidr" {
  type        = string
  description = "IPv4 CIDR for the node subnet"
}

variable "pod_ipv4_cidr" {
  type        = string
  description = "IPv4 CIDR for the pod network"
}

variable "service_ipv4_cidr" {
  type        = string
  description = "IPv4 CIDR for the service network"
}

# VMs

variable "control_plane" {
  type = object({
    location    = string
    server_type = string
    count       = number
  })
}

variable "worker_pools" {
  type = map(object({
    location    = string
    server_type = string
    count       = number
    labels      = optional(map(string), {})
    taints      = optional(list(string), [])
    firewall_rules = optional(list(object({
      direction  = string
      protocol   = string
      port       = string
      source_ips = list(string)
    })), [])
  }))
}

# Talos

variable "talos_machine_configuration_apply_mode" {
  type        = string
  default     = "auto"
  description = "Mode for applying Talos machine configurations via talos provider"
}

# Software Versions

variable "talos_version" {
  type    = string
  default = "v1.11.5"
}

variable "talos_ccm_version" {
  type    = string
  default = "v0.14.0"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.34.2"
}

variable "gateway_api_crd_version" {
  type    = string
  default = "v1.4.0"
}

variable "cilium_version" {
  type    = string
  default = "1.18.4"
}

variable "hcloud_ccm_version" {
  type    = string
  default = "1.28.0"
}

variable "tailscale_operator_version" {
  type    = string
  default = "1.90.9"
}

variable "cert_manager_version" {
  type    = string
  default = "1.19.1"
}