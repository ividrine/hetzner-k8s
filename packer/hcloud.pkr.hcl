# https://docs.siderolabs.com/talos/v1.11/platform-specific-installations/cloud-platforms/hetzner

variable "talos_version" {
  type    = string
  default = "v1.11.5"
}

variable "server_arch" {
  type    = string
  default = "amd64"
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "server_location" {
  type    = string
  default = "fsn1"
}

variable "schematic_id" {
  type = string
  default = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
  description = "schematic id for hetzner cloud talos image with no system extensions"
}

packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

locals {
  image = "https://factory.talos.dev/image/${var.schematic_id}/${var.talos_version}/hcloud-${var.server_arch}.raw.xz"
}

source "hcloud" "talos" {
  rescue = "linux64"
  image = "debian-11"
  location = var.server_location
  server_type = var.server_type
  ssh_username = "root"
  snapshot_name = "talos-${var.server_arch}-${var.talos_version}"
  snapshot_labels = {
    type = "infra",
    os = "talos",
    version = var.talos_version,
    arch = var.server_arch,
  }
}

build {
  sources = ["source.hcloud.talos"]
  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}