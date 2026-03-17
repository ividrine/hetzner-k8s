data "http" "source_ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  source_ip = "${chomp(data.http.source_ip.response_body)}/32"
}


# Control planes needs both Kubernetes and Talos API ports exposed

resource "hcloud_firewall" "control_plane" {
  name = "${var.cluster_name}-control_plane"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [local.source_ip]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "50000"
    source_ips = [local.source_ip]
  }
}

# Workers will need Talos API port exposed in order to apply machine configurations during bootstrap

resource "hcloud_firewall" "worker" {
  name = "${var.cluster_name}-worker"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "50000"
    source_ips = [local.source_ip]
  }
}

# Create additional firewall rules based on worker pool configuration

resource "hcloud_firewall" "worker_pools" {
  for_each = { for name, pool in var.worker_pools : name => pool if length(pool.firewall_rules) > 0 }
  name     = "${var.cluster_name}-${each.key}"
  dynamic "rule" {
    for_each = each.value.firewall_rules
    content {
      direction  = rule.value.direction
      protocol   = rule.value.protocol
      port       = rule.value.port
      source_ips = rule.value.source_ips
    }
  }
}