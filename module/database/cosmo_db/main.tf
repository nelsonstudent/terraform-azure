terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                                  = var.cosmosdb_account_name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  offer_type                            = var.offer_type
  kind                                  = var.kind
  automatic_failover_enabled            = var.enable_automatic_failover
  multiple_write_locations_enabled      = var.enable_multiple_write_locations
  is_virtual_network_filter_enabled     = var.is_virtual_network_filter_enabled
  public_network_access_enabled         = var.public_network_access_enabled
  free_tier_enabled                     = var.enable_free_tier
  analytical_storage_enabled            = var.analytical_storage_enabled
  access_key_metadata_writes_enabled    = var.access_key_metadata_writes_enabled
  local_authentication_disabled         = var.local_authentication_disabled
  network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services
  network_acl_bypass_ids                = var.network_acl_bypass_ids
  default_identity_type                 = var.default_identity_type

  # Consistency Policy
  consistency_policy {
    consistency_level       = var.consistency_policy.consistency_level
    max_interval_in_seconds = lookup(var.consistency_policy, "max_interval_in_seconds", null)
    max_staleness_prefix    = lookup(var.consistency_policy, "max_staleness_prefix", null)
  }

  # Geo Locations
  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = lookup(geo_location.value, "zone_redundant", false)
    }
  }

  # Capabilities
  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  # Virtual Network Rules
  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id                                   = virtual_network_rule.value.id
      ignore_missing_vnet_service_endpoint = lookup(virtual_network_rule.value, "ignore_missing_vnet_service_endpoint", false)
    }
  }

  # Backup
  dynamic "backup" {
    for_each = var.backup_policy != null ? [var.backup_policy] : []
    content {
      type                = backup.value.type
      interval_in_minutes = lookup(backup.value, "interval_in_minutes", null)
      retention_in_hours  = lookup(backup.value, "retention_in_hours", null)
      storage_redundancy  = lookup(backup.value, "storage_redundancy", null)
    }
  }

  # CORS
  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_origins    = cors_rule.value.allowed_origins
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_headers    = cors_rule.value.allowed_headers
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  # Analytical Storage
  dynamic "analytical_storage" {
    for_each = var.analytical_storage_enabled ? [1] : []
    content {
      schema_type = var.analytical_storage_schema_type
    }
  }

  # Capacity
  dynamic "capacity" {
    for_each = var.capacity_total_throughput_limit != null ? [1] : []
    content {
      total_throughput_limit = var.capacity_total_throughput_limit
    }
  }

  tags = var.tags
}

# SQL Database
resource "azurerm_cosmosdb_sql_database" "main" {
  for_each = var.sql_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = lookup(each.value, "throughput", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# SQL Containers
resource "azurerm_cosmosdb_sql_container" "main" {
  for_each = var.sql_containers

  name                  = each.key
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = each.value.database_name
  partition_key_paths    = [each.value.partition_key_path]
  partition_key_version = lookup(each.value, "partition_key_version", null)
  throughput            = lookup(each.value, "throughput", null)
  default_ttl           = lookup(each.value, "default_ttl", null)
  analytical_storage_ttl = lookup(each.value, "analytical_storage_ttl", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }

  dynamic "indexing_policy" {
    for_each = lookup(each.value, "indexing_policy", null) != null ? [each.value.indexing_policy] : []
    content {
      indexing_mode = lookup(indexing_policy.value, "indexing_mode", "consistent")

      dynamic "included_path" {
        for_each = lookup(indexing_policy.value, "included_paths", [])
        content {
          path = included_path.value
        }
      }

      dynamic "excluded_path" {
        for_each = lookup(indexing_policy.value, "excluded_paths", [])
        content {
          path = excluded_path.value
        }
      }

      dynamic "composite_index" {
        for_each = lookup(indexing_policy.value, "composite_indexes", [])
        content {
          dynamic "index" {
            for_each = composite_index.value
            content {
              path  = index.value.path
              order = index.value.order
            }
          }
        }
      }

      dynamic "spatial_index" {
        for_each = lookup(indexing_policy.value, "spatial_indexes", [])
        content {
          path = spatial_index.value
        }
      }
    }
  }

  dynamic "unique_key" {
    for_each = lookup(each.value, "unique_keys", [])
    content {
      paths = unique_key.value.paths
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = lookup(each.value, "conflict_resolution_policy", null) != null ? [each.value.conflict_resolution_policy] : []
    content {
      mode                          = conflict_resolution_policy.value.mode
      conflict_resolution_path      = lookup(conflict_resolution_policy.value, "conflict_resolution_path", null)
      conflict_resolution_procedure = lookup(conflict_resolution_policy.value, "conflict_resolution_procedure", null)
    }
  }

  depends_on = [
    azurerm_cosmosdb_sql_database.main
  ]
}

# MongoDB Database
resource "azurerm_cosmosdb_mongo_database" "main" {
  for_each = var.mongo_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = lookup(each.value, "throughput", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# MongoDB Collections
resource "azurerm_cosmosdb_mongo_collection" "main" {
  for_each = var.mongo_collections

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = each.value.database_name
  shard_key           = lookup(each.value, "shard_key", null)
  throughput          = lookup(each.value, "throughput", null)
  default_ttl_seconds = lookup(each.value, "default_ttl_seconds", null)
  analytical_storage_ttl = lookup(each.value, "analytical_storage_ttl", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }

  dynamic "index" {
    for_each = lookup(each.value, "indexes", [])
    content {
      keys   = index.value.keys
      unique = lookup(index.value, "unique", false)
    }
  }

  depends_on = [
    azurerm_cosmosdb_mongo_database.main
  ]
}

# Cassandra Keyspace
resource "azurerm_cosmosdb_cassandra_keyspace" "main" {
  for_each = var.cassandra_keyspaces

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = lookup(each.value, "throughput", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# Cassandra Tables
resource "azurerm_cosmosdb_cassandra_table" "main" {
  for_each = var.cassandra_tables
  name                = each.key
  cassandra_keyspace_id  = azurerm_cosmosdb_cassandra_keyspace.main[each.value.keyspace_name].id
  throughput          = lookup(each.value, "throughput", null)
  default_ttl         = lookup(each.value, "default_ttl", null)
  analytical_storage_ttl = lookup(each.value, "analytical_storage_ttl", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }

  schema {
    dynamic "column" {
      for_each = each.value.schema.columns
      content {
        name = column.value.name
        type = column.value.type
      }
    }

    dynamic "partition_key" {
      for_each = each.value.schema.partition_keys
      content {
        name = partition_key.value
      }
    }

    dynamic "cluster_key" {
      for_each = lookup(each.value.schema, "cluster_keys", [])
      content {
        name     = cluster_key.value.name
        order_by = cluster_key.value.order_by
      }
    }
  }

  depends_on = [
    azurerm_cosmosdb_cassandra_keyspace.main
  ]
}

# Gremlin Database (Graph)
resource "azurerm_cosmosdb_gremlin_database" "main" {
  for_each = var.gremlin_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = lookup(each.value, "throughput", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# Gremlin Graphs
resource "azurerm_cosmosdb_gremlin_graph" "main" {
  for_each = var.gremlin_graphs

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = each.value.database_name
  partition_key_path  = each.value.partition_key_path
  throughput          = lookup(each.value, "throughput", null)
  default_ttl         = lookup(each.value, "default_ttl", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }

  dynamic "index_policy" {
    for_each = lookup(each.value, "indexing_policy", null) != null ? [each.value.indexing_policy] : []
    content {
      indexing_mode  = lookup(index_policy.value, "indexing_mode", "consistent")
      automatic      = lookup(index_policy.value, "automatic", true)
      included_paths = lookup(index_policy.value, "included_paths", null)
      excluded_paths = lookup(index_policy.value, "excluded_paths", null)  
    }
  }

  dynamic "unique_key" {
    for_each = lookup(each.value, "unique_keys", [])
    content {
      paths = unique_key.value.paths
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = lookup(each.value, "conflict_resolution_policy", null) != null ? [each.value.conflict_resolution_policy] : []
    content {
      mode                          = conflict_resolution_policy.value.mode
      conflict_resolution_path      = lookup(conflict_resolution_policy.value, "conflict_resolution_path", null)
      conflict_resolution_procedure = lookup(conflict_resolution_policy.value, "conflict_resolution_procedure", null)
    }
  }

  depends_on = [
    azurerm_cosmosdb_gremlin_database.main
  ]
}

# Table (Key-Value)
resource "azurerm_cosmosdb_table" "main" {
  for_each = var.tables

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = lookup(each.value, "throughput", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# Private Endpoint
resource "azurerm_private_endpoint" "main" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = var.private_endpoint_name != null ? var.private_endpoint_name : "${var.cosmosdb_account_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.cosmosdb_account_name}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    subresource_names              = [var.private_endpoint_subresource_name]
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

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${var.cosmosdb_account_name}-diagnostics"
  target_resource_id         = azurerm_cosmosdb_account.main.id
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
