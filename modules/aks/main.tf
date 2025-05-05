resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.location_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.location_prefix}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  private_cluster_enabled = true

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = var.subnet_id
    tags                = var.tags
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    os_disk_size_gb     = 50
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
    outbound_type      = "loadBalancer"  # Changed from userDefinedRouting
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

# Add disk encryption set (optional, requires Key Vault setup)
resource "azurerm_key_vault" "aks_kv" {
  name                        = "kv-aks-${var.location_prefix}-${var.environment}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Create", "Delete", "List", "Restore", "Recover", "UnwrapKey", "WrapKey",
      "Purge", "Encrypt", "Decrypt", "Sign", "Verify", "GetRotationPolicy", "SetRotationPolicy"
    ]
  }
}

resource "azurerm_key_vault_key" "aks_encryption_key" {
  name         = "aks-encryption-key"
  key_vault_id = azurerm_key_vault.aks_kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

data "azurerm_client_config" "current" {}