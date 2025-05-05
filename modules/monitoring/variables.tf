variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "cloudflare_tunnel_token_grafana" {
  description = "Cloudflare tunnel token for Grafana"
  type        = string
  sensitive   = true
}

variable "cloudflare_tunnel_token_wazuh" {
  description = "Cloudflare tunnel token for Wazuh"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Base domain name for services"
  type        = string
}

variable "grafana_subdomain" {
  description = "Subdomain for Grafana dashboard"
  type        = string
}

variable "wazuh_subdomain" {
  description = "Subdomain for Wazuh dashboard"
  type        = string
}
