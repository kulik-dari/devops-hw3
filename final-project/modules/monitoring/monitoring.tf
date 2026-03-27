resource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "57.2.0"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false
  timeout          = 600

  values = [<<-EOT
    grafana:
      enabled: true
      service:
        type: LoadBalancer
      adminPassword: "admin123"
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
            - name: default
              orgId: 1
              folder: ""
              type: file
              disableDeletion: false
              editable: true
              options:
                path: /var/lib/grafana/dashboards/default
      dashboards:
        default:
          kubernetes-cluster:
            gnetId: 7249
            revision: 1
            datasource: Prometheus
          node-exporter:
            gnetId: 1860
            revision: 37
            datasource: Prometheus

    prometheus:
      prometheusSpec:
        retention: 7d
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: gp2
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 10Gi

    alertmanager:
      enabled: true

    nodeExporter:
      enabled: true

    kubeStateMetrics:
      enabled: true
  EOT
  ]

  depends_on = [kubernetes_namespace.monitoring]
}
