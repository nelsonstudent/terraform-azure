output "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  value       = local.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Nome do Log Analytics Workspace"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].name : null
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace ID (GUID) do Log Analytics"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].workspace_id : null
}

output "log_analytics_workspace_primary_key" {
  description = "Primary shared key do Log Analytics"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].primary_shared_key : null
  sensitive   = true
}

output "log_analytics_workspace_secondary_key" {
  description = "Secondary shared key do Log Analytics"
  value       = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].secondary_shared_key : null
  sensitive   = true
}

# Application Insights
output "application_insights" {
  description = "Informações dos Application Insights criados"
  value = {
    for name, app in azurerm_application_insights.apps : name => {
      id                      = app.id
      name                    = app.name
      app_id                  = app.app_id
      instrumentation_key     = app.instrumentation_key
      connection_string       = app.connection_string
      application_type        = app.application_type
    }
  }
  sensitive = true
}

output "application_insights_ids" {
  description = "Map de IDs dos Application Insights"
  value       = local.application_insights_ids
}

output "application_insights_instrumentation_keys" {
  description = "Map de Instrumentation Keys"
  value = {
    for name, app in azurerm_application_insights.apps : name => app.instrumentation_key
  }
  sensitive = true
}

output "application_insights_connection_strings" {
  description = "Map de Connection Strings"
  value = {
    for name, app in azurerm_application_insights.apps : name => app.connection_string
  }
  sensitive = true
}

# Action Groups
output "action_groups" {
  description = "Informações dos Action Groups"
  value = {
    for name, ag in azurerm_monitor_action_group.groups : name => {
      id         = ag.id
      name       = ag.name
      short_name = ag.short_name
      enabled    = ag.enabled
    }
  }
}

output "action_group_ids" {
  description = "Map de IDs dos Action Groups"
  value       = local.action_group_ids
}

# Metric Alerts
output "metric_alerts" {
  description = "Informações dos Metric Alerts"
  value = {
    for name, alert in azurerm_monitor_metric_alert.alerts : name => {
      id          = alert.id
      name        = alert.name
      description = alert.description
      enabled     = alert.enabled
      severity    = alert.severity
      scopes      = alert.scopes
    }
  }
}

output "metric_alert_ids" {
  description = "Map de IDs dos Metric Alerts"
  value = {
    for name, alert in azurerm_monitor_metric_alert.alerts : name => alert.id
  }
}

# Scheduled Query Rules
output "scheduled_query_rules" {
  description = "Informações dos Scheduled Query Rules"
  value = {
    for name, query in azurerm_monitor_scheduled_query_rules_alert.queries : name => {
      id          = query.id
      name        = query.name
      description = query.description
      enabled     = query.enabled
      severity    = query.severity
    }
  }
}

output "scheduled_query_rule_ids" {
  description = "Map de IDs dos Scheduled Query Rules"
  value = {
    for name, query in azurerm_monitor_scheduled_query_rules_alert.queries : name => query.id
  }
}

# Activity Log Alerts
output "activity_log_alerts" {
  description = "Informações dos Activity Log Alerts"
  value = {
    for name, alert in azurerm_monitor_activity_log_alert.activity_alerts : name => {
      id          = alert.id
      name        = alert.name
      description = alert.description
      enabled     = alert.enabled
    }
  }
}

output "activity_log_alert_ids" {
  description = "Map de IDs dos Activity Log Alerts"
  value = {
    for name, alert in azurerm_monitor_activity_log_alert.activity_alerts : name => alert.id
  }
}

# Data Collection Rules
output "data_collection_rules" {
  description = "Informações dos Data Collection Rules"
  value = {
    for name, rule in azurerm_monitor_data_collection_rule.rules : name => {
      id                  = rule.id
      name                = rule.name
      immutable_id        = rule.immutable_id
    }
  }
}

output "data_collection_rule_ids" {
  description = "Map de IDs dos Data Collection Rules"
  value = {
    for name, rule in azurerm_monitor_data_collection_rule.rules : name => rule.id
  }
}

# Workbooks
output "workbooks" {
  description = "Informações dos Workbooks"
  value = {
    for name, wb in azurerm_application_insights_workbook.workbooks : name => {
      id           = wb.id
      name         = wb.name
      display_name = wb.display_name
    }
  }
}

output "workbook_ids" {
  description = "Map de IDs dos Workbooks"
  value = {
    for name, wb in azurerm_application_insights_workbook.workbooks : name => wb.id
  }
}

# Autoscale Settings
output "autoscale_settings" {
  description = "Informações dos Autoscale Settings"
  value = {
    for name, as in azurerm_monitor_autoscale_setting.autoscale : name => {
      id                 = as.id
      name               = as.name
      target_resource_id = as.target_resource_id
      enabled            = as.enabled
    }
  }
}

output "autoscale_setting_ids" {
  description = "Map de IDs dos Autoscale Settings"
  value = {
    for name, as in azurerm_monitor_autoscale_setting.autoscale : name => as.id
  }
}

# Summary
output "summary" {
  description = "Resumo dos recursos de monitoramento criados"
  value = {
    log_analytics_workspace_created    = var.create_log_analytics_workspace
    log_analytics_workspace_id         = local.log_analytics_workspace_id
    application_insights_count         = length(azurerm_application_insights.apps)
    action_groups_count                = length(azurerm_monitor_action_group.groups)
    metric_alerts_count                = length(azurerm_monitor_metric_alert.alerts)
    scheduled_query_rules_count        = length(azurerm_monitor_scheduled_query_rules_alert.queries)
    activity_log_alerts_count          = length(azurerm_monitor_activity_log_alert.activity_alerts)
    data_collection_rules_count        = length(azurerm_monitor_data_collection_rule.rules)
    workbooks_count                    = length(azurerm_application_insights_workbook.workbooks)
    autoscale_settings_count           = length(azurerm_monitor_autoscale_setting.autoscale)
  }
}

# Lists for easy reference
output "application_insights_names" {
  description = "Lista de nomes dos Application Insights"
  value       = [for app in azurerm_application_insights.apps : app.name]
}

output "action_group_names" {
  description = "Lista de nomes dos Action Groups"
  value       = [for ag in azurerm_monitor_action_group.groups : ag.name]
}

output "metric_alert_names" {
  description = "Lista de nomes dos Metric Alerts"
  value       = [for alert in azurerm_monitor_metric_alert.alerts : alert.name]
}

# Configuration Info
output "monitoring_config" {
  description = "Informações de configuração de monitoramento"
  value = {
    log_analytics = var.create_log_analytics_workspace ? {
      id             = azurerm_log_analytics_workspace.main[0].id
      workspace_id   = azurerm_log_analytics_workspace.main[0].workspace_id
      name           = azurerm_log_analytics_workspace.main[0].name
      sku            = var.log_analytics_sku
      retention_days = var.log_analytics_retention_days
    } : null
    
    application_insights_enabled = length(var.application_insights) > 0
    alerting_configured         = length(var.action_groups) > 0
    autoscaling_enabled         = length(var.autoscale_settings) > 0
  }
}