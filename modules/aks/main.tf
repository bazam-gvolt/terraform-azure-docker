resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.location_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.location_prefix}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name            = "system"
    node_count      = var.node_count
    vm_size         = var.vm_size
    vnet_subnet_id  = var.subnet_id
    tags            = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/16"
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"
  }

  azure_policy_enabled = true
  role_based_access_control_enabled = true

  api_server_access_profile {
    authorized_ip_ranges = var.api_authorized_ranges
  }

  microsoft_defender {
    enabled = true
  }

  monitor_metrics {
    enabled = var.enable_monitoring
  }

  tags = var.tags
}