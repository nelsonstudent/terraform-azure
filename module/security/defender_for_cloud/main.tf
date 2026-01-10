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
  
  # Criar mapa de pricing combinando resource_type individual e security_center_pricing
  pricing_map = merge(
    var.resource_type != null && var.tier != null ? {
      (var.resource_type) = {
        tier       = var.tier
        subplan    = var.subplan
        extensions = var.extensions
      }
    } : {},
    var.security_center_pricing
  )

  # Contatos de segurança - combinar variáveis simplificadas com lista detalhada
  security_contacts = concat(
    var.security_contacts,
    var.email_security_contact != null ? [{
      email               = var.email_security_contact
      phone               = var.phone_security_contact
      alert_notifications = var.alert_notifications_enabled
      alerts_to_admins    = var.alerts_to_admins_enabled
      name                = "default1"
    }] : []
  )
}

# Security Center Pricing (Defender Plans)
resource "azurerm_security_center_subscription_pricing" "main" {
  for_each = local.pricing_map

  tier          = each.value.tier
  resource_type = each.key
  subplan       = each.value.subplan

  dynamic "extension" {
    for_each = each.value.extensions != null ? each.value.extensions : []
    content {
      name                             = extension.value.name
      additional_extension_properties  = extension.value.additional_extension_properties
    }
  }
}

# Security Center Contact
resource "azurerm_security_center_contact" "main" {
  for_each = { for idx, contact in local.security_contacts : contact.name => contact }

  email               = each.value.email
  phone               = each.value.phone
  alert_notifications = each.value.alert_notifications
  alerts_to_admins    = each.value.alerts_to_admins
  name                = each.value.name
}

# Auto Provisioning
resource "azurerm_security_center_auto_provisioning" "main" {
  count = var.auto_provisioning.enabled ? 1 : 0

  auto_provision = "On"
}

# Security Center Workspace
resource "azurerm_security_center_workspace" "main" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  scope        = "/subscriptions/${local.subscription_id}"
  workspace_id = var.log_analytics_workspace_id
}

# Assessment Metadata (Custom Assessments)
resource "azurerm_security_center_assessment_policy" "main" {
  for_each = var.assessments_settings

  display_name = each.key
  severity     = "Medium"
  description  = "Custom assessment: ${each.key}"

  lifecycle {
    create_before_destroy = true
  }
}

# Workflow Automation
resource "azurerm_security_center_automation" "main" {
  for_each = { for idx, wa in var.workflow_automations : wa.name => wa }

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  description         = each.value.description
  enabled             = each.value.enabled

  scopes = each.value.scopes

  dynamic "source" {
    for_each = each.value.sources
    content {
      event_source = source.value.event_source

      dynamic "rule_set" {
        for_each = source.value.rule_sets != null ? source.value.rule_sets : []
        content {
          dynamic "rule" {
            for_each = rule_set.value.rules
            content {
              property_path  = rule.value.property_path
              operator       = rule.value.operator
              expected_value = rule.value.expected_value
              property_type  = rule.value.property_type
            }
          }
        }
      }
    }
  }

  dynamic "action" {
    for_each = each.value.actions
    content {
      type               = action.value.type
      resource_id        = action.value.resource_id
      trigger_url        = action.value.trigger_url
      connection_string  = action.value.connection_string
    }
  }

  tags = merge(var.tags, each.value.tags)
}

# Just-In-Time VM Access Policy
resource "azurerm_security_center_jit_network_access_policy" "main" {
  for_each = { for idx, jit in var.jit_policies : jit.name => jit }

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  dynamic "virtual_machine" {
    for_each = each.value.virtual_machine_ids
    content {
      virtual_machine_id = virtual_machine.value
    }
  }

  dynamic "policy" {
    for_each = each.value.rules
    content {
      port                        = policy.value.number
      protocol                    = policy.value.protocol

      allowed_source_address_prefix = [policy.value.allowed_source_address_prefix]
      max_request_access_duration   = policy.value.max_request_access_duration
    }
  }
}

# Advanced Threat Protection
resource "azurerm_advanced_threat_protection" "main" {
  for_each = { for idx, atp in var.advanced_threat_protection : idx => atp }

  target_resource_id = each.value.target_resource_id
  enabled            = each.value.enabled
}

# Security Center Setting - MCAS (Microsoft Cloud App Security)
resource "azurerm_security_center_setting" "mcas" {
  setting_name = "MCAS"
  enabled      = true
}

# Security Center Setting - WDATP (Windows Defender ATP)
resource "azurerm_security_center_setting" "wdatp" {
  setting_name = "WDATP"
  enabled      = true
}

# Security Center Setting - Sentinel
resource "azurerm_security_center_setting" "sentinel" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  setting_name = "Sentinel"
  enabled      = true
}
