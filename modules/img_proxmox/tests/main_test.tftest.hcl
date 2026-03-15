# Tests for the img_proxmox module.
# Covers: image file naming, image URL, schematic deduplication, GPU schematics,
#         pre-existing qcow2 download path, ova schematic_id passthrough.
# Run from modules/img_proxmox/: terraform test

mock_provider "proxmox" {
  mock_resource "proxmox_virtual_environment_download_file" {
    defaults = {
      id = "local:import/test.qcow2"
    }
  }
}

mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "{\"id\":\"mock-schematic-factory-id\"}"
    }
  }
}

# File-level variable defaults shared across all run blocks
variables {
  proxmox = {
    endpoint  = "https://pve.test:8006"
    insecure  = true
    username  = "root@pam"
    api_token = "root@pam!test=secret"
  }
  cluster = {
    name          = "my-cluster"
    talos_version = "v1.9.0"
  }
  vms = {
    "cp-0" = {
      host_node = "pve1"
    }
  }
}

# ── Image naming and URL ──────────────────────────────────────────────────────

# The downloaded file must be named {cluster.name}-talos-{id}-{version}-nocloud-amd64.qcow2
run "image_file_name_follows_convention" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_download_file.this["pve1_mock-schematic-factory-id_v1.9.0"].file_name == "my-cluster-talos-mock-schematic-factory-id-v1.9.0-nocloud-amd64.qcow2"
    error_message = "File name should be '{cluster.name}-talos-{schematic_id}-{talos_version}-nocloud-amd64.qcow2'"
  }
}

# The download URL must point to the Talos image factory with the correct path segments.
run "image_url_uses_factory_endpoint" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_download_file.this["pve1_mock-schematic-factory-id_v1.9.0"].url == "https://factory.talos.dev/image/mock-schematic-factory-id/v1.9.0/nocloud-amd64.qcow2"
    error_message = "URL should be 'https://factory.talos.dev/image/{id}/{version}/nocloud-amd64.qcow2'"
  }
}

# The download resource must be placed on the correct Proxmox node.
run "image_download_targets_correct_node" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_download_file.this["pve1_mock-schematic-factory-id_v1.9.0"].node_name == "pve1"
    error_message = "Download resource should target the VM's host_node"
  }
}

# ── Schematic deduplication ───────────────────────────────────────────────────

# Two VMs on the same node with identical config produce a single download resource.
run "same_node_same_config_produces_one_download" {
  command = plan

  variables {
    vms = {
      "cp-0" = { host_node = "pve1" }
      "cp-1" = { host_node = "pve1" }
    }
  }

  assert {
    condition     = length(proxmox_virtual_environment_download_file.this) == 1
    error_message = "Two VMs on the same node with identical schematic should share one download resource"
  }
}

# Two VMs on different nodes with the same config produce one download resource per node.
run "different_nodes_same_config_produces_one_download_per_node" {
  command = plan

  variables {
    vms = {
      "cp-0" = { host_node = "pve1" }
      "cp-1" = { host_node = "pve2" }
    }
  }

  assert {
    condition     = length(proxmox_virtual_environment_download_file.this) == 2
    error_message = "VMs on different nodes should each get their own download resource"
  }
}

# ── schematic_ids output ──────────────────────────────────────────────────────

# The output maps each VM key to its resolved factory schematic ID.
run "schematic_ids_output_maps_vm_to_factory_id" {
  command = plan

  assert {
    condition     = output.schematic_ids["cp-0"] == "mock-schematic-factory-id"
    error_message = "schematic_ids output should map the VM key to the factory-resolved schematic ID"
  }
}

# ── GPU schematic ─────────────────────────────────────────────────────────────

# A VM with gpu set uses a different schematic (nvidia extensions are added),
# which produces a separate HTTP call to the Talos factory for its schematic ID.
run "gpu_vm_gets_separate_schematic_from_plain_vm" {
  command = plan

  variables {
    vms = {
      "cp-0"     = { host_node = "pve1" }
      "worker-0" = { host_node = "pve1", gpu = "nvidia" }
    }
  }

  assert {
    condition     = length(data.http.schematic_id) == 2
    error_message = "A GPU VM has a different schematic YAML from a plain VM; two distinct HTTP calls should be made to the Talos factory"
  }
}

# ── ova schematic_id passthrough ──────────────────────────────────────────────

# When schematic_id ends in ".ova", vm_schematic_ids passes through the value
# directly (no factory ID lookup). The download resource still uses the factory
# ID computed from the schematic template (ova VMs are NOT excluded from
# schematic rendering).
run "ova_schematic_id_passes_through_in_output" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node    = "pve1"
        schematic_id = "some-vmware-image.ova"
      }
    }
  }

  assert {
    condition     = output.schematic_ids["cp-0"] == "some-vmware-image.ova"
    error_message = "An ova schematic_id should be passed through as-is in the schematic_ids output"
  }
}

# ── Additional extensions ─────────────────────────────────────────────────────

# Two VMs with different additional_extensions produce different schematics,
# which means separate HTTP calls to the Talos factory.
run "different_extensions_produce_separate_schematic_calls" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node             = "pve1"
        additional_extensions = []
      }
      "worker-0" = {
        host_node             = "pve1"
        additional_extensions = ["siderolabs/zfs"]
      }
    }
  }

  assert {
    condition     = length(data.http.schematic_id) == 2
    error_message = "VMs with different additional_extensions have different schematic YAMLs; two distinct HTTP calls should be made to the Talos factory"
  }
}
