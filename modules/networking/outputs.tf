output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "firewall_id" {
  value = azurerm_firewall.main.id
}

output "firewall_private_ip" {
  value = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}