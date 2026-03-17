data "hcloud_image" "x86" {
  with_selector     = "os=talos"
  with_architecture = "x86"
  most_recent       = true
}

locals {

  control_planes = [
    for i in range(var.control_plane.count) : {
      name        = "${var.cluster_name}-control-plane-${i}"
      server_type = var.control_plane.server_type
      location    = var.control_plane.location
    }
  ]

  workers = flatten([
    for pool_name, pool in var.worker_pools : [
      for i in range(pool.count) : {
        name        = "${var.cluster_name}-${pool_name}-${i}"
        server_type = pool.server_type
        location    = pool.location
        pool_name   = pool_name
      }
    ]
  ])
}

resource "hcloud_server" "control_plane" {
  for_each     = { for control_plane in local.control_planes : control_plane.name => control_plane }
  name         = each.value.name
  image        = data.hcloud_image.x86.id
  server_type  = each.value.server_type
  location     = each.value.location
  firewall_ids = [hcloud_firewall.control_plane.id]

  network {
    network_id = hcloud_network.this.id
  }

  depends_on = [hcloud_network_subnet.node]

  lifecycle {
    ignore_changes = [
      user_data,
      image,
      network
    ]
  }
}

resource "hcloud_server" "worker" {
  for_each     = { for worker in local.workers : worker.name => worker }
  name         = each.value.name
  image        = data.hcloud_image.x86.id
  server_type  = each.value.server_type
  location     = each.value.location
  firewall_ids = concat(
    [hcloud_firewall.worker.id],
    contains(keys(hcloud_firewall.worker_pools), each.value.pool_name) ? [hcloud_firewall.worker_pools[each.value.pool_name].id] : []
  )

  network {
    network_id = hcloud_network.this.id
  }

  depends_on = [hcloud_network_subnet.node]

  lifecycle {
    ignore_changes = [
      user_data,
      image,
      network
    ]
  }
}