variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name         = string
    endpoint     = string
    network_dhcp = optional(bool, false)
  })
}

variable "nodes" {
  description = "Configuration for worker nodes"
  type = map(object({
    machine_type = string
    ip           = string
    install_disk = optional(string, "/dev/sda")
    data_lvm     = optional(bool, false)
    data_disks = optional(list(object({
      type = optional(string)
      dev  = optional(string)
      name = optional(string)
    })), [])
    gpu            = optional(string)
    time_server    = optional(string)
    kernel_modules = optional(list(string), [])
  }))
}
