# Service Plan Outputs
output "service_plan_id" {
  description = "ID do App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "service_plan_name" {
  description = "Nome do App Service Plan"
  value       = azurerm_service_plan.main.name
}

output "service_plan_kind" {
  description = "Tipo do App Service Plan"
  value       = azurerm_service_plan.main.kind
}

output "service_plan_sku" {
  description = "SKU do App Service Plan"
  value       = azurerm_service_plan.main.sku_name
}

# App Service Outputs
output "app_service_id" {
  description = "ID do App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
}

output "app_service_name" {
  description = "Nome do App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
}

output "app_service_default_hostname" {
  description = "Hostname padrão do App Service (*.azurewebsites.net)"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname
}

output "app_service_url" {
  description = "URL completa do App Service"
  value       = var.os_type == "Linux" ? "https://${azurerm_linux_web_app.main[0].default_hostname}" : "https://${azurerm_windows_web_app.main[0].default_hostname}"
}

output "app_service_outbound_ip_addresses" {
  description = "Endereços IP de saída do App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].outbound_ip_addresses : azurerm_windows_web_app.main[0].outbound_ip_addresses
}

output "app_service_possible_outbound_ip_addresses" {
  description = "Possíveis endereços IP de saída"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].possible_outbound_ip_addresses : azurerm_windows_web_app.main[0].possible_outbound_ip_addresses
}

output "app_service_outbound_ip_address_list" {
  description = "Lista de endereços IP de saída"
  value       = var.os_type == "Linux" ? split(",", azurerm_linux_web_app.main[0].outbound_ip_addresses) : split(",", azurerm_windows_web_app.main[0].outbound_ip_addresses)
}

# Identity Outputs
output "app_service_identity_principal_id" {
  description = "Principal ID da Managed Identity (System Assigned)"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_web_app.main[0].identity[0].principal_id : azurerm_windows_web_app.main[0].identity[0].principal_id) : null
}

output "app_service_identity_tenant_id" {
  description = "Tenant ID da Managed Identity"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_web_app.main[0].identity[0].tenant_id : azurerm_windows_web_app.main[0].identity[0].tenant_id) : null
}

output "app_service_identity" {
  description = "Objeto completo de identidade"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_web_app.main[0].identity : azurerm_windows_web_app.main[0].identity) : null
}

# Custom Domain Outputs
output "custom_domain_bindings" {
  description = "Mapa de custom domain bindings"
  value       = { for k, v in azurerm_app_service_custom_hostname_binding.main : k => v.hostname }
}

# Deployment Slot Outputs
output "deployment_slot_ids" {
  description = "IDs dos deployment slots"
  value       = var.os_type == "Linux" && var.deployment_slots != null ? { for k, v in azurerm_linux_web_app_slot.main : k => v.id } : {}
}

output "deployment_slot_hostnames" {
  description = "Hostnames dos deployment slots"
  value       = var.os_type == "Linux" && var.deployment_slots != null ? { for k, v in azurerm_linux_web_app_slot.main : k => v.default_hostname } : {}
}

# VNet Integration Output
output "vnet_integration_enabled" {
  description = "Indica se VNet integration está habilitada"
  value       = var.vnet_integration_subnet_id != null
}

# Site Credentials (para deployment)
output "app_service_site_credential" {
  description = "Credenciais do site para deployment"
  value = var.os_type == "Linux" ? {
    name     = azurerm_linux_web_app.main[0].site_credential[0].name
    password = azurerm_linux_web_app.main[0].site_credential[0].password
  } : {
    name     = azurerm_windows_web_app.main[0].site_credential[0].name
    password = azurerm_windows_web_app.main[0].site_credential[0].password
  }
  sensitive = true
}

# Kind (tipo de App Service)
output "app_service_kind" {
  description = "Tipo do App Service (app, functionapp, etc)"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].kind : azurerm_windows_web_app.main[0].kind
}

# Complete App Service Info
output "app_service_info" {
  description = "Informações completas do App Service"
  value = {
    id               = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
    name             = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
    default_hostname = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname
    os_type          = var.os_type
    sku              = azurerm_service_plan.main.sku_name
    location         = var.location
    resource_group   = var.resource_group_name
    https_only       = var.https_only
    identity_enabled = var.identity_type != null
  }
}

# FTP/FTPS Details
output "app_service_ftp_details" {
  description = "Detalhes de FTP/FTPS"
  value = {
    hostname = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname
    username = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].site_credential[0].name : azurerm_windows_web_app.main[0].site_credential[0].name
  }
  sensitive = true
}
