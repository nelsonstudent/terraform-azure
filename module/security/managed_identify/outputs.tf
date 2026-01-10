output "id" {
  description = "ID da Managed Identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "name" {
  description = "Nome da Managed Identity"
  value       = azurerm_user_assigned_identity.main.name
}

output "principal_id" {
  description = "Principal ID (Object ID) da Managed Identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "client_id" {
  description = "Client ID (Application ID) da Managed Identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "tenant_id" {
  description = "Tenant ID da Managed Identity"
  value       = azurerm_user_assigned_identity.main.tenant_id
}

output "location" {
  description = "Localização da Managed Identity"
  value       = azurerm_user_assigned_identity.main.location
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_user_assigned_identity.main.resource_group_name
}

output "role_assignment_ids" {
  description = "IDs dos role assignments criados"
  value       = { for k, v in azurerm_role_assignment.main : k => v.id }
}

output "federated_identity_credentials" {
  description = "Federated Identity Credentials criados"
  value = {
    for k, v in azurerm_federated_identity_credential.main : k => {
      id       = v.id
      name     = v.name
      issuer   = v.issuer
      subject  = v.subject
      audience = v.audience
    }
  }
}

output "key_vault_access_policy_id" {
  description = "ID do Key Vault Access Policy (se criado)"
  value       = try(azurerm_key_vault_access_policy.main[0].id, null)
}

output "storage_role_assignments" {
  description = "IDs dos role assignments de Storage"
  value       = { for k, v in azurerm_role_assignment.storage : k => v.id }
}

output "sql_role_assignments" {
  description = "IDs dos role assignments de SQL"
  value       = { for k, v in azurerm_role_assignment.sql : k => v.id }
}

output "acr_role_assignments" {
  description = "IDs dos role assignments de Container Registry"
  value       = { for k, v in azurerm_role_assignment.acr : k => v.id }
}

output "aks_role_assignments" {
  description = "IDs dos role assignments de AKS"
  value       = { for k, v in azurerm_role_assignment.aks : k => v.id }
}

output "app_config_role_assignments" {
  description = "IDs dos role assignments de App Configuration"
  value       = { for k, v in azurerm_role_assignment.app_config : k => v.id }
}

output "event_hub_role_assignments" {
  description = "IDs dos role assignments de Event Hub"
  value       = { for k, v in azurerm_role_assignment.event_hub : k => v.id }
}

output "service_bus_role_assignments" {
  description = "IDs dos role assignments de Service Bus"
  value       = { for k, v in azurerm_role_assignment.service_bus : k => v.id }
}

output "cognitive_role_assignments" {
  description = "IDs dos role assignments de Cognitive Services"
  value       = { for k, v in azurerm_role_assignment.cognitive : k => v.id }
}

output "identity_block" {
  description = "Bloco de identity para uso em outros recursos Azure"
  value = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }
}

output "resource" {
  description = "Objeto completo do recurso Managed Identity"
  value       = azurerm_user_assigned_identity.main
  sensitive   = true
}