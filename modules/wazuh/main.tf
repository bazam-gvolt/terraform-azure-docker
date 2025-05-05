resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = "wazuh"
  }
}

resource "helm_release" "wazuh" {
  name       = "wazuh"
  repository = "https://wazuh.github.io/helm"
  chart      = "wazuh"
  namespace  = kubernetes_namespace.wazuh.metadata[0].name
  version    = "4.5.1"

  values = [
    file("${path.module}/values/wazuh-values.yaml")
  ]

  depends_on = [kubernetes_namespace.wazuh]
}