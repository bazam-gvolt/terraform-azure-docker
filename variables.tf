variable "environment" {
  description = "Environment name (prd, dev, stg)"
  type        = string
  default     = "prd"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "location_prefix" {
  description = "Location prefix for naming"
  type        = string
  default     = "uks"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Security    = "High"
    Compliance  = "Required"
  }
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare tunnel token"
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

variable "api_authorized_ranges" {
  description = "Authorized IP ranges for K8s API access"
  type        = list(string)
  sensitive   = true
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor for containers"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Base domain name for services (e.g., your-domain.com)"
  type        = string
}

variable "wazuh_subdomain" {
  description = "Subdomain for Wazuh dashboard"
  type        = string
  default     = "wazuh"
}

variable "grafana_subdomain" {
  description = "Subdomain for Grafana dashboard"
  type        = string
  default     = "grafana"
}

resource "azurerm_kubernetes_cluster" "aks" {
  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    network_policy     = "calico"  // Add network policies
  }

  azure_policy_enabled = true
  
  microsoft_defender {
    enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  api_server_access_profile {
    authorized_ip_ranges = ["YOUR_IP_RANGE"]  // Restrict API server access
  }
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${var.location_prefix}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}