variable "proxmox" {
  description = "Proxmox configuration"
  type = object({
    endpoint           = string
    insecure           = bool
    username           = string
    password           = optional(string)
    realm              = optional(string, "pam")
    api_token          = optional(string)
    ssh_agent          = optional(string, false)
    random_vm_ids      = optional(string, false)
    random_vm_id_start = optional(number, 1000)
    random_vm_id_end   = optional(number, 2000)
    iso_datastore_id   = optional(string, "local")
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

variable "additional_extensions" {
  description = "Additional Talos system extensions to include in all images (added to base + GPU-specific extensions)"
  type        = list(string)
  default     = []
}

variable "vms" {
  description = "Configuration for cluster nodes"
  type = map(object({
    host_node    = string
    datastore_id = optional(string, "local-lvm")
    gpu          = optional(string)
  }))
}
