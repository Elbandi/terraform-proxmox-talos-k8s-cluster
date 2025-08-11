variable "schematic_id" {
  type = string
}

variable "schematic_nvidia_id" {
  type = string
}

variable "proxmox" {
  description = "Proxmox configuration"
  type = object({
    endpoint  = string
    insecure  = bool
    username  = string
    password  = string
    api_token = string
  })
  default   = null
  sensitive = true
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
  default   = null
  sensitive = true
}
