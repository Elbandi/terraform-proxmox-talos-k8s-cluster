variable "vmware" {
  description = "VmWare configuration"
  type = object({
    content_library = optional(string, "vHosting-ISO")
  })
  sensitive = true
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name          = string
    talos_version = string
  })
}

variable "vms" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node             = string
    additional_extensions = optional(list(string), [])
    schematic_id          = optional(string, "")
    datastore_id          = optional(string, "local-lvm")
    gpu                   = optional(string)
  }))
}
