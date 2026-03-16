# Tests for the img_vmware module.
# Covers: image name, image URL, schematic deduplication, GPU schematics,
#         ova schematic_id passthrough (excluded from factory lookup).
# Run from modules/img_vmware/: terraform test

mock_provider "vsphere" {
  mock_data "vsphere_content_library" {
    defaults = {
      id = "mock-library-id"
    }
  }
  mock_resource "vsphere_content_library_item" {
    defaults = {
      id = "mock-library-item-id"
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
  vmware = {
    content_library = "test-library"
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

# The content library item name must be {cluster.name}-talos-{substr(id,0,10)}-{version}-vmware-amd64
run "image_name_follows_convention" {
  command = plan

  assert {
    condition     = vsphere_content_library_item.this["mock-schematic-factory-id_v1.9.0"].name == "my-cluster-talos-mock-schem-v1.9.0-vmware-amd64"
    error_message = "Name should be '{cluster.name}-talos-{substr(schematic_id,0,10)}-{talos_version}-vmware-amd64'"
  }
}

# The download URL must point to the Talos image factory with the correct path segments.
run "image_url_uses_factory_endpoint" {
  command = plan

  assert {
    condition     = vsphere_content_library_item.this["mock-schematic-factory-id_v1.9.0"].file_url == "https://talos-factory.elbandi.net/image/mock-schematic-factory-id/v1.9.0/vmware-amd64.ova"
    error_message = "file_url should be 'https://talos-factory.elbandi.net/image/{id}/{version}/vmware-amd64.ova'"
  }
}

# ── Schematic deduplication ───────────────────────────────────────────────────

# Two VMs on the same node with identical config produce a single content library item.
run "same_node_same_config_produces_one_library_item" {
  command = plan

  variables {
    vms = {
      "cp-0" = { host_node = "pve1" }
      "cp-1" = { host_node = "pve1" }
    }
  }

  assert {
    condition     = length(vsphere_content_library_item.this) == 1
    error_message = "Two VMs with identical schematic should share one content library item"
  }
}

# Two VMs on different nodes with the same config still produce a single content library item.
# Unlike Proxmox (per-node images), VMware uploads to a shared content library.
run "different_nodes_same_config_produces_one_library_item" {
  command = plan

  variables {
    vms = {
      "cp-0" = { host_node = "pve1" }
      "cp-1" = { host_node = "pve2" }
    }
  }

  assert {
    condition     = length(vsphere_content_library_item.this) == 1
    error_message = "VMs on different nodes with the same schematic share one content library item (vmware images are not per-node)"
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

# When schematic_id ends in ".ova", the VM is excluded from schematic rendering:
# no HTTP call to the factory, and the ova URL is used directly for the content library item.
# The schematic_ids output returns the full ova path as-is.
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

  assert {
    condition     = length(data.http.schematic_id) == 0
    error_message = "An ova VM should not trigger an HTTP call to the Talos factory"
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
