output "id" {
  description = "ID do Resource Group"
  value       = azurerm_resource_group.main.id
}

output "name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Localização do Resource Group"
  value       = azurerm_resource_group.main.location
}

output "tags" {
  description = "Tags aplicadas ao Resource Group"
  value       = azurerm_resource_group.main.tags
}

output "managed_by" {
  description = "ID do recurso que gerencia este Resource Group"
  value       = azurerm_resource_group.main.managed_by
}

output "lock_id" {
  description = "ID do Management Lock (se criado)"
  value       = try(azurerm_management_lock.main[0].id, null)
}

output "lock_level" {
  description = "Nível do lock aplicado"
  value       = local.effective_lock_level
}

output "is_locked" {
  description = "Indica se o Resource Group está locked"
  value       = local.effective_lock_level != null
}

output "role_assignment_ids" {
  description = "IDs dos role assignments criados"
  value       = { for k, v in azurerm_role_assignment.main : k => v.id }
}

output "role_assignments" {
  description = "Detalhes dos role assignments"
  value = {
    for k, v in azurerm_role_assignment.main : k => {
      id                   = v.id
      principal_id         = v.principal_id
      role_definition_name = v.role_definition_name
      scope                = v.scope
    }
  }
}

output "policy_assignment_ids" {
  description = "IDs das policy assignments"
  value       = { for k, v in azurerm_resource_group_policy_assignment.main : k => v.id }
}

output "policy_assignments" {
  description = "Detalhes das policy assignments"
  value = {
    for k, v in azurerm_resource_group_policy_assignment.main : k => {
      id                   = v.id
      name                 = v.name
      policy_definition_id = v.policy_definition_id
      enforce              = v.enforce
    }
  }
}

output "diagnostic_setting_id" {
  description = "ID do diagnostic setting (se criado)"
  value       = try(azurerm_monitor_diagnostic_setting.main[0].id, null)
}

output "budget_id" {
  description = "ID do budget (se criado)"
  value       = try(azurerm_consumption_budget_resource_group.main[0].id, null)
}

output "budget_amount" {
  description = "Valor do budget configurado"
  value       = var.budget.enabled ? var.budget.amount : null
}

output "subscription_id" {
  description = "ID da subscription do Resource Group"
  value       = local.subscription_id
}

output "full_resource_id" {
  description = "Resource ID completo no formato ARM"
  value       = "/subscriptions/${local.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}"
}

output "resource" {
  description = "Objeto completo do Resource Group"
  value       = azurerm_resource_group.main
}

output "governance" {
  description = "Resumo da governança aplicada"
  value = {
    locked                 = local.effective_lock_level != null
    lock_level             = local.effective_lock_level
    role_assignments_count = length(var.role_assignments)
    policy_assignments_count = length(var.policy_assignments)
    budget_enabled         = var.budget.enabled
    budget_amount          = var.budget.enabled ? var.budget.amount : null
    diagnostic_enabled     = var.diagnostic_settings.enabled
  }
}