locals {
  factory_url = "https://factory.talos.dev"
  platform    = "vmware"
  arch        = "amd64"
  version     = var.cluster.talos_version

  # vmname => schema_data.yaml
  schematic_nodes = { for k, v in var.vms : k => templatefile("${path.module}/schematics/schematic.yaml.tmpl", {
    gpu                   = v.gpu
    additional_extensions = v.additional_extensions
  }) if !endswith(v.schematic_id, "ova") }
  # vmname => sha256(schema_data.yaml)
  schematic_node_hash = { for k, v in local.schematic_nodes : k => sha256(v) }
  # sha256(schema_data.yaml) => schema_data.yaml
  schematic_hash = { for k, v in distinct([for schema in local.schematic_nodes : schema]) : sha256(v) => v }

  # sha256(schema_data.yaml) => factory_id
  schematic_ids_data = { for k, v in local.schematic_hash : k => jsondecode(data.http.schematic_id[k].response_body)["id"] }
  # distinct [{factory_id}]
  image_ids = distinct([for k, v in var.vms : !endswith(v.schematic_id, "ova") ?
    {
      id       = local.schematic_ids_data[local.schematic_node_hash[k]],
      name     = "${var.cluster.name}-talos-${substr(local.schematic_ids_data[local.schematic_node_hash[k]], 0, 10)}-${local.version}-${local.platform}-${local.arch}"
      file_url = "https://talos-factory.elbandi.net/image/${local.schematic_ids_data[local.schematic_node_hash[k]]}/${local.version}/${local.platform}-${local.arch}.ova"
    }
    :
    {
      id       = trimsuffix(basename(v.schematic_id), ".ova")
      name     = "${var.cluster.name}-talos-${trimsuffix(basename(v.schematic_id), ".ova")}-${local.version}-${local.platform}-${local.arch}"
      file_url = v.schematic_id
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

data "vsphere_content_library" "content_library" {
  name = var.vmware.content_library
}

resource "vsphere_content_library_item" "this" {
  for_each        = { for i, v in local.image_ids : "${v.id}_${local.version}" => v }
  type            = "ovf"
  description     = "Talos factory OVF Template"
  name            = each.value.name
  file_url        = each.value.file_url
  library_id      = data.vsphere_content_library.content_library.id
  remove_existing = true
}
