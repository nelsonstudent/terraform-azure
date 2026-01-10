terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_user_assigned_identity" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Role Assignments genéricos
resource "azurerm_role_assignment" "main" {
  for_each = { for idx, ra in var.role_assignments : idx => ra }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  role_definition_id   = each.value.role_definition_id
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  description          = each.value.description
  condition            = each.value.condition
  condition_version    = each.value.condition_version
}

# Federated Identity Credentials (para Workload Identity)
resource "azurerm_federated_identity_credential" "main" {
  for_each = { for fic in var.federated_identity_credentials : fic.name => fic }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.main.id
  issuer              = each.value.issuer
  subject             = each.value.subject
  audience            = each.value.audiences
}

# Key Vault Access Policy (quando não usar RBAC)
resource "azurerm_key_vault_access_policy" "main" {
  count = var.key_vault_access.enabled && var.key_vault_access.key_vault_id != null ? 1 : 0

  key_vault_id = var.key_vault_access.key_vault_id
  tenant_id    = azurerm_user_assigned_identity.main.tenant_id
  object_id    = azurerm_user_assigned_identity.main.principal_id

  key_permissions         = var.key_vault_access.key_permissions
  secret_permissions      = var.key_vault_access.secret_permissions
  certificate_permissions = var.key_vault_access.certificate_permissions
  storage_permissions     = var.key_vault_access.storage_permissions
}

# Storage Account Access
resource "azurerm_role_assignment" "storage" {
  for_each = { for idx, sa in var.storage_account_access : idx => sa }

  scope                = each.value.storage_account_id
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# SQL Database Access - Role Assignments
resource "azurerm_role_assignment" "sql" {
  for_each = { for idx, sql in var.sql_database_access : idx => sql }

  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${coalesce(each.value.resource_group_name, var.resource_group_name)}/providers/Microsoft.Sql/servers/${each.value.sql_server_name}/databases/${each.value.database_name}"
  role_definition_name = "SQL DB Contributor"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Container Registry Access
resource "azurerm_role_assignment" "acr" {
  for_each = { for idx, acr in var.container_registry_access : idx => acr }

  scope                = each.value.registry_id
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# AKS Cluster Access
resource "azurerm_role_assignment" "aks" {
  for_each = { for idx, aks in var.aks_access : idx => aks }

  scope                = each.value.cluster_id
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# App Configuration Access
resource "azurerm_role_assignment" "app_config" {
  for_each = { for idx, ac in var.app_configuration_access : idx => ac }

  scope                = each.value.app_config_id
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Event Hub Access
resource "azurerm_role_assignment" "event_hub" {
  for_each = { for idx, eh in var.event_hub_access : idx => eh }

  scope                = each.value.event_hub_id
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Service Bus Access
resource "azurerm_role_assignment" "service_bus" {
  for_each = { for idx, sb in var.service_bus_access : idx => sb }

  scope                = each.value.service_bus_id
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Cognitive Services Access
resource "azurerm_role_assignment" "cognitive" {
  for_each = { for idx, cs in var.cognitive_services_access : idx => cs }

  scope                = each.value.cognitive_account_id
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

data "azurerm_client_config" "current" {}
