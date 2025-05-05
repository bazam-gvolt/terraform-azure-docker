# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "purpose" = "monitoring"
    }
  }
}

# Instead of using Helm for Grafana, we'll use a Kubernetes deployment directly
# This gives us more control over resource limits for all containers
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "grafana"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        init_container {
          name  = "init-chown-data"
          image = "busybox:1.35"
          
          # Add explicit resource limits for init container
          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
          
          command = ["sh", "-c", "chown -R 472:472 /var/lib/grafana"]
          
          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }
        }

        container {
          name  = "grafana"
          image = "grafana/grafana:9.3.6"
          
          # Add explicit resource limits for main container
          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "500Mi"
            }
          }
          
          port {
            container_port = 3000
            name           = "http-grafana"
            protocol       = "TCP"
          }

          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = var.grafana_admin_password
          }
          
          env {
            name  = "GF_INSTALL_PLUGINS"
            value = "grafana-clock-panel,grafana-simple-json-datasource"
          }

          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }
        }

        volume {
          name = "grafana-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.grafana_pvc.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_persistent_volume_claim.grafana_pvc
  ]
}

# Create persistent volume claim for Grafana
resource "kubernetes_persistent_volume_claim" "grafana_pvc" {
  metadata {
    name      = "grafana-storage"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "managed-premium"
  }
  depends_on = [kubernetes_namespace.monitoring]
}

# Create Grafana service
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    selector = {
      app = "grafana"
    }
    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
  depends_on = [kubernetes_deployment.grafana]
}

# Configure Grafana datasources through ConfigMap
resource "kubernetes_config_map" "grafana_datasources" {
  metadata {
    name      = "grafana-datasources"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "grafana"
    }
  }

  data = {
    "datasources.yaml" = <<-EOF
      apiVersion: 1
      datasources:
      - name: Wazuh
        type: elasticsearch
        url: http://wazuh-indexer-indexer:9200
        database: wazuh-*
        jsonData:
          timeField: "@timestamp"
          esVersion: "7.10.2"
    EOF
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

# For Wazuh deployment, we need to create the resources directly
resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = "wazuh"
  }
}

# We'll create the Wazuh resources directly using kubectl apply
resource "null_resource" "deploy_wazuh" {
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/wazuh-temp
      cd ${path.module}/wazuh-temp
      git clone https://github.com/wazuh/wazuh-kubernetes.git -b v4.5.1 --depth=1
      cd wazuh-kubernetes
      kubectl apply -f wazuh/base/
      kubectl apply -f wazuh/indexer_stack/
      kubectl apply -f wazuh/manager/
    EOT
  }

  depends_on = [kubernetes_namespace.wazuh]
}