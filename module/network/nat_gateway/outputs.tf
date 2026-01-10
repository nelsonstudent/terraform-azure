output "id" {
  description = "ID do NAT Gateway"
  value       = azurerm_nat_gateway.main.id
}

output "name" {
  description = "Nome do NAT Gateway"
  value       = azurerm_nat_gateway.main.name
}

output "resource_guid" {
  description = "GUID do recurso NAT Gateway"
  value       = azurerm_nat_gateway.main.resource_guid
}

output "location" {
  description = "Localização do NAT Gateway"
  value       = azurerm_nat_gateway.main.location
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_nat_gateway.main.resource_group_name
}

output "sku_name" {
  description = "SKU do NAT Gateway"
  value       = azurerm_nat_gateway.main.sku_name
}

output "idle_timeout_in_minutes" {
  description = "Timeout de idle configurado"
  value       = azurerm_nat_gateway.main.idle_timeout_in_minutes
}

output "zones" {
  description = "Availability Zones configuradas"
  value       = azurerm_nat_gateway.main.zones
}

output "public_ip_prefix_id" {
  description = "ID do Public IP Prefix (se criado)"
  value       = try(azurerm_public_ip_prefix.main[0].id, null)
}

output "public_ip_prefix" {
  description = "Objeto completo do Public IP Prefix"
  value       = try(azurerm_public_ip_prefix.main[0], null)
}

output "public_ip_ids" {
  description = "IDs dos Public IPs criados"
  value       = [for ip in azurerm_public_ip.main : ip.id]
}

output "public_ip_addresses" {
  description = "Endereços IP públicos atribuídos"
  value       = [for ip in azurerm_public_ip.main : ip.ip_address]
}

output "public_ips" {
  description = "Objetos completos dos Public IPs"
  value = {
    for idx, ip in azurerm_public_ip.main : ip.name => {
      id         = ip.id
      ip_address = ip.ip_address
      fqdn       = ip.fqdn
    }
  }
}

output "all_public_ip_ids" {
  description = "Todos os IDs de Public IPs associados (criados + existentes)"
  value       = local.all_public_ip_ids
}

output "subnet_associations" {
  description = "Associações de subnets criadas"
  value = {
    for k, v in azurerm_subnet_nat_gateway_association.main : k => {
      id         = v.id
      subnet_id  = v.subnet_id
    }
  }
}

output "associated_subnet_ids" {
  description = "IDs das subnets associadas ao NAT Gateway"
  value       = var.subnet_ids
}

output "public_ip_associations" {
  description = "Associações de Public IPs"
  value = {
    for k, v in azurerm_nat_gateway_public_ip_association.main : k => {
      id                   = v.id
      public_ip_address_id = v.public_ip_address_id
    }
  }
}

output "diagnostic_setting_id" {
  description = "ID do Diagnostic Setting (se criado)"
  value       = try(azurerm_monitor_diagnostic_setting.main[0].id, null)
}

output "alert_ids" {
  description = "IDs dos alertas criados"
  value = {
    snat_ports = try(azurerm_monitor_metric_alert.snat_ports[0].id, null)
    data_path  = try(azurerm_monitor_metric_alert.data_path[0].id, null)
  }
}

output "capacity" {
  description = "Capacidade do NAT Gateway (portas SNAT por IP)"
  value = {
    public_ip_count      = length(local.all_public_ip_ids)
    ports_per_ip         = 64512
    total_snat_ports     = length(local.all_public_ip_ids) * 64512
    max_destinations     = length(local.all_public_ip_ids) * 64000
  }
}

output "nat_gateway_summary" {
  description = "Resumo do NAT Gateway"
  value = {
    id                      = azurerm_nat_gateway.main.id
    name                    = azurerm_nat_gateway.main.name
    location                = azurerm_nat_gateway.main.location
    sku                     = azurerm_nat_gateway.main.sku_name
    idle_timeout            = azurerm_nat_gateway.main.idle_timeout_in_minutes
    zones                   = azurerm_nat_gateway.main.zones
    public_ip_count         = length(local.all_public_ip_ids)
    total_snat_ports        = length(local.all_public_ip_ids) * 64512
    associated_subnets      = length(var.subnet_ids)
    diagnostic_enabled      = var.diagnostic_settings.enabled
    alerts_enabled          = var.alerts.enabled
  }
}

output "resource" {
  description = "Objeto completo do NAT Gateway"
  value       = azurerm_nat_gateway.main
  sensitive   = true
}