locals {
  platform = "nocloud"
  arch     = "amd64"
  version  = var.cluster.talos_version

  image_ids        = { for k, v in var.vms : k => "${var.proxmox.iso_datastore_id}:import/${var.cluster.name}-talos-${v.schematic_id}-${local.version}-${local.platform}-${local.arch}.qcow2" }
  image_nvidia_ids = { for k, v in var.vms : k => "${var.proxmox.iso_datastore_id}:import/${var.cluster.name}-talos-${v.schematic_nvidia_id}-${local.version}-${local.platform}-${local.arch}.qcow2" }

}
