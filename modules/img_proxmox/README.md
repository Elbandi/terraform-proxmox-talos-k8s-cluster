<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.5 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.95 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | 3.5.0 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.98.1 |

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
| <a name="input_vms"></a> [vms](#input\_vms) | Configuration for cluster nodes | <pre>map(object({<br/>    host_node             = string<br/>    additional_extensions = optional(list(string), [])<br/>    datastore_id          = optional(string, "local-lvm")<br/>    gpu                   = optional(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_schematic_ids"></a> [schematic\_ids](#output\_schematic\_ids) | n/a |
<!-- END_TF_DOCS -->