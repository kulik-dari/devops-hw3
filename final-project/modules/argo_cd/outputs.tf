output "argocd_url" {
  value       = "Run: kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
  description = "ArgoCD server URL"
}
