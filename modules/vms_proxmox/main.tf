resource "proxmox_virtual_environment_vm" "vms" {
  for_each = var.vms

  node_name = each.value.host_node

  name    = "${var.cluster.name}-${each.key}"
  tags    = ["terraform", "talos", "k8s", each.value.machine_type, var.cluster.name]
  on_boot = true
  started = true
  vm_id   = each.value.vm_id
  pool_id = var.proxmox.pool != null ? data.proxmox_virtual_environment_pool.pool[0].id : null

  bios          = "ovmf"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-pci"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
    numa  = true
  }

  memory {
    dedicated = each.value.memory_dedicated
  }

  network_device {
    bridge  = var.cluster.network_device_bridge
    vlan_id = var.cluster.vlan_id
  }

  # EFI disk
  efi_disk {
    datastore_id = each.value.datastore_id
    file_format  = each.value.disk_file_format
    type         = "4m"
    # pre_enrolled_keys = true
  }

  # system disk
  disk {
    datastore_id = each.value.datastore_id
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = "true"
    file_format  = each.value.disk_file_format
    size         = each.value.system_disk_size
    file_id      = each.value.gpu != null ? local.image_nvidia_id : local.image_id
  }

  # user disk - csak akkor adja hozzá, ha data_disk letezik
  dynamic "disk" {
    for_each = each.value.user_disks
    content {
      datastore_id = disk.value.datastore_id != null ? disk.value.datastore_id : each.value.datastore_id
      interface    = "scsi${disk.key + 1}"
      iothread     = true
      cache        = "writethrough"
      discard      = "on"
      ssd          = true
      file_format  = each.value.disk_file_format
      size         = disk.value.size
      serial       = disk.value.type != null ? "${disk.value.type}-${disk.value.name}-${disk.key + 1}" : null
    }
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = each.value.datastore_id

    dynamic "dns" {
      for_each = (var.cluster.dns_domain != null || var.cluster.dns_servers != null) ? [1] : []
      content {
        domain  = var.cluster.dns_domain
        servers = var.cluster.dns_servers
      }
    }

    ip_config {
      ipv4 {
        address = var.cluster.network_dhcp == true ? "dhcp" : "${each.value.ip}/${var.cluster.cidr}"
        gateway = var.cluster.network_dhcp == true ? null : var.cluster.gateway
      }
    }
  }

  dynamic "hostpci" {
    for_each = (each.value.gpu != null) ? [1] : []
    content {
      # Passthrough GPU
      device  = "hostpci0"
      mapping = each.value.gpu
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].dns[0]
    ]
  }

}
data "proxmox_virtual_environment_pool" "pool" {
  count   = var.proxmox.pool != null ? 1 : 0
  pool_id = var.proxmox.pool
}

# resource "proxmox_virtual_environment_pool_membership" "pool_member" {
# #  for_each = var.vms
#   pool_id    = data.proxmox_virtual_environment_pool.pool[0].id
#   vm_id   = proxmox_virtual_environment_vm.vms[*].id
# }

resource "time_sleep" "waiting_if_dhcp" {
  depends_on      = [proxmox_virtual_environment_vm.vms]
  create_duration = (var.cluster.network_dhcp == true) ? "60s" : "0s"
}