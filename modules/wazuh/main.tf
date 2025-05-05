resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = "wazuh"
  }
}

# Using the raw Kubernetes manifests approach is more reliable since there's no official Helm chart
resource "null_resource" "deploy_wazuh" {
  depends_on = [kubernetes_namespace.wazuh]

  provisioner "local-exec" {
    command = <<-EOT
      git clone https://github.com/wazuh/wazuh-kubernetes.git -b v4.5.1 --depth=1
      cd wazuh-kubernetes
      kubectl apply -f wazuh/base/
      kubectl apply -f wazuh/indexer_stack/
      kubectl apply -f wazuh/manager/
    EOT
  }
}