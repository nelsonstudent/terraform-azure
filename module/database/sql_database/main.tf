terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                          = var.sql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.sql_server_version
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_login_password
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled
  outbound_network_restriction_enabled = var.outbound_network_restriction_enabled

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [var.azuread_administrator] : []
    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      tenant_id                   = lookup(azuread_administrator.value, "tenant_id", null)
      azuread_authentication_only = lookup(azuread_administrator.value, "azuread_authentication_only", false)
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name                        = var.database_name
  server_id                   = azurerm_mssql_server.main.id
  collation                   = var.collation
  license_type                = var.license_type
  max_size_gb                 = var.max_size_gb
  sku_name                    = var.sku_name
  zone_redundant              = var.zone_redundant
  read_scale                  = var.read_scale
  read_replica_count          = var.read_replica_count
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes
  min_capacity                = var.min_capacity
  storage_account_type        = var.storage_account_type
  transparent_data_encryption_enabled = var.transparent_data_encryption_enabled
  ledger_enabled              = var.ledger_enabled
  maintenance_configuration_name = var.maintenance_configuration_name
  elastic_pool_id             = var.elastic_pool_id
  geo_backup_enabled          = var.geo_backup_enabled
  create_mode                 = var.create_mode
  creation_source_database_id = var.creation_source_database_id
  restore_point_in_time       = var.restore_point_in_time
  recover_database_id         = var.recover_database_id
  restore_dropped_database_id = var.restore_dropped_database_id

  dynamic "threat_detection_policy" {
    for_each = var.threat_detection_policy != null ? [var.threat_detection_policy] : []
    content {
      state                      = threat_detection_policy.value.state
      disabled_alerts            = lookup(threat_detection_policy.value, "disabled_alerts", null)
      email_account_admins       = lookup(threat_detection_policy.value, "email_account_admins", null)
      email_addresses            = lookup(threat_detection_policy.value, "email_addresses", null)
      retention_days             = lookup(threat_detection_policy.value, "retention_days", null)
      storage_account_access_key = lookup(threat_detection_policy.value, "storage_account_access_key", null)
      storage_endpoint           = lookup(threat_detection_policy.value, "storage_endpoint", null)
    }
  }

  dynamic "short_term_retention_policy" {
    for_each = var.short_term_retention_policy != null ? [var.short_term_retention_policy] : []
    content {
      retention_days             = short_term_retention_policy.value.retention_days
      backup_interval_in_hours   = lookup(short_term_retention_policy.value, "backup_interval_in_hours", null)
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = var.long_term_retention_policy != null ? [var.long_term_retention_policy] : []
    content {
      weekly_retention  = lookup(long_term_retention_policy.value, "weekly_retention", null)
      monthly_retention = lookup(long_term_retention_policy.value, "monthly_retention", null)
      yearly_retention  = lookup(long_term_retention_policy.value, "yearly_retention", null)
      week_of_year      = lookup(long_term_retention_policy.value, "week_of_year", null)
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      license_type
    ]
  }
}

# Firewall Rules
resource "azurerm_mssql_firewall_rule" "main" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Virtual Network Rules
resource "azurerm_mssql_virtual_network_rule" "main" {
  for_each = var.virtual_network_rules

  name      = each.key
  server_id = azurerm_mssql_server.main.id
  subnet_id = each.value.subnet_id
}

# Private Endpoint
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = var.private_endpoint_name != null ? var.private_endpoint_name : "${var.sql_server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.sql_server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = var.tags
}

# Auditing Policy
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  count = var.enable_auditing ? 1 : 0

  server_id                               = azurerm_mssql_server.main.id
  storage_endpoint                        = var.auditing_storage_endpoint
  storage_account_access_key              = var.auditing_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.auditing_retention_days
  log_monitoring_enabled                  = var.auditing_log_analytics_enabled

  depends_on = [
    azurerm_mssql_server.main
  ]
}

# Database Auditing Policy
resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  count = var.enable_auditing ? 1 : 0

  database_id                             = azurerm_mssql_database.main.id
  storage_endpoint                        = var.auditing_storage_endpoint
  storage_account_access_key              = var.auditing_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.auditing_retention_days
  log_monitoring_enabled                  = var.auditing_log_analytics_enabled

  depends_on = [
    azurerm_mssql_database.main
  ]
}

# Microsoft Defender for SQL
resource "azurerm_mssql_server_security_alert_policy" "main" {
  count = var.enable_threat_detection ? 1 : 0

  resource_group_name        = var.resource_group_name
  server_name                = azurerm_mssql_server.main.name
  state                      = "Enabled"
  storage_endpoint           = var.threat_detection_storage_endpoint
  storage_account_access_key = var.threat_detection_storage_account_access_key
  disabled_alerts            = var.threat_detection_disabled_alerts
  retention_days             = var.threat_detection_retention_days
  email_account_admins       = var.threat_detection_email_account_admins
  email_addresses            = var.threat_detection_email_addresses

  depends_on = [
    azurerm_mssql_server.main
  ]
}

# Vulnerability Assessment
resource "azurerm_mssql_server_vulnerability_assessment" "main" {
  count = var.enable_vulnerability_assessment ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main[0].id
  storage_container_path          = var.vulnerability_assessment_storage_container_path
  storage_account_access_key      = var.vulnerability_assessment_storage_account_access_key

  dynamic "recurring_scans" {
    for_each = var.vulnerability_assessment_recurring_scans != null ? [var.vulnerability_assessment_recurring_scans] : []
    content {
      enabled                   = recurring_scans.value.enabled
      email_subscription_admins = lookup(recurring_scans.value, "email_subscription_admins", false)
      emails                    = lookup(recurring_scans.value, "emails", null)
    }
  }

  depends_on = [
    azurerm_mssql_server_security_alert_policy.main
  ]
}

# Failover Group (opcional)
resource "azurerm_mssql_failover_group" "main" {
  count = var.create_failover_group ? 1 : 0

  name      = var.failover_group_name
  server_id = azurerm_mssql_server.main.id

  databases = [
    azurerm_mssql_database.main.id
  ]

  partner_server {
    id = var.failover_group_partner_server_id
  }

  read_write_endpoint_failover_policy {
    mode          = var.failover_group_read_write_endpoint_mode
    grace_minutes = var.failover_group_read_write_endpoint_mode == "Automatic" ? var.failover_group_grace_minutes : null
  }

  dynamic "read_only_endpoint_failover_policy" {
    for_each = var.read_only_endpoint_failover_policy_enabled ? [1] : []
    content {
      mode = "Enabled"
    }
  }

  tags = var.tags
}

# Elastic Pool (opcional)
resource "azurerm_mssql_elasticpool" "main" {
  count = var.create_elastic_pool ? 1 : 0

  name                = var.elastic_pool_name
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_mssql_server.main.name
  max_size_gb         = var.elastic_pool_max_size_gb
  zone_redundant      = var.elastic_pool_zone_redundant
  license_type        = var.elastic_pool_license_type

  sku {
    name     = var.elastic_pool_sku_name
    tier     = var.elastic_pool_sku_tier
    capacity = var.elastic_pool_sku_capacity
    family   = lookup(var.elastic_pool_sku, "family", null)
  }

  per_database_settings {
    min_capacity = var.elastic_pool_min_capacity
    max_capacity = var.elastic_pool_max_capacity
  }

  tags = var.tags
}

# Diagnostic Settings (Log Analytics)
resource "azurerm_monitor_diagnostic_setting" "database" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.database_name}-diagnostics"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_logs
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}
