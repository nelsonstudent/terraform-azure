# Log Analytics Outputs
output "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : var.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Nome do Log Analytics Workspace"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].name : null
}

output "log_analytics_workspace_customer_id" {
  description = "Customer ID (Workspace ID) do Log Analytics"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].workspace_id : null
}

output "log_analytics_primary_shared_key" {
  description = "Primary Shared Key do Log Analytics"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].primary_shared_key : null
  sensitive   = true
}

# Container Apps Environment Outputs
output "environment_id" {
  description = "ID do Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}

output "environment_name" {
  description = "Nome do Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "environment_default_domain" {
  description = "Domínio padrão do Container Apps Environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "environment_static_ip_address" {
  description = "Endereço IP estático do Environment"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "environment_docker_bridge_cidr" {
  description = "CIDR da bridge Docker"
  value       = azurerm_container_app_environment.main.docker_bridge_cidr
}

output "environment_platform_reserved_cidr" {
  description = "CIDR reservado pela plataforma"
  value       = azurerm_container_app_environment.main.platform_reserved_cidr
}

output "environment_platform_reserved_dns_ip" {
  description = "IP DNS reservado pela plataforma"
  value       = azurerm_container_app_environment.main.platform_reserved_dns_ip_address
}

# Container App Outputs
output "container_app_id" {
  description = "ID do Container App"
  value       = azurerm_container_app.main.id
}

output "container_app_name" {
  description = "Nome do Container App"
  value       = azurerm_container_app.main.name
}

output "container_app_fqdn" {
  description = "FQDN (URL) do Container App"
  value       = azurerm_container_app.main.latest_revision_fqdn
}

output "container_app_url" {
  description = "URL completa HTTPS do Container App"
  value       = var.ingress_enabled ? "https://${azurerm_container_app.main.latest_revision_fqdn}" : null
}

output "container_app_latest_revision_name" {
  description = "Nome da última revisão"
  value       = azurerm_container_app.main.latest_revision_name
}

output "container_app_outbound_ip_addresses" {
  description = "Endereços IP de saída"
  value       = azurerm_container_app.main.outbound_ip_addresses
}

output "container_app_custom_domain_verification_id" {
  description = "ID de verificação para custom domains"
  value       = azurerm_container_app.main.custom_domain_verification_id
}

# Managed Identity Outputs
output "container_app_identity_principal_id" {
  description = "Principal ID da Managed Identity (System Assigned)"
  value       = var.identity_type != null ? azurerm_container_app.main.identity[0].principal_id : null
}

output "container_app_identity_tenant_id" {
  description = "Tenant ID da Managed Identity"
  value       = var.identity_type != null ? azurerm_container_app.main.identity[0].tenant_id : null
}

output "container_app_identity" {
  description = "Objeto completo de identidade"
  value       = var.identity_type != null ? azurerm_container_app.main.identity : null
}

# Ingress Outputs
output "ingress_fqdn" {
  description = "FQDN do ingress"
  value       = var.ingress_enabled ? azurerm_container_app.main.ingress[0].fqdn : null
}

output "ingress_traffic_weights" {
  description = "Distribuição de tráfego configurada"
  value       = var.ingress_enabled ? var.ingress_traffic_weights : null
}

# Environment Storage Outputs
output "environment_storage_ids" {
  description = "IDs dos storages do environment"
  value       = { for k, v in azurerm_container_app_environment_storage.main : k => v.id }
}

output "environment_storage_names" {
  description = "Nomes dos storages do environment"
  value       = { for k, v in azurerm_container_app_environment_storage.main : k => v.name }
}

# Certificate Outputs
output "certificate_ids" {
  description = "IDs dos certificados"
  value       = { for k, v in azurerm_container_app_environment_certificate.main : k => v.id }
}

output "certificate_names" {
  description = "Nomes dos certificados"
  value       = { for k, v in azurerm_container_app_environment_certificate.main : k => v.name }
}

# Dapr Component Outputs
output "dapr_component_ids" {
  description = "IDs dos componentes Dapr"
  value       = { for k, v in azurerm_container_app_environment_dapr_component.main : k => v.id }
}

output "dapr_component_names" {
  description = "Nomes dos componentes Dapr"
  value       = { for k, v in azurerm_container_app_environment_dapr_component.main : k => v.name }
}

# Complete Container App Info
output "container_app_info" {
  description = "Informações completas do Container App"
  value = {
    id                    = azurerm_container_app.main.id
    name                  = azurerm_container_app.main.name
    fqdn                  = azurerm_container_app.main.latest_revision_fqdn
    url                   = var.ingress_enabled ? "https://${azurerm_container_app.main.latest_revision_fqdn}" : null
    latest_revision       = azurerm_container_app.main.latest_revision_name
    environment_id        = azurerm_container_app_environment.main.id
    environment_name      = azurerm_container_app_environment.main.name
    location              = var.location
    resource_group        = var.resource_group_name
    revision_mode         = var.revision_mode
    ingress_enabled       = var.ingress_enabled
    ingress_external      = var.ingress_external_enabled
    dapr_enabled          = var.dapr_enabled
    identity_enabled      = var.identity_type != null
    outbound_ip_addresses = azurerm_container_app.main.outbound_ip_addresses
  }
}

# Revision History (útil para rollback)
output "container_app_revision_history" {
  description = "Histórico de revisões"
  value = {
    latest_revision_name = azurerm_container_app.main.latest_revision_name
    revision_mode        = var.revision_mode
  }
}

# Configuration Summary
output "container_app_configuration" {
  description = "Resumo da configuração"
  sensitive   = true
  value = {
    min_replicas       = var.min_replicas
    max_replicas       = var.max_replicas
    containers_count   = length(var.containers)
    init_containers    = length(var.init_containers)
    volumes            = length(var.volumes)
    secrets_count      = length(var.secrets)
    scale_rules_count  = length(var.http_scale_rules) + length(var.tcp_scale_rules) + length(var.azure_queue_scale_rules) + length(var.custom_scale_rules)
  }
}

# Dapr Configuration
output "dapr_configuration" {
  description = "Configuração Dapr"
  value = var.dapr_enabled ? {
    app_id       = var.dapr_app_id
    app_port     = var.dapr_app_port
    app_protocol = var.dapr_app_protocol
    components   = keys(var.dapr_components)
  } : null
}
