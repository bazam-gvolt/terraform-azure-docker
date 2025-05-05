# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "purpose" = "monitoring"
    }
  }
}

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

  depends_on = [kubernetes_namespace.monitoring]
}

# Create ConfigMap for lab documentation
resource "kubernetes_config_map" "lab_documentation" {
  metadata {
    name      = "lab-guide"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "instructions.md" = "# RedDome Lab - Student Instructions\n\nThis is a placeholder for detailed lab instructions. Replace with actual content."
    "architecture.md" = "# RedDome Lab - Architecture\n\nThis is a placeholder for architecture documentation. Replace with actual content."
    "exercises.md"    = "# RedDome Lab - Exercises\n\nThis is a placeholder for lab exercises. Replace with actual content."
  }

  depends_on = [kubernetes_namespace.monitoring]
}