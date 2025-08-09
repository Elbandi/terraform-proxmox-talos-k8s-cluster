locals {
  platform = "nocloud"
  arch     = "amd64"
  version  = var.cluster.talos_version

  image_id        = "${var.proxmox.iso_datastore_id}:iso/${var.cluster.name}-talos-${var.schematic_id}-${local.version}-${local.platform}-${local.arch}.img"
  image_nvidia_id = "${var.proxmox.iso_datastore_id}:iso/${var.cluster.name}-talos-${var.schematic_nvidia_id}-${local.version}-${local.platform}-${local.arch}.img"

}
