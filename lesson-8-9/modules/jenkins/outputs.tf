output "jenkins_url" {
  value = "http://${helm_release.jenkins.status == "deployed" ? "pending" : "unknown"}:8080"
  description = "Run: kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
