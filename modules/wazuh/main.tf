resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = "wazuh"
  }
}

# Use a simple helm release as a placeholder for Wazuh
# In a real environment, we would either:
# 1. Ensure kubectl is available on the Terraform worker
# 2. Use a Helm chart for Wazuh
# 3. Use Kubernetes manifest resources directly in Terraform
resource "helm_release" "wazuh" {
  name       = "wazuh"
  chart      = "https://github.com/morgoved/wazuh-helm/releases/download/v0.1.0/wazuh-0.1.0.tgz"
  namespace  = kubernetes_namespace.wazuh.metadata[0].name
  timeout    = 600

  values = [
    file("${path.module}/values/wazuh-values.yaml")
  ]

  depends_on = [kubernetes_namespace.wazuh]
}