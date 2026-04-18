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
  sensitive = true
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
}

variable "git_credentials" {
  description = "Git repository credentials"
  type = object({
    username    = string
    password    = optional(string)
    private_key = optional(string)
  })
  sensitive = true
}
