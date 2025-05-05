resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = "wazuh"
  }
}

# Option 1: Use a community Helm chart
resource "helm_release" "wazuh" {
  name       = "wazuh"
  repository = "https://artifacthub.io/packages/helm/wazuh-manager-filebeat/wazuh-manager-filebeat"  # Use a community chart
  chart      = "wazuh-manager-filebeat"
  namespace  = kubernetes_namespace.wazuh.metadata[0].name
  version    = "0.1.0"  # Use latest version available

  values = [
    file("${path.module}/values/wazuh-values.yaml")
  ]

  depends_on = [kubernetes_namespace.wazuh]
}

# Option 2 (alternative): You might need to use Kubernetes manifests directly if the Helm chart doesn't work
# resource "null_resource" "deploy_wazuh" {
#   depends_on = [kubernetes_namespace.wazuh]
#
#   provisioner "local-exec" {
#     command = <<-EOT
#       git clone https://github.com/wazuh/wazuh-kubernetes.git -b v4.5.1 --depth=1
#       cd wazuh-kubernetes
#       kubectl apply -f wazuh/base/
#       kubectl apply -f wazuh/indexer_stack/
#       kubectl apply -f wazuh/manager/
#     EOT
#   }
# }