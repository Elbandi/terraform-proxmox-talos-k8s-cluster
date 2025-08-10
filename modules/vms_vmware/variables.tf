variable "schematic_id" {
  type = string
}

variable "schematic_nvidia_id" {
  type = string
}

variable "vmware" {
  description = "VmWare configuration"
  type = object({
    endpoint        = optional(string)
    insecure        = optional(bool)
    username        = optional(string)
    password        = optional(string)
    datacenter      = optional(string)
    content_library = optional(string, "vHosting-ISO")
    cluster         = optional(string)
    folder          = optional(string)
  })
  sensitive = true
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name                  = string
    talos_version         = string
    network_dhcp          = optional(bool, false)
    gateway               = string
    dns_domain            = optional(string)
    dns_servers           = optional(list(string))
    cidr                  = number
    vlan_id               = optional(number, null)
    network_device_bridge = optional(string, "vmbr0")
  })
}

variable "vms" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node     = string
    machine_type  = string
    vm_id         = optional(number)
    datastore_id  = optional(string, "local-lvm")
    ip            = string
    cpu           = number
    ram_dedicated = number
    os_disk_size  = number
    data_disks = optional(list(object({
      size = number
      type = optional(string)
      dev  = optional(string)
      name = optional(string)
    })), [])
    disk_file_format = optional(string, "raw")
    gpu              = optional(string)
  }))
}

variable "pci" {
  description = "Configuration mapping PCI"
  type = map(object({
    name         = string
    id           = string
    iommu_group  = number
    node         = string
    path         = string
    subsystem_id = string
  }))
  default = null
}
