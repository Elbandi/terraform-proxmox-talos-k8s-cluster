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
    mtu            = optional(number, 1450)
    cloud_provider = optional(string, "none")
    extra_hosts    = optional(map(list(string)))
    registries = optional(map(object({
      username = string
      password = string
    })), {})
  })
  validation {
    condition     = contains(["cilium", "calico"], var.cluster.cni)
    error_message = "Allowed values for cni are \"cilium\" or \"calico\"."
  }
  validation {
    condition     = contains(["none", "talos"], var.cluster.cloud_provider)
    error_message = "Allowed values for cloud_provider are \"none\" or \"talos\"."
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
    node_labels    = optional(map(any), {})
    custom_network = optional(string)
  }))
}
