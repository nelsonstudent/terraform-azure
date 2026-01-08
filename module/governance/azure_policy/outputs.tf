output "id" {
  description = "ID do recurso criado (policy definition, assignment ou exemption)"
  value = try(
    azurerm_policy_definition.subscription[0].id,
    azurerm_policy_definition.management_group[0].id,
    azurerm_policy_set_definition.subscription[0].id,
    azurerm_policy_set_definition.management_group[0].id,
    azurerm_resource_policy_assignment.main[0].id,
    azurerm_resource_policy_exemption.main[0].id,
    null
  )
}

output "name" {
  description = "Nome do recurso criado"
  value       = var.name
}

output "display_name" {
  description = "Nome de exibição do recurso"
  value       = local.effective_display_name
}

output "type" {
  description = "Tipo de recurso criado"
  value       = var.policy_type
}

# Policy Definition Outputs
output "policy_definition_id" {
  description = "ID da policy definition (se criada)"
  value = try(
    azurerm_policy_definition.subscription[0].id,
    azurerm_policy_definition.management_group[0].id,
    null
  )
}

output "policy_definition" {
  description = "Objeto completo da policy definition"
  value = try(
    azurerm_policy_definition.subscription[0],
    azurerm_policy_definition.management_group[0],
    null
  )
  sensitive = true
}

# Policy Set Definition Outputs
output "policy_set_definition_id" {
  description = "ID da policy set definition (se criada)"
  value = try(
    azurerm_policy_set_definition.subscription[0].id,
    azurerm_policy_set_definition.management_group[0].id,
    null
  )
}

output "policy_set_definition" {
  description = "Objeto completo da policy set definition"
  value = try(
    azurerm_policy_set_definition.subscription[0],
    azurerm_policy_set_definition.management_group[0],
    null
  )
  sensitive = true
}

output "policy_definition_count" {
  description = "Número de policy definitions na initiative"
  value       = var.policy_type == "set_definition" ? length(var.policy_definitions) : 0
}

# Policy Assignment Outputs
output "policy_assignment_id" {
  description = "ID do policy assignment (se criado)"
  value       = try(azurerm_resource_policy_assignment.main[0].id, null)
}

output "policy_assignment" {
  description = "Objeto completo do policy assignment"
  value       = try(azurerm_resource_policy_assignment.main[0], null)
  sensitive   = true
}

output "assignment_scope" {
  description = "Escopo do policy assignment"
  value       = var.policy_type == "assignment" ? local.effective_scope : null
}

output "assignment_identity" {
  description = "Managed Identity do policy assignment"
  value = try({
    type         = azurerm_resource_policy_assignment.main[0].identity[0].type
    principal_id = azurerm_resource_policy_assignment.main[0].identity[0].principal_id
    tenant_id    = azurerm_resource_policy_assignment.main[0].identity[0].tenant_id
  }, null)
  sensitive = true
}

output "enforce_mode" {
  description = "Status de enforcement da policy"
  value       = var.policy_type == "assignment" ? var.enforce : null
}

# Policy Exemption Outputs
output "policy_exemption_id" {
  description = "ID da policy exemption (se criada)"
  value       = try(azurerm_resource_policy_exemption.main[0].id, null)
}

output "policy_exemption" {
  description = "Objeto completo da policy exemption"
  value       = try(azurerm_resource_policy_exemption.main[0], null)
  sensitive   = true
}

output "exemption_category" {
  description = "Categoria da exemption"
  value       = var.policy_type == "exemption" ? var.exemption_category : null
}

output "exemption_expires_on" {
  description = "Data de expiração da exemption"
  value       = var.policy_type == "exemption" ? var.expires_on : null
}

# Remediation Outputs
output "remediation_task_id" {
  description = "ID da remediation task (se criada)"
  value       = try(azurerm_subscription_policy_remediation.main[0].id, null)
}

output "remediation_task" {
  description = "Objeto completo da remediation task"
  value       = try(azurerm_subscription_policy_remediation.main[0], null)
}

output "remediation_enabled" {
  description = "Indica se remediation está habilitada"
  value       = var.create_remediation_task
}

# Summary Output
output "policy_summary" {
  description = "Resumo da policy criada"
  value = {
    id           = try(
      azurerm_policy_definition.subscription[0].id,
      azurerm_policy_definition.management_group[0].id,
      azurerm_policy_set_definition.subscription[0].id,
      azurerm_policy_set_definition.management_group[0].id,
      azurerm_resource_policy_assignment.main[0].id,
      azurerm_resource_policy_exemption.main[0].id,
      null
    )
    name         = var.name
    display_name = local.effective_display_name
    type         = var.policy_type
    mode         = var.mode
    scope        = var.policy_type == "assignment" || var.policy_type == "exemption" ? local.effective_scope : null
    enforce      = var.policy_type == "assignment" ? var.enforce : null
    has_identity = var.policy_type == "assignment" && var.identity_type != null
    has_remediation = var.create_remediation_task
  }
}