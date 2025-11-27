locals {
  factory_url = "https://factory.talos.dev"
  platform    = "nocloud"
  arch        = "amd64"
  version     = var.cluster.talos_version

  schematic    = templatefile("${path.module}/schematic.yaml", { talos_extensions = var.cluster.talos_extensions })
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]

  schematic_nvidia    = templatefile("${path.module}/schematic-nvidia.yaml", { talos_extensions = var.cluster.talos_extensions })
  schematic_nvidia_id = jsondecode(data.http.schematic_nvidia_id.response_body)["id"]

  schematic_ids = distinct([for k, v in var.vms : { node = v.host_node, id = v.gpu != null ? local.schematic_nvidia_id : local.schematic_id }])
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

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = { for i, v in local.schematic_ids : "${v.node}_${v.id}_${local.version}" => v }

  node_name    = each.value.node
  content_type = "iso"
  datastore_id = var.proxmox.iso_datastore_id

  file_name               = "${var.cluster.name}-talos-${each.value.id}-${local.version}-${local.platform}-${local.arch}.img"
  url                     = "${local.factory_url}/image/${each.value.id}/${local.version}/${local.platform}-${local.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
