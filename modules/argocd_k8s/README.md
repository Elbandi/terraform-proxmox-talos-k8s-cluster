<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.app_of_apps_manifest](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_secret.git_repository](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_resources.applications_argoproj_io](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/resources) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd"></a> [argocd](#input\_argocd) | ArgoCD configuration | <pre>object({<br/>    admin_password = string<br/>    namespace      = string<br/>    chart_version  = string<br/>  })</pre> | n/a | yes |
| <a name="input_git_credentials"></a> [git\_credentials](#input\_git\_credentials) | Git repository credentials | <pre>object({<br/>    username = string<br/>    password = string<br/>  })</pre> | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | Git repo and path to the ArgoCD Applications | <pre>object({<br/>    name          = string<br/>    repo_url      = string<br/>    branch        = optional(string, "main")<br/>    manifest_path = string<br/>    project_name  = optional(string, "default")<br/>    recurse       = optional(bool, true)<br/>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->