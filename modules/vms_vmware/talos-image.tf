locals {
  platform = "vmware"
  arch     = "amd64"
  version  = var.cluster.talos_version

  image_id        = "${var.schematic_id}_${local.version}"
  image_nvidia_id = "${var.schematic_nvidia_id}_${local.version}"
}

data "vsphere_content_library" "content_library" {
  name = var.vmware.content_library
}

data "vsphere_content_library_item" "this" {
  for_each   = toset(distinct([for k, v in var.vms : "${v.gpu != null ? local.image_nvidia_id : local.image_id}"]))
  name       = "${var.cluster.name}-talos-${substr(split("_", each.key)[0], 0, 10)}-${split("_", each.key)[1]}-${local.platform}-${local.arch}"
  type       = "ovf"
  library_id = data.vsphere_content_library.content_library.id
}
