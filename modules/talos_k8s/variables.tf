variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name           = string
    id             = optional(number, 0)
    endpoint       = string
    network_dhcp   = optional(bool, false)
    cni            = optional(string, "cilium")
    lvm_label_node = optional(bool, true)
    pod_subnet     = optional(string, "10.244.0.0/16")
    service_subnet = optional(string, "10.96.0.0/12")
  })
  validation {
    condition     = contains(["cilium", "calico"], var.cluster.cni)
    error_message = "Allowed values for cni are \"cilium\" or \"calico\"."
  }
}

variable "nodes" {
  description = "Configuration for worker nodes"
  type = map(object({
    machine_type = string
    ip           = string
    install_disk = optional(string, "/dev/sda")
    data_disks = optional(list(object({
      type = optional(string)
      dev  = optional(string)
      name = optional(string)
    })), [])
    gpu            = optional(string)
    time_server    = optional(string)
    kernel_modules = optional(list(string), [])
    custom_network = optional(string)
  }))
}
