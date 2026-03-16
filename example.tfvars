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
control_plane = { location = "", server_type = "", count = 1 }
worker_pools = {
  # Configure a pool of workers with specific options
  general = {
    location       = ""
    server_type    = ""
    count          = 1
    labels         = {}
    taints         = []
    firewall_rules = []
  }
}