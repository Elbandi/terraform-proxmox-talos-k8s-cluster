locals {
  platform = "vmware"
  arch     = "amd64"
  version  = var.cluster.talos_version

  image_ids = { for k, v in var.vms : k => "${v.schematic_id}_${local.version}" }
}

data "vsphere_content_library" "content_library" {
  name = var.vmware.content_library
}

data "vsphere_content_library_item" "this" {
  for_each   = toset(distinct([for k, v in var.vms : local.image_nvidia_ids[k]]))
  name       = "${var.cluster.name}-talos-${substr(split("_", each.key)[0], 0, 10)}-${split("_", each.key)[1]}-${local.platform}-${local.arch}"
  type       = "ovf"
  library_id = data.vsphere_content_library.content_library.id
}
