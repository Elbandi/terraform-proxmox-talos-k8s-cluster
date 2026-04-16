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
    pool            = optional(string)
  })
  sensitive = true
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name                  = string
    talos_version         = string
    endpoint              = optional(string)
    network_dhcp          = optional(bool, false)
    gateway               = string
    dns_domain            = optional(string, null)
    dns_servers           = optional(list(string), null)
    cidr                  = number
    vlan_id               = optional(number, null)
    network_device_bridge = optional(string, "vmbr0")
  })
}

variable "vms" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node        = string
    machine_type     = string
    vm_id            = optional(number)
    schematic_id     = optional(string, "")
    datastore_id     = optional(string, "local-lvm")
    ip               = string
    bios             = optional(string, "uefi")
    cpu              = number
    memory_dedicated = number
    swap_size        = optional(number, 0)
    system_disk = object({
      size      = number
      interface = optional(string, "scsi")
      cache     = optional(bool, true)
    })
    user_disks = optional(list(object({
      size         = number
      interface    = optional(string, "scsi")
      datastore_id = optional(string)
      type         = optional(string)
      dev          = optional(string)
      name         = optional(string)
      cache        = optional(bool, true)
    })), [])
    disk_file_format = optional(string, "raw")
    gpu              = optional(string)
  }))
  validation {
    condition     = alltrue([for v in var.vms : contains(["legacy", "uefi"], v.bios)])
    error_message = format("Allowed values for bios are: %s.", join(", ", ["legacy", "uefi"]))
  }
}

variable "pci" {
  description = "Configuration mapping PCI"
  type = map(object({
    name             = string
    id               = string
    iommu_group      = number
    node             = string
    path             = string
    subsystem_id     = string
    mediated_devices = optional(bool, false)
  }))
  default = null
}
