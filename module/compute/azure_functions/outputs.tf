# Storage Account Outputs
output "storage_account_id" {
  description = "ID da Storage Account"
  value       = azurerm_storage_account.function.id
}

output "storage_account_name" {
  description = "Nome da Storage Account"
  value       = azurerm_storage_account.function.name
}

output "storage_account_primary_access_key" {
  description = "Primary access key da Storage Account"
  value       = azurerm_storage_account.function.primary_access_key
  sensitive   = true
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string da Storage Account"
  value       = azurerm_storage_account.function.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Endpoint primário do Blob Storage"
  value       = azurerm_storage_account.function.primary_blob_endpoint
}

# Service Plan Outputs
output "service_plan_id" {
  description = "ID do Service Plan"
  value       = azurerm_service_plan.function.id
}

output "service_plan_name" {
  description = "Nome do Service Plan"
  value       = azurerm_service_plan.function.name
}

output "service_plan_sku" {
  description = "SKU do Service Plan"
  value       = azurerm_service_plan.function.sku_name
}

# Function App Outputs
output "function_app_id" {
  description = "ID da Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
}

output "function_app_name" {
  description = "Nome da Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].name : azurerm_windows_function_app.main[0].name
}

output "function_app_default_hostname" {
  description = "Hostname padrão da Function App (*.azurewebsites.net)"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].default_hostname : azurerm_windows_function_app.main[0].default_hostname
}

output "function_app_url" {
  description = "URL completa HTTPS da Function App"
  value       = var.os_type == "Linux" ? "https://${azurerm_linux_function_app.main[0].default_hostname}" : "https://${azurerm_windows_function_app.main[0].default_hostname}"
}

output "function_app_kind" {
  description = "Tipo da Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].kind : azurerm_windows_function_app.main[0].kind
}

output "function_app_outbound_ip_addresses" {
  description = "Endereços IP de saída da Function App"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].outbound_ip_addresses : azurerm_windows_function_app.main[0].outbound_ip_addresses
}

output "function_app_possible_outbound_ip_addresses" {
  description = "Possíveis endereços IP de saída"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].possible_outbound_ip_addresses : azurerm_windows_function_app.main[0].possible_outbound_ip_addresses
}

output "function_app_outbound_ip_address_list" {
  description = "Lista de endereços IP de saída"
  value       = var.os_type == "Linux" ? split(",", azurerm_linux_function_app.main[0].outbound_ip_addresses) : split(",", azurerm_windows_function_app.main[0].outbound_ip_addresses)
}

# Managed Identity Outputs
output "function_app_identity_principal_id" {
  description = "Principal ID da Managed Identity (System Assigned)"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity[0].principal_id : azurerm_windows_function_app.main[0].identity[0].principal_id) : null
}

output "function_app_identity_tenant_id" {
  description = "Tenant ID da Managed Identity"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity[0].tenant_id : azurerm_windows_function_app.main[0].identity[0].tenant_id) : null
}

output "function_app_identity" {
  description = "Objeto completo de identidade"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity : azurerm_windows_function_app.main[0].identity) : null
}

# Site Credentials
output "function_app_site_credential" {
  description = "Credenciais do site para deployment"
  value = var.os_type == "Linux" ? {
    name     = azurerm_linux_function_app.main[0].site_credential[0].name
    password = azurerm_linux_function_app.main[0].site_credential[0].password
  } : {
    name     = azurerm_windows_function_app.main[0].site_credential[0].name
    password = azurerm_windows_function_app.main[0].site_credential[0].password
  }
  sensitive = true
}

# Deployment Slot Outputs
output "deployment_slot_ids" {
  description = "IDs dos deployment slots"
  value       = var.os_type == "Linux" && var.deployment_slots != null ? { for k, v in azurerm_linux_function_app_slot.main : k => v.id } : {}
}

output "deployment_slot_hostnames" {
  description = "Hostnames dos deployment slots"
  value       = var.os_type == "Linux" && var.deployment_slots != null ? { for k, v in azurerm_linux_function_app_slot.main : k => v.default_hostname } : {}
}

# Application Insights Outputs
output "application_insights_id" {
  description = "ID do Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.function[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation Key do Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.function[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection String do Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.function[0].connection_string : null
  sensitive   = true
}

output "application_insights_app_id" {
  description = "App ID do Application Insights"
  value       = var.create_application_insights ? azurerm_application_insights.function[0].app_id : null
}

# VNet Integration
output "vnet_integration_enabled" {
  description = "Indica se VNet integration está habilitada"
  value       = var.vnet_integration_subnet_id != null
}

# Storage Queues
output "storage_queue_names" {
  description = "Nomes das Storage Queues criadas"
  value       = [for q in azurerm_storage_queue.triggers : q.name]
}

output "storage_queue_ids" {
  description = "IDs das Storage Queues"
  value       = { for k, v in azurerm_storage_queue.triggers : k => v.id }
}

# Storage Containers
output "storage_container_names" {
  description = "Nomes dos Storage Containers criados"
  value       = [for c in azurerm_storage_container.triggers : c.name]
}

output "storage_container_ids" {
  description = "IDs dos Storage Containers"
  value       = { for k, v in azurerm_storage_container.triggers : k => v.id }
}

# Complete Function App Info
output "function_app_info" {
  description = "Informações completas da Function App"
  value = {
    id                      = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
    name                    = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].name : azurerm_windows_function_app.main[0].name
    default_hostname        = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].default_hostname : azurerm_windows_function_app.main[0].default_hostname
    os_type                 = var.os_type
    sku                     = azurerm_service_plan.function.sku_name
    location                = var.location
    resource_group          = var.resource_group_name
    runtime                 = var.functions_worker_runtime
    runtime_version         = var.functions_extension_version
    https_only              = var.https_only
    identity_enabled        = var.identity_type != null
    application_insights_id = var.create_application_insights ? azurerm_application_insights.function[0].id : null
  }
}

# Master Key (para chamar admin endpoints)
output "function_app_master_key" {
  description = "Master key da Function App (para admin operations)"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].site_credential[0].password : azurerm_windows_function_app.main[0].site_credential[0].password
  sensitive   = true
}

# Custom Handler (se aplicável)
output "function_app_custom_domain_verification_id" {
  description = "ID de verificação para custom domains"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].custom_domain_verification_id : azurerm_windows_function_app.main[0].custom_domain_verification_id
}
