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
  # Display name padrão igual ao name se não especificado
  effective_display_name = coalesce(var.display_name, var.name)

  # Políticas padrão recomendadas
  default_policies = var.enable_default_policies ? [
    {
      name                 = "audit-vm-managed-disks"
      display_name         = "Audit VMs that do not use managed disks"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
      description          = "Audit VMs without managed disks"
      enforce              = false
    },
    {
      name                 = "allowed-locations"
      display_name         = "Allowed locations"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
      description          = "Restrict resource locations"
      enforce              = true
      parameters = jsonencode({
        listOfAllowedLocations = {
          value = ["eastus", "eastus2", "westus2", "centralus"]
        }
      })
    },
    {
      name                 = "require-tag-on-resources"
      display_name         = "Require a tag on resources"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
      description          = "Enforce tagging on resources"
      enforce              = true
      parameters = jsonencode({
        tagName = {
          value = "Environment"
        }
      })
    }
  ] : []

  # Combinar políticas customizadas com padrões
  all_policy_assignments = concat(var.policy_assignments, local.default_policies)
}

# Management Group Principal
resource "azurerm_management_group" "main" {
  name                       = var.name
  display_name               = local.effective_display_name
  parent_management_group_id = var.parent_management_group_id

  lifecycle {
    create_before_destroy = false
  }
}

# Management Groups Filhos
resource "azurerm_management_group" "children" {
  for_each = var.child_management_groups

  name                       = each.key
  display_name               = coalesce(each.value.display_name, each.key)
  parent_management_group_id = azurerm_management_group.main.id

  lifecycle {
    create_before_destroy = false
  }
}

# Subscription Associations
resource "azurerm_management_group_subscription_association" "main" {
  for_each = toset(var.subscription_ids)

  management_group_id = azurerm_management_group.main.id
  subscription_id     = "/subscriptions/${each.value}"
}

# Subscription Associations para Management Groups Filhos
resource "azurerm_management_group_subscription_association" "children" {
  for_each = merge([
    for mg_name, mg_config in var.child_management_groups : {
      for sub_id in mg_config.subscription_ids :
      "${mg_name}-${sub_id}" => {
        management_group_id = azurerm_management_group.children[mg_name].id
        subscription_id     = sub_id
      }
    }
  ]...)

  management_group_id = each.value.management_group_id
  subscription_id     = "/subscriptions/${each.value.subscription_id}"
}

# Custom Policy Definitions
resource "azurerm_policy_definition" "custom" {
  for_each = { for pd in var.custom_policy_definitions : pd.name => pd }

  name                = each.value.name
  policy_type         = each.value.policy_type
  mode                = each.value.mode
  display_name        = each.value.display_name
  description         = each.value.description
  management_group_id = azurerm_management_group.main.id

  metadata     = each.value.metadata
  parameters   = each.value.parameters
  policy_rule  = each.value.policy_rule
}

# Policy Set Definitions (Initiatives)
resource "azurerm_policy_set_definition" "custom" {
  for_each = { for psd in var.policy_set_definitions : psd.name => psd }

  name                = each.value.name
  policy_type         = each.value.policy_type
  display_name        = each.value.display_name
  description         = each.value.description
  management_group_id = azurerm_management_group.main.id

  metadata   = each.value.metadata
  parameters = each.value.parameters

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      parameter_values     = policy_definition_reference.value.parameter_values
      reference_id         = policy_definition_reference.value.reference_id
      policy_group_names   = policy_definition_reference.value.policy_group_names
    }
  }

  dynamic "policy_definition_group" {
    for_each = each.value.policy_definition_groups != null ? each.value.policy_definition_groups : []
    content {
      name                            = policy_definition_group.value.name
      display_name                    = policy_definition_group.value.display_name
      category                        = policy_definition_group.value.category
      description                     = policy_definition_group.value.description
      additional_metadata_resource_id = policy_definition_group.value.additional_metadata_resource_id
    }
  }
}

# Policy Assignments
resource "azurerm_management_group_policy_assignment" "main" {
  for_each = { for idx, pa in local.all_policy_assignments : pa.name => pa }

  name                 = each.value.name
  management_group_id  = azurerm_management_group.main.id
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

  location = each.value.identity_type != null ? coalesce(each.value.location, var.default_location) : null

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_messages != null ? each.value.non_compliance_messages : []
    content {
      content                        = non_compliance_message.value.message
      policy_definition_reference_id = non_compliance_message.value.policy_definition_reference_id
    }
  }

  depends_on = [
    azurerm_policy_definition.custom,
    azurerm_policy_set_definition.custom
  ]
}

# Role Assignments
resource "azurerm_role_assignment" "main" {
  for_each = { for idx, ra in var.role_assignments : idx => ra }

  scope                = azurerm_management_group.main.id
  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_definition_name
  role_definition_id   = each.value.role_definition_id
  description          = each.value.description
  condition            = each.value.condition
  condition_version    = each.value.condition_version

  skip_service_principal_aad_check = true
}
