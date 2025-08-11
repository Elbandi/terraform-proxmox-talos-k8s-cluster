<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_talos_k8s_cluster"></a> [talos\_k8s\_cluster](#module\_talos\_k8s\_cluster) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_proxmox"></a> [proxmox](#input\_proxmox) | Proxmox configuration | <pre>object({<br/>    endpoint  = string<br/>    insecure  = bool<br/>    username  = string<br/>    password  = string<br/>    api_token = string<br/>  })</pre> | `null` | no |
| <a name="input_schematic_id"></a> [schematic\_id](#input\_schematic\_id) | n/a | `string` | n/a | yes |
| <a name="input_schematic_nvidia_id"></a> [schematic\_nvidia\_id](#input\_schematic\_nvidia\_id) | n/a | `string` | n/a | yes |
| <a name="input_vmware"></a> [vmware](#input\_vmware) | VmWare configuration | <pre>object({<br/>    endpoint        = optional(string)<br/>    insecure        = optional(bool)<br/>    username        = optional(string)<br/>    password        = optional(string)<br/>    datacenter      = optional(string)<br/>    content_library = optional(string, "vHosting-ISO")<br/>    cluster         = optional(string)<br/>    folder          = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name |
| <a name="output_config_ipv4_addresses"></a> [config\_ipv4\_addresses](#output\_config\_ipv4\_addresses) | IPv4 addresses |
| <a name="output_schematic_id"></a> [schematic\_id](#output\_schematic\_id) | n/a |
| <a name="output_schematic_nvidia_id"></a> [schematic\_nvidia\_id](#output\_schematic\_nvidia\_id) | n/a |
<!-- END_TF_DOCS -->