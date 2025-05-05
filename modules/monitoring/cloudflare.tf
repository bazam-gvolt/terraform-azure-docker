resource "helm_release" "cloudflared_grafana" {
  name       = "cloudflared-grafana"
  repository = "https://cloudflare.github.io/helm-charts"
  chart      = "cloudflared"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "0.5.0"
  timeout    = 600

  values = [
    templatefile("${path.module}/values/cloudflare-grafana-values.yaml", {
      CLOUDFLARE_TUNNEL_TOKEN_GRAFANA = var.cloudflare_tunnel_token_grafana
      GRAFANA_SUBDOMAIN               = var.grafana_subdomain
      DOMAIN_NAME                     = var.domain_name
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "cloudflared_wazuh" {
  name       = "cloudflared-wazuh"
  repository = "https://cloudflare.github.io/helm-charts"
  chart      = "cloudflared"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "0.5.0"
  timeout    = 600

  values = [
    templatefile("${path.module}/values/cloudflare-wazuh-values.yaml", {
      CLOUDFLARE_TUNNEL_TOKEN_WAZUH = var.cloudflare_tunnel_token_wazuh
      WAZUH_SUBDOMAIN               = var.wazuh_subdomain
      DOMAIN_NAME                   = var.domain_name
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}