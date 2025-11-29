## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >=3.5.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >=0.78.1 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >=0.13.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | >=3.5.0 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >=0.78.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_download_file.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) | resource |
| [http_http.schematic_id](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.schematic_nvidia_id](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Cluster configuration | <pre>object({<br/>    network_dhcp          = optional(bool, false)<br/>    gateway               = string<br/>    dns_domain            = optional(string)<br/>    dns_servers           = optional(list(string))<br/>    cidr                  = number<br/>    vlan_id               = optional(number, null)<br/>    network_device_bridge = optional(string, "vmbr0")<br/>    name                  = string<br/>    talos_version         = optional(string, "v1.10.3")<br/>  })</pre> | n/a | yes |
| <a name="input_pci"></a> [pci](#input\_pci) | Configuration mapping PCI | <pre>map(object({<br/>    name         = string<br/>    id           = string<br/>    iommu_group  = number<br/>    node         = string<br/>    path         = string<br/>    subsystem_id = string<br/>  }))</pre> | `null` | no |
| <a name="input_proxmox"></a> [proxmox](#input\_proxmox) | Proxmox configuration | <pre>object({<br/>    endpoint           = string<br/>    insecure           = bool<br/>    username           = string<br/>    password           = optional(string)<br/>    realm              = optional(string, "pam")<br/>    api_token          = optional(string)<br/>    ssh_agent          = optional(string, false)<br/>    random_vm_ids      = optional(string, false)<br/>    random_vm_id_start = optional(number, 1000)<br/>    random_vm_id_end   = optional(number, 2000)<br/>    iso_datastore_id   = optional(string, "local")<br/>  })</pre> | n/a | yes |
| <a name="input_vms"></a> [vms](#input\_vms) | Configuration for cluster nodes | <pre>map(object({<br/>    host_node        = string<br/>    machine_type     = string<br/>    vm_id            = optional(number)<br/>    datastore_id     = optional(string, "local-lvm")<br/>    ip               = string<br/>    cpu              = number<br/>    ram_dedicated    = number<br/>    os_disk_size     = number<br/>    data_disks       = optional(list(object({<br/>      size = number<br/>      type = optional(string)<br/>      dev  = optional(string)<br/>      name = optional(string)<br/>    })), [])<br/>    disk_file_format = optional(string, "raw")<br/>    gpu              = optional(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aaa"></a> [aaa](#output\_aaa) | n/a |
| <a name="output_schematic_id"></a> [schematic\_id](#output\_schematic\_id) | n/a |
| <a name="output_schematic_nvidia_id"></a> [schematic\_nvidia\_id](#output\_schematic\_nvidia\_id) | n/a |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >=3.5.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >=0.78.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | >=3.5.0 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >=0.78.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_download_file.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) | resource |
| [http_http.schematic_id](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Cluster configuration | <pre>object({<br/>    name          = string<br/>    talos_version = string<br/>  })</pre> | n/a | yes |
| <a name="input_proxmox"></a> [proxmox](#input\_proxmox) | Proxmox configuration | <pre>object({<br/>    endpoint           = string<br/>    insecure           = bool<br/>    username           = string<br/>    password           = optional(string)<br/>    realm              = optional(string, "pam")<br/>    api_token          = optional(string)<br/>    ssh_agent          = optional(string, false)<br/>    random_vm_ids      = optional(string, false)<br/>    random_vm_id_start = optional(number, 1000)<br/>    random_vm_id_end   = optional(number, 2000)<br/>    iso_datastore_id   = optional(string, "local")<br/>  })</pre> | n/a | yes |
| <a name="input_vms"></a> [vms](#input\_vms) | Configuration for cluster nodes | <pre>map(object({<br/>    host_node        = string<br/>    talos_extensions = optional(list(string), [])<br/>    schematic_id     = optional(string, "")<br/>    gpu              = optional(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_schematic_ids"></a> [schematic\_ids](#output\_schematic\_ids) | n/a |
<!-- END_TF_DOCS -->