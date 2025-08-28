variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name                               = string
    id                                 = optional(number, 0)
    talos_version                      = optional(string)
    kubernetes_version                 = optional(string)
    endpoint                           = string
    network_dhcp                       = optional(bool, false)
    allow_scheduling_on_control_planes = optional(bool, true)
    vip_ip                             = optional(string)
    vip_interface                      = optional(string, "eth0")
    lvm_label_node                     = optional(bool, true)
    pod_subnet                         = optional(string, "10.244.0.0/16")
    service_subnet                     = optional(string, "10.96.0.0/12")
  })
}

variable "nodes" {
  description = "Configuration for worker nodes"
  type = map(object({
    machine_type = string
    ip           = string
    install_disk = optional(string, "/dev/sda")
    user_disks = optional(list(object({
      type = optional(string)
      dev  = optional(string)
      name = optional(string)
    })), [])
    gpu            = optional(string)
    time_server    = optional(string)
    kernel_modules = optional(list(string), [])
  }))
}
