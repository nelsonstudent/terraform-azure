terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.create_mode == "Default" ? var.administrator_login : null
  administrator_password = var.create_mode == "Default" ? var.administrator_password : null

  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  storage_tier = var.storage_tier
  version    = var.version
  zone       = var.zone

  auto_grow_enabled = var.auto_grow_enabled

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  create_mode                       = var.create_mode
  point_in_time_restore_time_in_utc = var.point_in_time_restore_time_in_utc
  source_server_id                  = var.source_server_id
  replication_role                  = var.replication_role

  # Network
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = var.public_network_access_enabled

  # High Availability
  dynamic "high_availability" {
    for_each = var.high_availability != null ? [var.high_availability] : []
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  # Authentication
  dynamic "authentication" {
    for_each = var.authentication != null ? [var.authentication] : []
    content {
      active_directory_auth_enabled = authentication.value.active_directory_auth_enabled
      password_auth_enabled         = authentication.value.password_auth_enabled
      tenant_id                     = authentication.value.tenant_id
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : []
    }
  }

  # Customer Managed Key
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id                     = customer_managed_key.value.key_vault_key_id
      primary_user_assigned_identity_id    = customer_managed_key.value.primary_user_assigned_identity_id
      geo_backup_key_vault_key_id          = customer_managed_key.value.geo_backup_key_vault_key_id
      geo_backup_user_assigned_identity_id = customer_managed_key.value.geo_backup_user_assigned_identity_id
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

# PostgreSQL Configurations
resource "azurerm_postgresql_flexible_server_configuration" "config" {
  for_each = var.postgresql_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}

# Databases
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each = { for db in var.databases : db.name => db }

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = each.value.charset
  collation = each.value.collation
}

# Firewall Rules
resource "azurerm_postgresql_flexible_server_firewall_rule" "rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name             = each.value.name
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Active Directory Administrator (se habilitado)
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "admin" {
  count = var.authentication != null && var.authentication.active_directory_auth_enabled ? 1 : 0

  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.authentication.tenant_id
  object_id           = var.identity_type != null ? azurerm_postgresql_flexible_server.main.identity[0].principal_id : ""
  principal_name      = var.administrator_login
  principal_type      = "ServicePrincipal"
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(var.diagnostic_logs)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(var.diagnostic_metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Locais para uso interno
locals {
  fqdn = azurerm_postgresql_flexible_server.main.fqdn
  
  # Connection string básica
  connection_string = var.delegated_subnet_id != null ? (
    "host=${local.fqdn} port=5432 dbname=postgres user=${var.administrator_login} password=${var.administrator_password} sslmode=require"
  ) : (
    "host=${local.fqdn} port=5432 dbname=postgres user=${var.administrator_login} password=${var.administrator_password} sslmode=require"
  )
  
  # Verificar se está em VNet
  is_vnet_integrated = var.delegated_subnet_id != null
}
