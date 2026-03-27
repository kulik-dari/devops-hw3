resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.7.3"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  timeout          = 600

  values = [templatefile("${path.module}/values.yaml", {
    github_repo_url = var.github_repo_url
  })]

  depends_on = [kubernetes_namespace.argocd]
}

# Deploy ArgoCD Application via Helm chart
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  timeout   = 300

  set {
    name  = "application.repoURL"
    value = var.github_repo_url
  }

  set {
    name  = "application.ecrRepoURL"
    value = var.ecr_repo_url
  }

  depends_on = [helm_release.argocd]
}
