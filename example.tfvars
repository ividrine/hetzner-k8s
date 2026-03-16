# Secrets 

hcloud_token      = "example-hcloud-token"
tailscale_api_key = "example-tailscale-authkey"
tailscale_tailnet = "example-tailnet-id"

# Network

network_ipv4_cidr     = ""
node_subnet_zone      = ""
node_subnet_ipv4_cidr = ""
pod_ipv4_cidr         = ""
service_ipv4_cidr     = ""

# VMs

control_plane = { location = "fsn1", server_type = "cx23", count = 1 }
worker_pools = {
  general = { location = "fsn1", server_type = "cx23", count = 1 }
  specificTainedServers = {
    location    = "fsn1"
    server_type = "cx23"
    count       = 1
    labels      = { "agones.dev/agones-system" = true }
    taints      = ["agones.dev/agones-system=true:NoExecute"]
  }
}