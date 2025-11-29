locals {
  factory_url = "https://factory.talos.dev"
  platform    = "nocloud"
  arch        = "amd64"
  version     = var.cluster.talos_version


  # vmname => schema_data.yaml
  schematic_nodes = { for k, v in var.vms : k => templatefile("${path.module}/schematics/schematic.yaml.tmpl", {
    gpu                   = v.gpu
    additional_extensions = v.additional_extensions
  }) if !endswith(v.schematic_id, "qcow2") }
  # vmname => sha256(schema_data.yaml)
  schematic_node_hash = { for k, v in local.schematic_nodes : k => sha256(v) }
  # sha256(schema_data.yaml) => schema_data.yaml
  schematic_hash = { for k, v in distinct([for schema in local.schematic_nodes : schema]) : sha256(v) => v }

  # sha256(schema_data.yaml) => factory_id
  schematic_ids_data = { for k, v in local.schematic_hash : k => jsondecode(data.http.schematic_id[k].response_body)["id"] }
  # [{nodename, factory_id}]
  image_ids = distinct([
    for k, v in var.vms : {
      node = v.host_node,
      id   = !endswith(v.schematic_id, "qcow2") ? local.schematic_ids_data[local.schematic_node_hash[k]] : trimsuffix(basename(v.schematic_id), ".qcow2")
    }
  ])
  # vmname => factory_id
  vm_schematic_ids = { for k, v in var.vms : k => !endswith(v.schematic_id, "ova") ? local.schematic_ids_data[local.schematic_node_hash[k]] : v.schematic_id }
}

data "http" "schematic_id" {
  for_each     = local.schematic_hash
  url          = "${local.factory_url}/schematics"
  method       = "POST"
  request_body = each.value
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = { for i, v in local.image_ids : "${v.node}_${v.id}_${local.version}" => v }

  node_name    = each.value.node
  content_type = "import"
  datastore_id = var.proxmox.iso_datastore_id

  file_name = "${var.cluster.name}-talos-${each.value.id}-${local.version}-${local.platform}-${local.arch}.qcow2"
  url       = "${local.factory_url}/image/${each.value.id}/${local.version}/${local.platform}-${local.arch}.qcow2"
  overwrite = false
}
