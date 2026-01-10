output "id" {
  description = "Resource ID do Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "name" {
  description = "Nome do Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "workspace_id" {
  description = "Workspace ID (GUID) do Log Analytics"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "customer_id" {
  description = "Customer ID (mesmo que workspace_id)"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "primary_shared_key" {
  description = "Primary shared key para autenticação"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Secondary shared key para autenticação"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "location" {
  description = "Localização do workspace"
  value       = azurerm_log_analytics_workspace.main.location
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_log_analytics_workspace.main.resource_group_name
}

output "sku" {
  description = "SKU do workspace"
  value       = azurerm_log_analytics_workspace.main.sku
}

output "retention_in_days" {
  description = "Dias de retenção configurados"
  value       = azurerm_log_analytics_workspace.main.retention_in_days
}

output "daily_quota_gb" {
  description = "Quota diária em GB"
  value       = azurerm_log_analytics_workspace.main.daily_quota_gb
}

# Identity
output "identity" {
  description = "Identidade gerenciada do workspace"
  value = var.identity_type != null ? {
    type         = azurerm_log_analytics_workspace.main.identity[0].type
    principal_id = azurerm_log_analytics_workspace.main.identity[0].principal_id
    tenant_id    = azurerm_log_analytics_workspace.main.identity[0].tenant_id
  } : null
}

output "principal_id" {
  description = "Principal ID da identidade gerenciada"
  value       = var.identity_type != null ? azurerm_log_analytics_workspace.main.identity[0].principal_id : null
}

# Solutions
output "solutions" {
  description = "Informações das solutions instaladas"
  value = {
    for name, solution in azurerm_log_analytics_solution.solutions : name => {
      id            = solution.id
      solution_name = solution.solution_name
    }
  }
}

output "solution_names" {
  description = "Lista de nomes das solutions instaladas"
  value       = local.solution_names
}

output "solution_ids" {
  description = "Map de IDs das solutions"
  value = {
    for name, solution in azurerm_log_analytics_solution.solutions : name => solution.id
  }
}

# Saved Searches
output "saved_searches" {
  description = "Informações das queries salvas"
  value = {
    for name, search in azurerm_log_analytics_saved_search.searches : name => {
      id           = search.id
      name         = search.name
      display_name = search.display_name
      category     = search.category
    }
  }
}

output "saved_search_names" {
  description = "Lista de nomes das queries salvas"
  value       = local.saved_search_names
}

# Data Export Rules
output "data_export_rules" {
  description = "Informações das regras de exportação"
  value = {
    for name, rule in azurerm_log_analytics_data_export_rule.exports : name => {
      id                      = rule.id
      name                    = rule.name
      destination_resource_id = rule.destination_resource_id
      table_names             = rule.table_names
      enabled                 = rule.enabled
    }
  }
}

output "data_export_rule_ids" {
  description = "Map de IDs das regras de exportação"
  value = {
    for name, rule in azurerm_log_analytics_data_export_rule.exports : name => rule.id
  }
}

# Linked Services
output "linked_services" {
  description = "Informações dos linked services"
  value = {
    for name, service in azurerm_log_analytics_linked_service.services : name => {
      id   = service.id
      name = service.name
    }
  }
}

# Custom Tables
output "custom_tables" {
  description = "Informações das tabelas customizadas"
  value = {
    for name, table in azurerm_log_analytics_workspace_table.custom_tables : name => {
      id                = table.id
      name              = table.name
      plan              = table.plan
      retention_in_days = table.retention_in_days
    }
  }
}

# Data Collection Endpoint
output "data_collection_endpoint_id" {
  description = "ID do Data Collection Endpoint"
  value       = var.create_data_collection_endpoint ? azurerm_monitor_data_collection_endpoint.main[0].id : null
}

output "data_collection_endpoint_name" {
  description = "Nome do Data Collection Endpoint"
  value       = var.create_data_collection_endpoint ? azurerm_monitor_data_collection_endpoint.main[0].name : null
}

output "data_collection_endpoint_logs_ingestion_endpoint" {
  description = "Endpoint de ingestão de logs"
  value       = var.create_data_collection_endpoint ? azurerm_monitor_data_collection_endpoint.main[0].logs_ingestion_endpoint : null
}

# Connection Info
output "connection_info" {
  description = "Informações de conexão para agentes"
  value = {
    workspace_id       = local.workspace_id
    primary_key        = azurerm_log_analytics_workspace.main.primary_shared_key
    secondary_key      = azurerm_log_analytics_workspace.main.secondary_shared_key
    workspace_name     = var.name
    resource_group     = var.resource_group_name
  }
  sensitive = true
}

# Agent Configuration String
output "agent_config_string" {
  description = "String de configuração para Azure Monitor Agent"
  value       = "WorkspaceId=${local.workspace_id};WorkspaceKey=${azurerm_log_analytics_workspace.main.primary_shared_key}"
  sensitive   = true
}

# Summary
output "workspace_summary" {
  description = "Resumo das informações do workspace"
  value = {
    id                     = azurerm_log_analytics_workspace.main.id
    name                   = var.name
    workspace_id           = local.workspace_id
    location               = var.location
    sku                    = var.sku
    retention_days         = var.retention_in_days
    daily_quota_gb         = var.daily_quota_gb
    solutions_count        = length(azurerm_log_analytics_solution.solutions)
    saved_searches_count   = length(azurerm_log_analytics_saved_search.searches)
    data_export_rules_count = length(azurerm_log_analytics_data_export_rule.exports)
    custom_tables_count    = length(azurerm_log_analytics_workspace_table.custom_tables)
    has_identity           = var.identity_type != null
    has_dce                = var.create_data_collection_endpoint
  }
}

# Query Endpoint
output "query_endpoint" {
  description = "Endpoint para queries API"
  value       = "https://api.loganalytics.io/v1/workspaces/${local.workspace_id}/query"
}

# Portal URLs
output "portal_urls" {
  description = "URLs úteis do portal Azure"
  value = {
    workspace_url = "https://portal.azure.com/#@/resource${azurerm_log_analytics_workspace.main.id}/overview"
    logs_url      = "https://portal.azure.com/#@/resource${azurerm_log_analytics_workspace.main.id}/logs"
    workbooks_url = "https://portal.azure.com/#@/resource${azurerm_log_analytics_workspace.main.id}/workbooks"
  }
}

# Configuration
output "configuration" {
  description = "Configurações do workspace"
  value = {
    internet_ingestion_enabled = var.internet_ingestion_enabled
    internet_query_enabled     = var.internet_query_enabled
    local_auth_disabled        = var.local_authentication_enabled
    cmk_for_query_forced       = var.cmk_for_query_forced
    reservation_capacity_gb    = var.reservation_capacity_in_gb_per_day
  }
}

# Lists for easy reference
output "solution_list" {
  description = "Lista simples de solutions"
  value       = keys(azurerm_log_analytics_solution.solutions)
}

output "saved_search_list" {
  description = "Lista simples de saved searches"
  value       = keys(azurerm_log_analytics_saved_search.searches)
}

output "custom_table_list" {
  description = "Lista simples de custom tables"
  value       = keys(azurerm_log_analytics_workspace_table.custom_tables)
}