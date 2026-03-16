# Tests for the vms_vmware module.
# Covers: VM naming convention, VM count, DHCP vs static wait.
# Run from modules/vms_vmware/: terraform test

mock_provider "vsphere" {
  mock_data "vsphere_datacenter" {
    defaults = {
      id = "datacenter-1"
    }
  }
  mock_data "vsphere_datastore" {
    defaults = {
      id = "datastore-1"
    }
  }
  mock_data "vsphere_compute_cluster" {
    defaults = {
      id               = "domain-c1"
      resource_pool_id = "resgroup-1"
    }
  }
  mock_data "vsphere_network" {
    defaults = {
      id = "network-1"
    }
  }
  mock_data "vsphere_host" {
    defaults = {
      id = "host-1"
    }
  }
  mock_data "vsphere_content_library" {
    defaults = {
      id = "library-1"
    }
  }
  mock_data "vsphere_content_library_item" {
    defaults = {
      id = "item-1"
    }
  }
  mock_resource "vsphere_virtual_machine" {
    defaults = {
      id = "vm-1"
    }
  }
}

mock_provider "time" {
  mock_resource "time_sleep" {}
}

# File-level variable defaults shared across all run blocks
variables {
  vmware = {
    endpoint        = "https://vsphere.test"
    insecure        = true
    username        = "administrator@vsphere.local"
    password        = "secret"
    datacenter      = "DC"
    content_library = "talos-images"
    cluster         = "cluster1"
    folder          = "/DC/vm/k8s"
  }
  cluster = {
    name                  = "my-cluster"
    gateway               = "192.168.1.1"
    cidr                  = 24
    talos_version         = "v1.12.4"
    network_device_bridge = "VM Network"
  }
  vms = {
    "cp-0" = {
      host_node        = "esxi1"
      machine_type     = "controlplane"
      ip               = "192.168.1.10"
      cpu              = 2
      memory_dedicated = 4096
      datastore_id     = "datastore1"
      system_disk      = { size = 10 }
    }
  }
}

# ── VM naming ────────────────────────────────────────────────────────────────

# VMs must be named {cluster.name}-{vm_key}.
run "vm_naming_follows_convention" {
  command = plan

  assert {
    condition     = vsphere_virtual_machine.vms["cp-0"].name == "my-cluster-cp-0"
    error_message = "VM name should be '{cluster.name}-{vm_key}'"
  }
}

# ── VM count ─────────────────────────────────────────────────────────────────

# One vsphere_virtual_machine resource is created per entry in var.vms.
run "vm_count_matches_input" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.10"
        cpu              = 2
        memory_dedicated = 4096
        datastore_id     = "datastore1"
        system_disk      = { size = 10 }
      }
      "cp-1" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.11"
        cpu              = 2
        memory_dedicated = 4096
        datastore_id     = "datastore1"
        system_disk      = { size = 10 }
      }
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
      }
    }
  }

  assert {
    condition     = length(vsphere_virtual_machine.vms) == 3
    error_message = "Should create exactly one VM per entry in var.vms"
  }
}

# ── Static vs DHCP networking ────────────────────────────────────────────────

# In static mode no wait is injected after VM creation.
run "static_networking_no_wait" {
  command = plan

  assert {
    condition     = time_sleep.waiting_if_dhcp.create_duration == "0s"
    error_message = "Static mode should not inject a wait after VM creation"
  }
}

# In DHCP mode a 60-second wait is injected to allow IP assignment.
run "dhcp_networking_enables_wait" {
  command = plan

  variables {
    cluster = {
      name                  = "my-cluster"
      network_dhcp          = true
      gateway               = "192.168.1.1"
      cidr                  = 24
      talos_version         = "v1.12.4"
      network_device_bridge = "VM Network"
    }
  }

  assert {
    condition     = time_sleep.waiting_if_dhcp.create_duration == "60s"
    error_message = "DHCP mode should inject a 60s wait after VM creation"
  }
}

# ── CPU and memory ────────────────────────────────────────────────────────────

# num_cpus and memory must reflect the values from var.vms.
run "cpu_and_memory_match_vm_config" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.10"
        cpu              = 8
        memory_dedicated = 16384
        datastore_id     = "datastore1"
        system_disk      = { size = 10 }
      }
    }
  }

  assert {
    condition     = vsphere_virtual_machine.vms["cp-0"].num_cpus == 8
    error_message = "num_cpus should match the cpu value in vm config"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["cp-0"].memory == 16384
    error_message = "memory should match memory_dedicated in vm config"
  }
}

# ── Disk configuration ────────────────────────────────────────────────────────

# A VM with no user_disks should have exactly one disk (the system disk).
run "vm_with_no_user_disks_has_one_disk" {
  command = plan

  assert {
    condition     = length(vsphere_virtual_machine.vms["cp-0"].disk) == 1
    error_message = "VM with no user_disks should have exactly one disk"
  }
}

# A VM with user_disks should have 1 system disk plus the additional data disks.
run "user_disks_added_as_additional_disks" {
  command = plan

  variables {
    vms = {
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
        user_disks = [
          { size = 50 },
          { size = 100 },
        ]
      }
    }
  }

  assert {
    condition     = length(vsphere_virtual_machine.vms["worker-0"].disk) == 3
    error_message = "VM with 2 user_disks should have 3 disks total (1 system + 2 data)"
  }
}

# System disk size must match what is configured.
run "system_disk_size_matches_config" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.10"
        cpu              = 2
        memory_dedicated = 4096
        datastore_id     = "datastore1"
        system_disk      = { size = 42 }
      }
    }
  }

  assert {
    condition     = vsphere_virtual_machine.vms["cp-0"].disk[0].size == 42
    error_message = "First disk size should match system_disk.size"
  }
}

# ── VM placement ──────────────────────────────────────────────────────────────

# VMs are placed in the folder configured on the vmware variable.
run "vm_placed_in_configured_folder" {
  command = plan

  variables {
    vmware = {
      endpoint        = "https://vsphere.test"
      insecure        = true
      username        = "administrator@vsphere.local"
      password        = "secret"
      datacenter      = "DC"
      content_library = "talos-images"
      cluster         = "cluster1"
      folder          = "/DC/vm/production"
    }
  }

  assert {
    condition     = vsphere_virtual_machine.vms["cp-0"].folder == "/DC/vm/production"
    error_message = "VM folder should match vmware.folder"
  }
}

# ── Mixed machine types ───────────────────────────────────────────────────────

# A cluster with both controlplane and worker VMs creates all of them correctly.
run "mixed_controlplane_and_worker_vms" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.10"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
      }
      "cp-1" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.11"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
      }
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 8
        memory_dedicated = 32768
        datastore_id     = "datastore1"
        system_disk      = { size = 40 }
        user_disks       = [{ size = 200 }]
      }
    }
  }

  assert {
    condition     = length(vsphere_virtual_machine.vms) == 3
    error_message = "Should create all 3 VMs (2 controlplane + 1 worker)"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["cp-0"].name == "my-cluster-cp-0"
    error_message = "Controlplane VM name should follow naming convention"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].name == "my-cluster-worker-0"
    error_message = "Worker VM name should follow naming convention"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].num_cpus == 8
    error_message = "Worker VM should have its own cpu count"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].memory == 32768
    error_message = "Worker VM should have its own memory size"
  }
}

# ── Multiple datastores ───────────────────────────────────────────────────────

# VMs on different datastores are all created; each VM uses its own datastore.
run "vms_on_different_datastores" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.10"
        cpu              = 2
        memory_dedicated = 4096
        datastore_id     = "ssd-datastore"
        system_disk      = { size = 10 }
      }
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "hdd-datastore"
        system_disk      = { size = 20 }
      }
    }
  }

  assert {
    condition     = length(vsphere_virtual_machine.vms) == 2
    error_message = "Both VMs should be created regardless of datastore differences"
  }
}

# ── user_disks scenarios ──────────────────────────────────────────────────────

# A single user disk becomes "Hard disk 2" with unit_number 1.
run "single_user_disk_label_and_unit_number" {
  command = plan

  variables {
    vms = {
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
        user_disks       = [{ size = 100 }]
      }
    }
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[1].label == "Hard disk 2"
    error_message = "First user disk label should be 'Hard disk 2'"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[1].unit_number == 1
    error_message = "First user disk unit_number should be 1"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[1].size == 100
    error_message = "User disk size should match configured value"
  }
}

# Two user disks get sequential labels and unit numbers.
run "two_user_disks_get_sequential_labels" {
  command = plan

  variables {
    vms = {
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
        user_disks = [
          { size = 50 },
          { size = 100 },
        ]
      }
    }
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[1].label == "Hard disk 2"
    error_message = "First user disk label should be 'Hard disk 2'"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[1].unit_number == 1
    error_message = "First user disk unit_number should be 1"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[2].label == "Hard disk 3"
    error_message = "Second user disk label should be 'Hard disk 3'"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[2].unit_number == 2
    error_message = "Second user disk unit_number should be 2"
  }
}

# Each user disk size is preserved independently.
run "user_disk_sizes_are_preserved_per_disk" {
  command = plan

  variables {
    vms = {
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
        user_disks = [
          { size = 50 },
          { size = 200 },
          { size = 500 },
        ]
      }
    }
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[1].size == 50
    error_message = "First user disk size should be 50"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[2].size == 200
    error_message = "Second user disk size should be 200"
  }

  assert {
    condition     = vsphere_virtual_machine.vms["worker-0"].disk[3].size == 500
    error_message = "Third user disk size should be 500"
  }
}

# Three user disks result in 4 total disks (1 system + 3 data).
run "three_user_disks_total_count_is_four" {
  command = plan

  variables {
    vms = {
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
        user_disks = [
          { size = 50 },
          { size = 100 },
          { size = 200 },
        ]
      }
    }
  }

  assert {
    condition     = length(vsphere_virtual_machine.vms["worker-0"].disk) == 4
    error_message = "3 user_disks should result in 4 total disks (1 system + 3 data)"
  }
}

# VMs in the same cluster can have different user_disk counts independently.
run "different_vms_have_independent_user_disks" {
  command = plan

  variables {
    vms = {
      "cp-0" = {
        host_node        = "esxi1"
        machine_type     = "controlplane"
        ip               = "192.168.1.10"
        cpu              = 2
        memory_dedicated = 4096
        datastore_id     = "datastore1"
        system_disk      = { size = 10 }
      }
      "worker-0" = {
        host_node        = "esxi1"
        machine_type     = "worker"
        ip               = "192.168.1.20"
        cpu              = 4
        memory_dedicated = 8192
        datastore_id     = "datastore1"
        system_disk      = { size = 20 }
        user_disks       = [{ size = 100 }, { size = 200 }]
      }
    }
  }

  assert {
    condition     = length(vsphere_virtual_machine.vms["cp-0"].disk) == 1
    error_message = "Controlplane with no user_disks should have exactly 1 disk"
  }

  assert {
    condition     = length(vsphere_virtual_machine.vms["worker-0"].disk) == 3
    error_message = "Worker with 2 user_disks should have 3 disks total"
  }
}
