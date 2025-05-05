resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "monitoring" = "true"
    }
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "7.0.6"  # Updated version

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

  depends_on = [kubernetes_namespace.monitoring]
}

# Add Prometheus for comprehensive monitoring
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "45.9.1"
  
  values = [
    file("${path.module}/values/prometheus-values.yaml")
  ]
  
  depends_on = [kubernetes_namespace.monitoring]
}

# Add Velero for backup and disaster recovery
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "2.32.6"

  values = [
    templatefile("${path.module}/values/velero-values.yaml", {})
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Add resource quotas for teaching resource management
resource "kubernetes_resource_quota" "student_quota" {
  metadata {
    name = "student-quota"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
      "pods"            = "10"
    }
  }
}

# Add ConfigMap for lab documentation
resource "kubernetes_config_map" "lab_documentation" {
  metadata {
    name      = "lab-guide"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "instructions.md" = file("${path.module}/docs/lab_instructions.md")
    "architecture.md" = file("${path.module}/docs/architecture.md")
    "exercises.md"    = file("${path.module}/docs/exercises.md")
  }
}