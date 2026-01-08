terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Azure Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku_name

  non_ssl_port_enabled           = var.enable_non_ssl_port
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  # Premium features
  replicas_per_master   = var.sku_name == "Premium" ? var.replicas_per_master : null
  replicas_per_primary  = var.sku_name == "Premium" ? var.replicas_per_primary : null
  shard_count           = var.sku_name == "Premium" ? var.shard_count : null
  subnet_id             = var.sku_name == "Premium" ? var.subnet_id : null
  private_static_ip_address = var.private_static_ip_address
  zones                 = var.sku_name == "Premium" ? var.zones : null

  redis_version = var.redis_version

  # Redis Configuration
  redis_configuration {
    aof_backup_enabled              = var.redis_configuration.aof_backup_enabled
    aof_storage_connection_string_0 = var.redis_configuration.aof_storage_connection_string_0
    aof_storage_connection_string_1 = var.redis_configuration.aof_storage_connection_string_1
    authentication_enabled          = var.redis_configuration.enable_authentication
    maxmemory_reserved              = var.redis_configuration.maxmemory_reserved
    maxmemory_delta                 = var.redis_configuration.maxmemory_delta
    maxmemory_policy                = var.redis_configuration.maxmemory_policy
    maxfragmentationmemory_reserved = var.redis_configuration.maxfragmentationmemory_reserved
    rdb_backup_enabled              = var.redis_configuration.rdb_backup_enabled
    rdb_backup_frequency            = var.redis_configuration.rdb_backup_frequency
    rdb_backup_max_snapshot_count   = var.redis_configuration.rdb_backup_max_snapshot_count
    rdb_storage_connection_string   = var.redis_configuration.rdb_storage_connection_string
    notify_keyspace_events          = var.redis_configuration.notify_keyspace_events
  }

  # Managed Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  tenant_settings = var.tenant_settings

  tags = var.tags

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      # Evitar recriação desnecessária
      redis_configuration[0].rdb_storage_connection_string,
      redis_configuration[0].aof_storage_connection_string_0,
      redis_configuration[0].aof_storage_connection_string_1,
    ]
  }
}

# Patch Schedule
resource "azurerm_redis_patch_schedule" "main" {
  count = length(var.patch_schedule) > 0 ? 1 : 0

  redis_cache_id = azurerm_redis_cache.main.id

  dynamic "patch_schedule" {
    for_each = var.patch_schedule
    content {
      day_of_week        = patch_schedule.value.day_of_week
      start_hour_utc     = patch_schedule.value.start_hour_utc
      maintenance_window = patch_schedule.value.maintenance_window
    }
  }
}

# Firewall Rules
resource "azurerm_redis_firewall_rule" "rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name                = each.value.name
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip            = each.value.start_ip_address
  end_ip              = each.value.end_ip_address
}

# Private Endpoint
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
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
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_redis_cache.main.id
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

# Outputs locais para uso interno do módulo
locals {
  redis_connection_string = azurerm_redis_cache.main.primary_connection_string
  redis_host              = azurerm_redis_cache.main.hostname
  redis_port_ssl          = azurerm_redis_cache.main.ssl_port
  redis_port              = azurerm_redis_cache.main.port
}
