data "vsphere_datacenter" "datacenter" {
  name = var.vmware.datacenter
}

data "vsphere_datastore" "datastore" {
  for_each      = toset(distinct([for k, v in var.vms : v.datastore_id]))
  name          = each.key
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vmware.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.cluster.network_device_bridge
  datacenter_id = data.vsphere_datacenter.datacenter.id
  filter {
    network_type = "Network"
  }
}

data "vsphere_host" "host" {
  for_each      = toset(distinct([for k, v in var.vms : v.host_node]))
  name          = each.key
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  count         = var.vmware.pool != null ? 1 : 0
  datacenter_id = data.vsphere_datacenter.datacenter.id
  name          = var.vmware.pool
}

resource "vsphere_virtual_machine" "vms" {
  depends_on       = [data.vsphere_content_library_item.this]
  for_each         = var.vms
  resource_pool_id = var.vmware.pool != null ? data.vsphere_resource_pool.pool[0].id : data.vsphere_compute_cluster.cluster.resource_pool_id

  name = "${var.cluster.name}-${each.key}"
  #   tags    = ["terraform", "talos", "k8s", each.value.machine_type, var.cluster.name]
  #   on_boot = true
  #   started = true
  #   vm_id   = each.value.vm_id
  #  host_system_id = data.vsphere_host.host[each.value.host_node].id
  #  wait_for_guest_net_timeout = 5
  wait_for_guest_net_routable = false
  wait_for_guest_ip_timeout   = 5
  scsi_controller_count       = 1

  folder = var.vmware.folder
  #   machine       = "q35"
  #   scsi_hardware = "virtio-scsi-single"
  #   bios          = "seabios"

  #   agent {
  #     enabled = true
  #   }

  num_cpus                         = each.value.cpu
  cpu_hot_add_enabled              = true
  cpu_hot_remove_enabled           = true
  cpu_performance_counters_enabled = true
  nested_hv_enabled                = true
  vvtd_enabled                     = true
  #   cpu {
  #     cores = each.value.cpu
  #     type  = "host"
  #     numa  = true
  #   }

  memory                 = each.value.memory_dedicated
  memory_hot_add_enabled = true
  #   memory {
  #     dedicated = each.value.ram_dedicated
  #   }

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  #   network_device {
  #     bridge  = var.cluster.network_device_bridge
  #     vlan_id = var.cluster.vlan_id
  #   }

  disk {
    label = "Hard disk 1"
    size  = each.value.system_disk.size
  }
  datastore_id = data.vsphere_datastore.datastore[each.value.datastore_id].id

  clone {
    template_uuid = data.vsphere_content_library_item.this["${local.image_ids[each.key].id}"].id
    #   customize {
    #     linux_options {
    #       host_name = "${var.cluster.name}-${each.key}"
    #       domain    = "${var.cluster.name}-${each.key}"
    #     }
    #     network_interface {
    #       ipv4_address = each.value.ip
    #       ipv4_netmask = var.cluster.cidr
    #     }
    #     ipv4_gateway = var.cluster.network_dhcp == true ? null : var.cluster.gateway
    #     dns_server_list = var.cluster.dns_servers
    #   }
  }
  extra_config = {
    "guestinfo.metadata" = base64encode(templatefile("${path.module}/cloud-init/network-config.tpl", {
      network_interface = "eth0"
      hostname          = "${var.cluster.name}-${each.key}"
      ipaddress         = var.cluster.network_dhcp == true ? "dhcp" : "${each.value.ip}/${var.cluster.cidr}"
      gateway           = var.cluster.network_dhcp == true ? "" : var.cluster.gateway
      dns               = var.cluster.dns_servers
      domain_name       = var.cluster.dns_domain
    }))
    "guestinfo.metadata.encoding" = "base64"
    #    "guestinfo.userdata"          = base64gzip(data.template_file.server_cloud_init_userdata[each.key].rendered)
    #    "guestinfo.userdata.encoding" = "gzip+base64"
  }
  enable_disk_uuid = true

  # data disk - csak akkor adja hozzá, ha data_disk letezik
  dynamic "disk" {
    for_each = each.value.user_disks
    content {
      label       = "Hard disk ${disk.key + 2}"
      size        = disk.value.size
      unit_number = disk.key + 1
      #        serial       = disk.value.type != null ? "${disk.value.type}-${disk.value.name}-${disk.key + 1}" : null
    }
  }

  #   boot_order = ["scsi0"]

  #   operating_system {
  #     type = "l26"
  #   }
  guest_id = "other3xLinux64Guest"

  #   initialization {
  #     datastore_id = each.value.datastore_id

  #     dynamic "dns" {
  #       for_each = var.cluster.dns_domain != null || var.cluster.dns_servers != null ? [1] : []
  #       content {
  #         domain  = var.cluster.dns_domain
  #         servers = var.cluster.dns_servers
  #       }
  #     }

  #     ip_config {
  #       ipv4 {
  #         address = var.cluster.network_dhcp == true ? "dhcp" : "${each.value.ip}/${var.cluster.cidr}"
  #         gateway = var.cluster.network_dhcp == true ? null : var.cluster.gateway
  #       }
  #     }
  #   }

  #   dynamic "hostpci" {
  #     for_each = (each.value.gpu != null) ? [1] : []
  #     content {
  #       # Passthrough GPU
  #       device  = "hostpci0"
  #       mapping = each.value.gpu
  #       pcie    = true
  #       rombar  = true
  #       xvga    = false
  #     }
  #   }
  lifecycle {
    ignore_changes = [
      # ignore changes to extra_config scsi..virtualSSD in case the host does not have the device
      extra_config,
    ]
  }
}

resource "time_sleep" "waiting_if_dhcp" {
  depends_on      = [vsphere_virtual_machine.vms]
  create_duration = (var.cluster.network_dhcp == true) ? "60s" : "0s"
}
