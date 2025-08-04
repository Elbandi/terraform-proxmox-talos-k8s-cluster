variable "proxmox" {
  description = "Proxmox configuration"
  type = object({
    endpoint           = optional(string)
    insecure           = optional(bool)
    username           = optional(string)
    password           = optional(string)
    realm              = optional(string, "pam")
    api_token          = optional(string)
    ssh_agent          = optional(string, false)
    random_vm_ids      = optional(string, false)
    random_vm_id_start = optional(number, 1000)
    random_vm_id_end   = optional(number, 2000)
  })
  sensitive = true
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name                  = string
    talos_version         = optional(string, "v1.11.3")
    network_dhcp          = optional(bool, false)
    gateway               = optional(string)
    dns_domain            = optional(string)
    dns_servers           = optional(list(string))
    cidr                  = optional(number)
    vlan_id               = optional(number, null)
    network_device_bridge = optional(string, "vmbr0")
    endpoint              = optional(string)
    lvm_label_node        = optional(bool, true)
  })
}

variable "vms" {
  description = "VMs configuration"
  type = map(object({
    host_node     = string
    vm_id         = optional(number)
    machine_type  = string
    datastore_id  = optional(string, "local-lvm")
    ip            = optional(string)
    cpu           = number
    ram_dedicated = number
    os_disk_size  = optional(number, 10)
    data_disks = optional(list(object({
      size = number
      type = optional(string)
      dev  = optional(string)
      name = optional(string)
    })), [])
    install_disk     = optional(string, "/dev/sda")
    data_lvm         = optional(bool, false)
    disk_file_format = optional(string, "raw")
    gpu              = optional(string)
    time_server      = optional(string)
    kernel_modules   = optional(list(string), [])
  }))
}

variable "pci" {
  description = "Mapping PCI configuration"
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

variable "gitops" {
  description = "GitOps configuration"
  type = object({
    repository   = string
    token        = string
    cluster_name = string
  })
  default = null
}

variable "certificate" {
  description = "Certificate for k8s sealed-secrets"
  type = object({
    cert = string
    key  = string
  })
  default = null
}

variable "argocd" {
  description = "ArgoCD configuration"
  type = object({
    admin_password = string
    namespace      = string
    chart_version  = string
    oidc_config = optional(object({
      name             = string
      issuer           = string
      client_id        = string
      client_secret    = string
      requested_scopes = list(string)
    }))
    custom_rbac = optional(object({
      scopes = list(string)
      policy = list(string)
    }))
  })
  default = null
}

variable "repo" {
  description = "Git repo and path to the ArgoCD Applications"

  type = object({
    name            = string
    repo_url        = string
    branch          = optional(string, "main")
    manifest_path   = string
    project_name    = optional(string, "default")
    recurse         = optional(bool, true)
    ssh_known_hosts = optional(list(string))
  })
  default = null
}

variable "git_credentials" {
  type = object({
    username    = string
    password    = optional(string)
    private_key = optional(string)
  })
  description = "Git repository credentials"
  default     = null
  sensitive   = true
}
