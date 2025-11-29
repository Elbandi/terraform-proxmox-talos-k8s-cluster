locals {
  platform = "vmware"
  arch     = "amd64"
  version  = var.cluster.talos_version

  image_ids = { for k, v in var.vms : k => !endswith(v.schematic_id, "ova") ?
    {
      id   = "${v.schematic_id}_${local.version}"
      name = substr(v.schematic_id, 0, 10)
    }
    :
    {
      id   = "${trimsuffix(basename(v.schematic_id), ".ova")}_${local.version}"
      name = trimsuffix(basename(v.schematic_id), ".ova")
    }
  }
}

data "vsphere_content_library" "content_library" {
  name = var.vmware.content_library
}

data "vsphere_content_library_item" "this" {
  for_each   = { for i, v in distinct([for k, v in local.image_ids : v]) : v.id => v.name }
  name       = "${var.cluster.name}-talos-${each.value}-${local.version}-${local.platform}-${local.arch}"
  type       = "ovf"
  library_id = data.vsphere_content_library.content_library.id
}
