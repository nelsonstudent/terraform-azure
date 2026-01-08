output "id" {
  description = "ID do Management Group"
  value       = azurerm_management_group.main.id
}

output "name" {
  description = "Nome do Management Group"
  value       = azurerm_management_group.main.name
}

output "display_name" {
  description = "Nome de exibição do Management Group"
  value       = azurerm_management_group.main.display_name
}

output "parent_management_group_id" {
  description = "ID do Management Group pai"
  value       = azurerm_management_group.main.parent_management_group_id
}

output "subscription_ids" {
  description = "IDs das subscriptions associadas"
  value       = var.subscription_ids
}

output "subscription_associations" {
  description = "Associações de subscriptions criadas"
  value = {
    for k, v in azurerm_management_group_subscription_association.main : k => {
      id                  = v.id
      management_group_id = v.management_group_id
      subscription_id     = v.subscription_id
    }
  }
}

output "child_management_groups" {
  description = "Management Groups filhos criados"
  value = {
    for k, v in azurerm_management_group.children : k => {
      id           = v.id
      name         = v.name
      display_name = v.display_name
      parent_id    = v.parent_management_group_id
    }
  }
}

output "child_management_group_ids" {
  description = "IDs dos Management Groups filhos"
  value       = { for k, v in azurerm_management_group.children : k => v.id }
}

output "custom_policy_definitions" {
  description = "Definições de políticas customizadas"
  value = {
    for k, v in azurerm_policy_definition.custom : k => {
      id           = v.id
      name         = v.name
      display_name = v.display_name
      policy_type  = v.policy_type
      mode         = v.mode
    }
  }
}

output "custom_policy_definition_ids" {
  description = "IDs das definições de políticas customizadas"
  value       = { for k, v in azurerm_policy_definition.custom : k => v.id }
}

output "policy_set_definitions" {
  description = "Policy Set Definitions (Initiatives)"
  value = {
    for k, v in azurerm_policy_set_definition.custom : k => {
      id           = v.id
      name         = v.name
      display_name = v.display_name
      policy_type  = v.policy_type
    }
  }
}

output "policy_set_definition_ids" {
  description = "IDs das Policy Set Definitions"
  value       = { for k, v in azurerm_policy_set_definition.custom : k => v.id }
}

output "policy_assignments" {
  description = "Policy assignments criadas"
  value = {
    for k, v in azurerm_management_group_policy_assignment.main : k => {
      id                   = v.id
      name                 = v.name
      display_name         = v.display_name
      policy_definition_id = v.policy_definition_id
      enforce              = v.enforce
    }
  }
}

output "policy_assignment_ids" {
  description = "IDs das policy assignments"
  value       = { for k, v in azurerm_management_group_policy_assignment.main : k => v.id }
}

output "role_assignments" {
  description = "Role assignments criadas"
  value = {
    for k, v in azurerm_role_assignment.main : k => {
      id                   = v.id
      principal_id         = v.principal_id
      role_definition_name = v.role_definition_name
      scope                = v.scope
    }
  }
}

output "role_assignment_ids" {
  description = "IDs dos role assignments"
  value       = { for k, v in azurerm_role_assignment.main : k => v.id }
}

output "hierarchy" {
  description = "Hierarquia do Management Group"
  value = {
    root = {
      id                  = azurerm_management_group.main.id
      name                = azurerm_management_group.main.name
      display_name        = azurerm_management_group.main.display_name
      subscription_count  = length(var.subscription_ids)
      policy_count        = length(local.all_policy_assignments)
      custom_policy_count = length(var.custom_policy_definitions)
      child_count         = length(var.child_management_groups)
    }
    children = {
      for k, v in azurerm_management_group.children : k => {
        id                 = v.id
        name               = v.name
        display_name       = v.display_name
        subscription_count = length(lookup(var.child_management_groups[k], "subscription_ids", []))
      }
    }
  }
}

output "governance_summary" {
  description = "Resumo da governança aplicada"
  value = {
    management_group_name       = azurerm_management_group.main.name
    subscription_count          = length(var.subscription_ids)
    child_management_groups     = length(var.child_management_groups)
    policy_assignments_count    = length(local.all_policy_assignments)
    custom_policies_count       = length(var.custom_policy_definitions)
    policy_initiatives_count    = length(var.policy_set_definitions)
    role_assignments_count      = length(var.role_assignments)
    default_policies_enabled    = var.enable_default_policies
  }
}

output "resource" {
  description = "Objeto completo do Management Group"
  value       = azurerm_management_group.main
}