locals {
  factory_url = "https://factory.talos.dev"
  platform    = "nocloud"
  arch        = "amd64"
  version     = var.cluster.talos_version

  # Load schematic templates
  schematic_templates = {
    base   = yamldecode(file("${path.module}/schematics/base.yaml"))
    nvidia = yamldecode(file("${path.module}/schematics/nvidia.yaml"))
  }

  # Detect GPU type for each VM
  vm_gpu_types = {
    for k, v in var.vms : k => (
      v.gpu == null ? "base" : (
        can(regex("(?i)nvidia", v.gpu)) ? "nvidia" : "base"
      )
    )
  }

  # Unique GPU types actually used
  used_gpu_types = toset(values(local.vm_gpu_types))

  # Build merged extension lists for each GPU type
  # Base extensions + GPU-specific extensions + additional extensions
  extensions_by_type = {
    for gpu_type in ["base", "nvidia"] : gpu_type => concat(
      # Base extensions (always included)
      local.schematic_templates.base.customization.systemExtensions.officialExtensions,
      # GPU-specific extensions (if not base)
      gpu_type != "base" ? local.schematic_templates[gpu_type].customization.systemExtensions.officialExtensions : [],
      # Additional user-provided extensions
      var.cluster.talos_extensions
    )
  }

  # Generate schematics for each used GPU type
  schematics = {
    for gpu_type in local.used_gpu_types : gpu_type => yamlencode({
      customization = {
        systemExtensions = {
          officialExtensions = local.extensions_by_type[gpu_type]
        }
      }
    })
  }

  # Schematic IDs for each GPU type
  schematic_ids = {
    for gpu_type in local.used_gpu_types : gpu_type => jsondecode(data.http.schematic[gpu_type].response_body)["id"]
  }

  # Image IDs for each host
  image_ids = distinct([
    for k, v in var.vms : { node = v.host_node, id = local.schematic_ids[local.vm_gpu_types[k]] }
  ])

}

data "http" "schematic" {
  for_each = local.schematics

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
