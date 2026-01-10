output "id" {
  description = "ID do Application Insights"
  value       = azurerm_application_insights.main.id
}

output "name" {
  description = "Nome do Application Insights"
  value       = azurerm_application_insights.main.name
}

output "instrumentation_key" {
  description = "Chave de instrumentação do Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Connection string do Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_id" {
  description = "Application ID do Application Insights"
  value       = azurerm_application_insights.main.app_id
}

output "workspace_id" {
  description = "ID do Log Analytics Workspace associado"
  value       = azurerm_application_insights.main.workspace_id
}

output "application_type" {
  description = "Tipo de aplicação configurado"
  value       = azurerm_application_insights.main.application_type
}

output "retention_in_days" {
  description = "Período de retenção configurado em dias"
  value       = azurerm_application_insights.main.retention_in_days
}

output "sampling_percentage" {
  description = "Percentual de sampling configurado"
  value       = azurerm_application_insights.main.sampling_percentage
}

output "smart_detection_rules" {
  description = "IDs das regras de detecção inteligente criadas"
  value = {
    failure_anomalies         = try(azurerm_application_insights_smart_detection_rule.failure_anomalies[0].id, null)
    slow_page_load            = try(azurerm_application_insights_smart_detection_rule.slow_page_load[0].id, null)
    slow_server_response      = try(azurerm_application_insights_smart_detection_rule.slow_server_response[0].id, null)
    degradation_server_response = try(azurerm_application_insights_smart_detection_rule.degradation_server_response[0].id, null)
    memory_leak               = try(azurerm_application_insights_smart_detection_rule.memory_leak[0].id, null)
    exception_volume          = try(azurerm_application_insights_smart_detection_rule.exception_volume[0].id, null)
    security_issue            = try(azurerm_application_insights_smart_detection_rule.security_issue[0].id, null)
  }
}

output "resource" {
  description = "Objeto completo do recurso Application Insights"
  value       = azurerm_application_insights.main
  sensitive   = true
}