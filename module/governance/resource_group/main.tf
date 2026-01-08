terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  subscription_id = coalesce(var.subscription_id, data.azurerm_client_config.current.subscription_id)
  
  # Determinar se deve criar lock baseado em prevent_deletion ou enable_delete_lock
  should_create_lock = coalesce(var.enable_delete_lock, var.prevent_deletion, false)
  
  # Se lock_level for especificado, usa ele; senão usa CanNotDelete se should_create_lock for true
  effective_lock_level = var.lock_level != null ? var.lock_level : (local.should_create_lock ? "CanNotDelete" : null)

  # Preparar data de início do budget (primeiro dia do próximo mês se não especificado)
  budget_start_date = var.budget.start_date != null ? var.budget.start_date : formatdate("YYYY-MM-01", timeadd(timestamp(), "720h"))
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name       = var.name
  location   = var.location
  managed_by = var.managed_by

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["CreatedBy"]
    ]
  }
}

# Management Lock
resource "azurerm_management_lock" "main" {
  count = local.effective_lock_level != null ? 1 : 0

  name       = "${var.name}-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = local.effective_lock_level
  notes      = var.lock_notes
}

# Role Assignments
resource "azurerm_role_assignment" "main" {
  for_each = { for idx, ra in var.role_assignments : idx => ra }

  scope                = azurerm_resource_group.main.id
  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_definition_name
  role_definition_id   = each.value.role_definition_id
  description          = each.value.description
  condition            = each.value.condition
  condition_version    = each.value.condition_version

  skip_service_principal_aad_check = true
}

# Policy Assignments
resource "azurerm_resource_group_policy_assignment" "main" {
  for_each = { for idx, pa in var.policy_assignments : pa.name => pa }

  name                 = each.value.name
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = each.value.policy_definition_id
  description          = each.value.description
  display_name         = each.value.display_name
  enforce              = each.value.enforce
  parameters           = each.value.parameters
  metadata             = each.value.metadata

  dynamic "identity" {
    for_each = each.value.identity_type != null ? [1] : []
    content {
      type = each.value.identity_type
    }
  }

  location = each.value.identity_type != null ? coalesce(each.value.location, var.location) : null

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_messages != null ? each.value.non_compliance_messages : []
    content {
      content                        = non_compliance_message.value.message
      policy_definition_reference_id = non_compliance_message.value.policy_definition_reference_id
    }
  }
}

# Monitor Diagnostic Setting para Activity Log
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.diagnostic_settings.enabled ? 1 : 0

  name                           = var.diagnostic_settings.name
  target_resource_id             = azurerm_resource_group.main.id
  log_analytics_workspace_id     = var.diagnostic_settings.log_analytics_workspace_id
  storage_account_id             = var.diagnostic_settings.storage_account_id
  eventhub_authorization_rule_id = var.diagnostic_settings.eventhub_authorization_rule_id
  eventhub_name                  = var.diagnostic_settings.eventhub_name

  dynamic "enabled_log" {
    for_each = toset(var.diagnostic_settings.log_categories)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Consumption Budget
resource "azurerm_consumption_budget_resource_group" "main" {
  count = var.budget.enabled ? 1 : 0

  name              = coalesce(var.budget.name, "${var.name}-budget")
  resource_group_id = azurerm_resource_group.main.id

  amount     = var.budget.amount
  time_grain = var.budget.time_grain

  time_period {
    start_date = local.budget_start_date
    end_date   = var.budget.end_date
  }

  dynamic "notification" {
    for_each = var.budget.notifications
    content {
      enabled        = notification.value.enabled
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      contact_emails = notification.value.contact_emails
      contact_roles  = notification.value.contact_roles
      contact_groups = notification.value.contact_groups

      threshold_type = "Actual"
    }
  }

  lifecycle {
    ignore_changes = [
      time_period[0].start_date
    ]
  }
}
