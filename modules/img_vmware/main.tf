locals {
  factory_url = "https://factory.talos.dev"
  platform    = "vmware"
  arch        = "amd64"
  version     = var.cluster.talos_version

  schematic    = templatefile("${path.module}/schematic.yaml", { talos_extensions = var.cluster.talos_extensions })
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]
  image_id     = "${local.schematic_id}_${local.version}"

  schematic_nvidia    = templatefile("${path.module}/schematic-nvidia.yaml", { talos_extensions = var.cluster.talos_extensions })
  schematic_nvidia_id = jsondecode(data.http.schematic_nvidia_id.response_body)["id"]
  image_nvidia_id     = "${local.schematic_nvidia_id}_${local.version}"
}

data "http" "schematic_id" {
  url          = "${local.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic
}

data "http" "schematic_nvidia_id" {
  url          = "${local.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic_nvidia
}

data "vsphere_content_library" "content_library" {
  name = var.vmware.content_library
}

resource "vsphere_content_library_item" "this" {
  for_each        = toset(distinct([for k, v in var.vms : "${v.gpu != null ? local.image_nvidia_id : local.image_id}"]))
  type            = "ovf"
  description     = "Talos factory OVF Template"
  name            = "${var.cluster.name}-talos-${substr(split("_", each.key)[0], 0, 10)}-${split("_", each.key)[1]}-${local.platform}-${local.arch}"
  file_url        = "https://talos-factory.elbandi.net/image/${split("_", each.key)[0]}/${split("_", each.key)[1]}/${local.platform}-${local.arch}.ova"
  library_id      = data.vsphere_content_library.content_library.id
  remove_existing = true
}
