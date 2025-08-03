
resource "helm_release" "argocd" {
  name             = "argo-cd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = var.argocd.namespace
  create_namespace = true
  version          = var.argocd.chart_version

  values = [templatefile("${path.module}/config/argocd-helm-values.yaml.tmpl", {
    argocd = var.argocd,
    repo   = var.repo,
  })]
  timeout = 180
  wait    = true
}

# Git repository secret létrehozása
resource "kubernetes_secret" "git_repository" {
  depends_on = [helm_release.argocd]

  metadata {
    name      = var.repo.name
    namespace = var.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    type          = "git"
    name          = var.repo.name
    url           = var.repo.repo_url
    username      = var.git_credentials.username
    password      = var.git_credentials.password
    sshPrivateKey = var.git_credentials.private_key
    #    project  = var.git_credentials.project # TODO: miez?
  }

  type = "Opaque"
}

resource "helm_release" "argocd-app" {
  name             = "argocd-app"
  chart            = "argocd-apps"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = var.argocd.namespace
  create_namespace = true
  version          = "2.0.2"

  values = [yamlencode({
    applications = {
      (var.repo.name) = {
        namespace = var.argocd.namespace
        finalizers = [
          "resources-finalizer.argocd.argoproj.io"
        ],
        destination = {
          namespace = var.argocd.namespace
          server    = "https://kubernetes.default.svc"
        }
        project = var.repo.project_name
        source = {
          directory = {
            recurse = var.repo.recurse
          }
          path           = var.repo.manifest_path
          repoURL        = var.repo.repo_url
          targetRevision = var.repo.branch
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
          retry = {
            backoff = {
              duration    = "5s"
              factor      = 2
              maxDuration = "3m"
            }
            limit = 5
          }
          syncOptions = [
            "CreateNamespace=true",
            "PrunePropagationPolicy=foreground",
            "PruneLast=true",
          ]
        }
      }
    }
  })]
  timeout    = 180
  wait       = true
  depends_on = [helm_release.argocd, kubernetes_secret.git_repository]
}
