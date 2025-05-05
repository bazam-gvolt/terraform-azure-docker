resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "6.50.7"
  timeout    = 900  # Increase timeout to 15 minutes
  wait       = false  # Don't wait for all resources to be ready

  values = [
    templatefile("${path.module}/values/grafana-values.yaml", {
      GRAFANA_ADMIN_PASSWORD = var.grafana_admin_password
    })
  ]

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }
  
  # Add resource configurations directly
  set {
    name  = "resources.requests.cpu"
    value = "200m"
  }
  
  set {
    name  = "resources.requests.memory"
    value = "500Mi"
  }
  
  set {
    name  = "resources.limits.cpu"
    value = "500m"
  }
  
  set {
    name  = "resources.limits.memory"
    value = "1Gi"
  }

  depends_on = [kubernetes_namespace.monitoring]
}