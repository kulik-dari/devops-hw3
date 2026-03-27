output "grafana_url" {
  value       = "Run: kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
  description = "Grafana URL"
}

output "prometheus_url" {
  value       = "Run: kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring"
  description = "Prometheus access via port-forward"
}
