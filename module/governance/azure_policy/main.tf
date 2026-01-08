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
data "azurerm_subscription" "current" {}

locals {
  # Display name padrão
  effective_display_name = coalesce(var.display_name, var.name)
  
  # Policy rule convertido para JSON se necessário
  policy_rule_json = var.policy_rule != null ? (
    can(jsondecode(var.policy_rule)) ? var.policy_rule : jsonencode(var.policy_rule)
  ) : null
  
  # Scope padrão (subscription atual se não especificado)
  effective_scope = coalesce(
    var.scope,
    data.azurerm_subscription.current.id
  )
  
  # Remediation scope padrão
  effective_remediation_scope = coalesce(
    var.remediation_scope,
    var.scope,
    data.azurerm_subscription.current.id
  )
}

# Policy Definition (Subscription Scope)
resource "azurerm_policy_definition" "subscription" {
  count = var.policy_type == "definition" && var.management_group_id == null ? 1 : 0

  name         = var.name
  policy_type  = "Custom"
  mode         = var.mode
  display_name = local.effective_display_name
  description  = var.description

  metadata    = var.metadata
  parameters  = var.parameters
  policy_rule = local.policy_rule_json

  lifecycle {
    create_before_destroy = true
  }
}

# Policy Definition (Management Group Scope)
resource "azurerm_policy_definition" "management_group" {
  count = var.policy_type == "definition" && var.management_group_id != null ? 1 : 0

  name                = var.name
  policy_type         = "Custom"
  mode                = var.mode
  display_name        = local.effective_display_name
  description         = var.description
  management_group_id = var.management_group_id

  metadata    = var.metadata
  parameters  = var.parameters
  policy_rule = local.policy_rule_json

  lifecycle {
    create_before_destroy = true
  }
}

# Policy Set Definition / Initiative (Subscription Scope)
resource "azurerm_policy_set_definition" "subscription" {
  count = var.policy_type == "set_definition" && var.management_group_id == null ? 1 : 0

  name         = var.name
  policy_type  = "Custom"
  display_name = local.effective_display_name
  description  = var.description

  metadata   = var.metadata
  parameters = var.parameters

  dynamic "policy_definition_reference" {
    for_each = var.policy_definitions
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      parameter_values     = policy_definition_reference.value.parameter_values
      reference_id         = policy_definition_reference.value.reference_id
      policy_group_names   = policy_definition_reference.value.policy_group_names
    }
  }

  dynamic "policy_definition_group" {
    for_each = var.policy_definition_groups
    content {
      name                            = policy_definition_group.value.name
      display_name                    = policy_definition_group.value.display_name
      category                        = policy_definition_group.value.category
      description                     = policy_definition_group.value.description
      additional_metadata_resource_id = policy_definition_group.value.additional_metadata_resource_id
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Policy Set Definition / Initiative (Management Group Scope)
resource "azurerm_policy_set_definition" "management_group" {
  count = var.policy_type == "set_definition" && var.management_group_id != null ? 1 : 0

  name                = var.name
  policy_type         = "Custom"
  display_name        = local.effective_display_name
  description         = var.description
  management_group_id = var.management_group_id

  metadata   = var.metadata
  parameters = var.parameters

  dynamic "policy_definition_reference" {
    for_each = var.policy_definitions
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      parameter_values     = policy_definition_reference.value.parameter_values
      reference_id         = policy_definition_reference.value.reference_id
      policy_group_names   = policy_definition_reference.value.policy_group_names
    }
  }

  dynamic "policy_definition_group" {
    for_each = var.policy_definition_groups
    content {
      name                            = policy_definition_group.value.name
      display_name                    = policy_definition_group.value.display_name
      category                        = policy_definition_group.value.category
      description                     = policy_definition_group.value.description
      additional_metadata_resource_id = policy_definition_group.value.additional_metadata_resource_id
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Policy Assignment
resource "azurerm_resource_policy_assignment" "main" {
  count = var.policy_type == "assignment" ? 1 : 0

  name                 = var.name
  resource_id          = local.effective_scope
  policy_definition_id = var.policy_definition_id
  display_name         = local.effective_display_name
  description          = var.description
  enforce              = var.enforce
  location             = var.location
  not_scopes           = var.not_scopes
  parameters           = var.parameters
  metadata             = var.metadata

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "non_compliance_message" {
    for_each = var.non_compliance_messages
    content {
      content                        = non_compliance_message.value.message
      policy_definition_reference_id = non_compliance_message.value.policy_definition_reference_id
    }
  }

  dynamic "overrides" {
    for_each = var.overrides
    content {
      value = overrides.value.value
      
      dynamic "selectors" {
        for_each = overrides.value.selectors != null ? overrides.value.selectors : []
        content {
          kind   = selectors.value.kind
          in     = selectors.value.in
          not_in = selectors.value.not_in
        }
      }
    }
  }

  dynamic "resource_selectors" {
    for_each = var.resource_selectors
    content {
      name = resource_selectors.value.name
      
      dynamic "selectors" {
        for_each = resource_selectors.value.selectors
        content {
          kind   = selectors.value.kind
          in     = selectors.value.in
          not_in = selectors.value.not_in
        }
      }
    }
  }
}

# Policy Exemption
resource "azurerm_resource_policy_exemption" "main" {
  count = var.policy_type == "exemption" ? 1 : 0

  name                            = var.name
  resource_id                     = local.effective_scope
  policy_assignment_id            = var.policy_assignment_id
  exemption_category              = var.exemption_category
  display_name                    = local.effective_display_name
  description                     = var.description
  expires_on                      = var.expires_on
  policy_definition_reference_ids = var.policy_definition_reference_ids
  metadata                        = var.metadata_exemption
}

# Remediation Task
resource "azurerm_subscription_policy_remediation" "main" {
  count = var.policy_type == "assignment" && var.create_remediation_task ? 1 : 0

  name                 = "${var.name}-remediation"
  subscription_id      = local.effective_remediation_scope
  policy_assignment_id = azurerm_resource_policy_assignment.main[0].id
  
  resource_discovery_mode = var.resource_discovery_mode
  failure_percentage      = var.failure_percentage
  parallel_deployments    = var.parallel_deployments
  resource_count          = var.resource_count
  location_filters        = var.location != null ? [var.location] : null

  depends_on = [
    azurerm_resource_policy_assignment.main
  ]
}
