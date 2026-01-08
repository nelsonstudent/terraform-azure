terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  https_traffic_only_enabled       = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication

  is_hns_enabled            = var.is_hns_enabled
  nfsv3_enabled             = var.nfsv3_enabled
  large_file_share_enabled  = var.large_file_share_enabled

  # Network Rules
  network_rules {
    default_action             = var.network_rules.default_action
    bypass                     = var.network_rules.bypass
    ip_rules                   = var.network_rules.ip_rules
    virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
  }

  # Blob Properties
  blob_properties {
    versioning_enabled       = var.blob_properties.versioning_enabled
    change_feed_enabled      = var.blob_properties.change_feed_enabled
    last_access_time_enabled = var.blob_properties.last_access_time_enabled

    delete_retention_policy {
      days = var.blob_properties.delete_retention_days
    }

    container_delete_retention_policy {
      days = var.blob_properties.container_delete_retention_days
    }
  }

  # Identity (Managed Identity)
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Blob Containers
resource "azurerm_storage_container" "containers" {
  for_each = { for container in var.containers : container.name => container }

  name                  = each.value.name
  storage_account_name = azurerm_storage_account.main.name
  container_access_type = each.value.container_access_type
}

# File Shares
resource "azurerm_storage_share" "file_shares" {
  for_each = { for share in var.file_shares : share.name => share }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.main.name
  quota                = each.value.quota
}

# Queues
resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# Tables
resource "azurerm_storage_table" "tables" {
  for_each = toset(var.tables)

  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# Advanced Threat Protection (opcional - comentado por padrão)
# resource "azurerm_advanced_threat_protection" "main" {
#   target_resource_id = azurerm_storage_account.main.id
#   enabled            = true
# }

# Management Policy para Lifecycle (exemplo comentado)
# resource "azurerm_storage_management_policy" "main" {
#   storage_account_id = azurerm_storage_account.main.id
#
#   rule {
#     name    = "rule1"
#     enabled = true
#     filters {
#       prefix_match = ["container1/prefix1"]
#       blob_types   = ["blockBlob"]
#     }
#     actions {
#       base_blob {
#         tier_to_cool_after_days_since_modification_greater_than    = 30
#         tier_to_archive_after_days_since_modification_greater_than = 90
#         delete_after_days_since_modification_greater_than          = 365
#       }
#       snapshot {
#         delete_after_days_since_creation_greater_than = 30
#       }
#     }
#   }
# }
