variable "argocd" {
  description = "ArgoCD configuration"
  type = object({
    admin_password = string
    namespace      = string
    chart_version  = string
  })
  sensitive = true
}

variable "repo" {
  description = "Git repo and path to the ArgoCD Applications"
  type = object({
    name          = string
    repo_url      = string
    branch        = optional(string, "main")
    manifest_path = string
    project_name  = optional(string, "default")
    recurse       = optional(bool, true)
  })
}

variable "git_credentials" {
  description = "Git repository credentials"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}
