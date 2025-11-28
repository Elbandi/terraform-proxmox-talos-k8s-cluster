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
    pool               = optional(string)
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
    pool            = optional(string)
  })
  default   = null
  sensitive = true
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name                               = string
    id                                 = optional(number, 0)
    talos_version                      = optional(string, "v1.12.4")
    kubernetes_version                 = optional(string)
    network_dhcp                       = optional(bool, false)
    gateway                            = optional(string)
    dns_domain                         = optional(string)
    dns_servers                        = optional(list(string))
    cidr                               = optional(number)
    vlan_id                            = optional(number, null)
    network_device_bridge              = optional(string, "vmbr0")
    endpoint                           = optional(string)
    allow_scheduling_on_control_planes = optional(bool, true)
    vip_ip                             = optional(string)
    vip_interface                      = optional(string, "eth0")
    lvm_label_node                     = optional(bool, true)
    cni                                = optional(string, "cilium")
    pod_subnet                         = optional(string, "10.244.0.0/16")
    service_subnet                     = optional(string, "10.96.0.0/12")
    mtu                                = optional(number, 1450)
    cloud_provider                     = optional(string, "none")
    extra_hosts                        = optional(map(list(string)))
    registries = optional(map(object({
      username = string
      password = string
    })), {})
  })
}

variable "vms" {
  description = "VMs configuration"
  type = map(object({
    host_node             = string
    vm_id                 = optional(number)
    machine_type          = string
    additional_extensions = optional(list(string), [])
    schematic_id          = optional(string, "")
    datastore_id          = optional(string, "local-lvm")
    ip                    = optional(string)
    bios                  = optional(string, "uefi")
    cpu                   = number
    numa                  = optional(bool, true)
    memory_dedicated      = number
    swap_size             = optional(number, 0)
    system_disk = object({
      size      = optional(number, 10)
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
    install_disk = optional(string, "/dev/sda")
    extra_mounts = optional(list(object({
      destination = string
      type        = string
      source      = string
      options     = optional(list(string), [])
    })), [])
    disk_file_format = optional(string, "raw")
    gpu              = optional(string)
    time_server      = optional(string)
    kernel_modules   = optional(list(string), [])
    node_labels      = optional(map(any), {})
    custom_network   = optional(string)
  }))
}

variable "pci" {
  description = "Mapping PCI configuration"
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
    namespace      = string
    chart_version  = string
    domain         = string
    admin_password = string
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
