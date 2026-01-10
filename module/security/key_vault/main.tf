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

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  rbac_authorization_enabled       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  public_network_access_enabled   = var.public_network_access_enabled

  network_acls {
    bypass                     = var.network_acls.bypass
    default_action             = var.network_acls.default_action
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  dynamic "contact" {
    for_each = var.contact_email != null ? [1] : []
    content {
      email = var.contact_email
    }
  }

  tags = var.tags
}

# Access Policies (usado quando RBAC está desabilitado)
resource "azurerm_key_vault_access_policy" "policy" {
  for_each = var.enable_rbac_authorization ? {} : { for idx, policy in var.access_policies : idx => policy }

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = coalesce(each.value.tenant_id, var.tenant_id)
  object_id    = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}

# Secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id
  content_type = each.value.content_type

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.policy
  ]
}

# Keys
resource "azurerm_key_vault_key" "keys" {
  for_each = var.keys

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  curve        = each.value.curve
  key_opts     = each.value.key_opts

  expiration_date = each.value.expiration_date

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.policy
  ]
}

# Certificates
resource "azurerm_key_vault_certificate" "certificates" {
  for_each = var.certificates

  name         = each.key
  key_vault_id = azurerm_key_vault.main.id

  dynamic "certificate" {
    for_each = each.value.contents != null ? [1] : []
    content {
      contents = each.value.contents
      password = each.value.password
    }
  }

  dynamic "certificate_policy" {
    for_each = each.value.policy != null ? [each.value.policy] : []
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_parameters.name
      }

      key_properties {
        exportable = certificate_policy.value.key_properties.exportable
        key_size   = certificate_policy.value.key_properties.key_size
        key_type   = certificate_policy.value.key_properties.key_type
        reuse_key  = certificate_policy.value.key_properties.reuse_key
      }

      secret_properties {
        content_type = certificate_policy.value.secret_properties.content_type
      }

      dynamic "x509_certificate_properties" {
        for_each = certificate_policy.value.x509_certificate_properties != null ? [certificate_policy.value.x509_certificate_properties] : []
        content {
          key_usage          = x509_certificate_properties.value.key_usage
          subject            = x509_certificate_properties.value.subject
          validity_in_months = x509_certificate_properties.value.validity_in_months

          dynamic "subject_alternative_names" {
            for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []
            content {
              dns_names = subject_alternative_names.value.dns_names
              emails    = subject_alternative_names.value.emails
              upns      = subject_alternative_names.value.upns
            }
          }
        }
      }

      dynamic "lifetime_action" {
        for_each = certificate_policy.value.lifetime_action != null ? certificate_policy.value.lifetime_action : []
        content {
          action {
            action_type = lifetime_action.value.action.action_type
          }

          trigger {
            days_before_expiry  = lifetime_action.value.trigger.days_before_expiry
            lifetime_percentage = lifetime_action.value.trigger.lifetime_percentage
          }
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [
    azurerm_key_vault_access_policy.policy
  ]
}

# Private Endpoint
resource "azurerm_private_endpoint" "main" {
  count = var.private_endpoint_enabled ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "${var.name}-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.diagnostic_settings.enabled ? 1 : 0

  name                           = "${var.name}-diag"
  target_resource_id             = azurerm_key_vault.main.id
  log_analytics_workspace_id     = var.diagnostic_settings.log_analytics_workspace_id
  storage_account_id             = var.diagnostic_settings.storage_account_id
  eventhub_authorization_rule_id = var.diagnostic_settings.eventhub_authorization_rule_id
  eventhub_name                  = var.diagnostic_settings.eventhub_name

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.logs != null ? var.diagnostic_settings.logs : [
      { category = "AuditEvent", enabled = true },
      { category = "AzurePolicyEvaluationDetails", enabled = true }
    ]
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_settings.metrics != null ? var.diagnostic_settings.metrics : [
      { category = "AllMetrics", enabled = true }
    ]
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}
