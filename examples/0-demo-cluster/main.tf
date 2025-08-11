module "talos_k8s_cluster" {
  #  source  = "vdupain/talos-k8s-cluster/proxmox"
  #  version = "1.0.0"
  source = "../.."

  schematic_id        = var.schematic_id
  schematic_nvidia_id = var.schematic_nvidia_id

  cluster = {
    talos_version = "v1.10.5"
    name          = "demo-cluster"
    gateway       = "192.168.10.1"
    cidr          = 24
    # endpoint ip sould be above as node ip!!!
    endpoint              = "192.168.10.210"
    network_device_bridge = "4013-Linux-3"
  }

  vms = {
    "k8s-cp-0" = {
      host_node     = "pve"
      machine_type  = "controlplane"
      ip            = "192.168.10.20"
      cpu           = 2
      ram_dedicated = 4096
      os_disk_size  = 10
      datastore_id  = "local-lvm"
    }
    "k8s-cp-1" = {
      host_node     = "pve"
      machine_type  = "controlplane"
      ip            = "192.168.10.21"
      cpu           = 2
      ram_dedicated = 4096
      os_disk_size  = 10
      datastore_id  = "local-lvm"
    }
    "k8s-cp-2" = {
      host_node     = "pve"
      machine_type  = "controlplane"
      ip            = "192.168.10.22"
      cpu           = 2
      ram_dedicated = 4096
      os_disk_size  = 10
      datastore_id  = "local-lvm"
    }
    "k8s-w-0" = {
      host_node     = "pve"
      machine_type  = "worker"
      ip            = "192.168.10.30"
      cpu           = 2
      ram_dedicated = 4096
      os_disk_size  = 10
      data_disks = [
        { size = 10, type = "lvm", dev = "/dev/sdb", name = "lvmpv" }
      ]
      datastore_id = "local-lvm"
    }
    "k8s-w-1" = {
      host_node     = "pve"
      machine_type  = "worker"
      ip            = "192.168.10.31"
      cpu           = 2
      ram_dedicated = 4096
      os_disk_size  = 10
      data_disks = [
        { size = 10, type = "lvm", dev = "/dev/sdb", name = "lvmpv" }
      ]
      datastore_id = "local-lvm"
    }
  }

  vmware  = var.vmware
  proxmox = var.proxmox

  gitops = {
    repository   = "https://github.com/vdupain/gitops.git"
    token        = "github_pat"
    cluster_name = "my-cluster"
  }

}
