terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                               = var.name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  sku                                = var.sku
  retention_in_days                  = var.retention_in_days
  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_enabled         = var.internet_ingestion_enabled
  internet_query_enabled             = var.internet_query_enabled
  reservation_capacity_in_gb_per_day = var.reservation_capacity_in_gb_per_day
  local_authentication_enabled       = var.local_authentication_enabled
  cmk_for_query_forced               = var.cmk_for_query_forced

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : []
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Data Export Rules
resource "azurerm_log_analytics_data_export_rule" "exports" {
  for_each = { for rule in var.data_export_rules : rule.name => rule }

  name                    = each.value.name
  resource_group_name     = var.resource_group_name
  workspace_resource_id   = azurerm_log_analytics_workspace.main.id
  destination_resource_id = each.value.destination_resource_id
  table_names             = each.value.table_names
  enabled                 = each.value.enabled
}

# Linked Services
resource "azurerm_log_analytics_linked_service" "services" {
  for_each = { for service in var.linked_services : service.name => service }

  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  read_access_id      = each.value.resource_id
  write_access_id     = each.value.write_access_resource_id
}

# Linked Storage Accounts - Custom Logs
resource "azurerm_log_analytics_linked_storage_account" "custom_logs" {
  count = length(var.linked_storage_accounts.custom_logs) > 0 ? 1 : 0

  data_source_type      = "CustomLogs"
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_ids   = var.linked_storage_accounts.custom_logs
}

# Linked Storage Accounts - Azure Watson
resource "azurerm_log_analytics_linked_storage_account" "azure_watson" {
  count = length(var.linked_storage_accounts.azure_watson) > 0 ? 1 : 0

  data_source_type      = "AzureWatson"
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_ids   = var.linked_storage_accounts.azure_watson
}

# Linked Storage Accounts - Query
resource "azurerm_log_analytics_linked_storage_account" "query" {
  count = length(var.linked_storage_accounts.query) > 0 ? 1 : 0

  data_source_type      = "Query"
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_ids   = var.linked_storage_accounts.query
}

# Linked Storage Accounts - Alerts
resource "azurerm_log_analytics_linked_storage_account" "alerts" {
  count = length(var.linked_storage_accounts.alerts) > 0 ? 1 : 0

  data_source_type      = "Alerts"
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_ids   = var.linked_storage_accounts.alerts
}

# Saved Searches
resource "azurerm_log_analytics_saved_search" "searches" {
  for_each = { for search in var.saved_searches : search.name => search }

  name                       = each.value.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  category                   = each.value.category
  display_name               = each.value.display_name
  query                      = each.value.query
  function_alias             = each.value.function_alias
  function_parameters        = each.value.function_parameters
}

# Common Solutions
locals {
  common_solutions = merge(
    var.enable_common_solutions.security_center ? {
      "Security" = {
        solution_name  = "Security"
        publisher      = "Microsoft"
        product        = "OMSGallery/Security"
        plan_name      = "Security"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/Security"
      }
    } : {},
    var.enable_common_solutions.update_management ? {
      "Updates" = {
        solution_name  = "Updates"
        publisher      = "Microsoft"
        product        = "OMSGallery/Updates"
        plan_name      = "Updates"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/Updates"
      }
    } : {},
    var.enable_common_solutions.change_tracking ? {
      "ChangeTracking" = {
        solution_name  = "ChangeTracking"
        publisher      = "Microsoft"
        product        = "OMSGallery/ChangeTracking"
        plan_name      = "ChangeTracking"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/ChangeTracking"
      }
    } : {},
    var.enable_common_solutions.sql_assessment ? {
      "SQLAssessment" = {
        solution_name  = "SQLAssessment"
        publisher      = "Microsoft"
        product        = "OMSGallery/SQLAssessment"
        plan_name      = "SQLAssessment"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/SQLAssessment"
      }
    } : {},
    var.enable_common_solutions.container_insights ? {
      "ContainerInsights" = {
        solution_name  = "ContainerInsights"
        publisher      = "Microsoft"
        product        = "OMSGallery/ContainerInsights"
        plan_name      = "ContainerInsights"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/ContainerInsights"
      }
    } : {},
    var.enable_common_solutions.vm_insights ? {
      "VMInsights" = {
        solution_name  = "VMInsights"
        publisher      = "Microsoft"
        product        = "OMSGallery/VMInsights"
        plan_name      = "VMInsights"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/VMInsights"
      }
    } : {},
    var.enable_common_solutions.service_map ? {
      "ServiceMap" = {
        solution_name  = "ServiceMap"
        publisher      = "Microsoft"
        product        = "OMSGallery/ServiceMap"
        plan_name      = "ServiceMap"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/ServiceMap"
      }
    } : {},
    var.enable_common_solutions.azure_automation ? {
      "AzureAutomation" = {
        solution_name  = "AzureAutomation"
        publisher      = "Microsoft"
        product        = "OMSGallery/AzureAutomation"
        plan_name      = "AzureAutomation"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/AzureAutomation"
      }
    } : {},
    var.enable_common_solutions.activity_log_analytics ? {
      "AzureActivity" = {
        solution_name  = "AzureActivity"
        publisher      = "Microsoft"
        product        = "OMSGallery/AzureActivity"
        plan_name      = "AzureActivity"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/AzureActivity"
      }
    } : {},
    var.enable_common_solutions.key_vault_analytics ? {
      "KeyVaultAnalytics" = {
        solution_name  = "KeyVaultAnalytics"
        publisher      = "Microsoft"
        product        = "OMSGallery/KeyVaultAnalytics"
        plan_name      = "KeyVaultAnalytics"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/KeyVaultAnalytics"
      }
    } : {},
    var.enable_common_solutions.network_performance_monitor ? {
      "NetworkMonitoring" = {
        solution_name  = "NetworkMonitoring"
        publisher      = "Microsoft"
        product        = "OMSGallery/NetworkMonitoring"
        plan_name      = "NetworkMonitoring"
        plan_publisher = "Microsoft"
        plan_product   = "OMSGallery/NetworkMonitoring"
      }
    } : {}
  )

  all_solutions = merge(
    { for solution in var.solutions : solution.solution_name => solution },
    local.common_solutions
  )
}

# Solutions
resource "azurerm_log_analytics_solution" "solutions" {
  for_each = local.all_solutions

  solution_name         = each.value.solution_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = each.value.plan_publisher
    product   = each.value.plan_product
  }

  tags = var.tags
}

# Custom Tables
resource "azurerm_log_analytics_workspace_table" "custom_tables" {
  for_each = { for table in var.custom_tables : table.name => table }

  name                    = each.value.name
  workspace_id            = azurerm_log_analytics_workspace.main.id
  plan                    = each.value.plan
  retention_in_days       = each.value.retention_days
  total_retention_in_days = each.value.total_retention_days
}

# Data Collection Endpoint
resource "azurerm_monitor_data_collection_endpoint" "main" {
  count = var.create_data_collection_endpoint ? 1 : 0

  name                          = var.data_collection_endpoint_name != null ? var.data_collection_endpoint_name : "${var.name}-dce"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  public_network_access_enabled = var.data_collection_endpoint_public_network_access_enabled

  tags = var.tags
}

# Diagnostic Settings (for the workspace itself)
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name               = "${var.name}-diag"
  target_resource_id = azurerm_log_analytics_workspace.main.id
  storage_account_id = var.diagnostic_settings_storage_account_id

  dynamic "enabled_log" {
    for_each = toset(var.diagnostic_logs)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(var.diagnostic_metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Locals
locals {
  workspace_id           = azurerm_log_analytics_workspace.main.workspace_id
  workspace_resource_id  = azurerm_log_analytics_workspace.main.id
  
  solution_names = [
    for solution in azurerm_log_analytics_solution.solutions : solution.solution_name
  ]
  
  saved_search_names = [
    for search in azurerm_log_analytics_saved_search.searches : search.name
  ]
}
