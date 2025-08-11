module "talos_k8s_cluster" {
  source = "../.."
  #  version = "1.6.0"

  schematic_id        = var.schematic_id
  schematic_nvidia_id = var.schematic_nvidia_id

  cluster = {
    talos_version         = "v1.9.5"
    name                  = "mini-cluster"
    gateway               = "192.168.10.1"
    cidr                  = 24
    endpoint              = "192.168.10.100"
    network_device_bridge = "4013-Linux-3"
  }

  vms = {
    "k8s-cp-0" = {
      host_node     = "pve1"
      machine_type  = "controlplane"
      ip            = "192.168.10.50"
      cpu           = 4
      ram_dedicated = 4096
      os_disk_size  = 10
      data_disks = [
        { size = 10, type = "lvm", dev = "/dev/sdb", name = "lvmpv" }
      ]
      datastore_id = "datastore"
    }
  }

  vmware  = var.vmware
  proxmox = var.proxmox
}
