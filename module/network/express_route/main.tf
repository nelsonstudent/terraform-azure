terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# ExpressRoute Circuit
resource "azurerm_express_route_circuit" "main" {
  name                  = var.name
  resource_group_name   = var.resource_group_name
  location              = var.location
  service_provider_name = var.service_provider_name
  peering_location      = var.peering_location
  bandwidth_in_mbps     = var.bandwidth_in_mbps

  sku {
    tier   = var.sku.tier
    family = var.sku.family
  }

  allow_classic_operations = var.allow_classic_operations
  express_route_port_id    = var.express_route_port_id
  bandwidth_in_gbps        = var.bandwidth_in_gbps

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Azure Private Peering
resource "azurerm_express_route_circuit_peering" "azure_private" {
  count = var.enable_azure_private_peering && var.azure_private_peering != null ? 1 : 0

  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.main.name
  resource_group_name           = var.resource_group_name
  peer_asn                      = var.azure_private_peering.peer_asn
  primary_peer_address_prefix   = var.azure_private_peering.primary_peer_address_prefix
  secondary_peer_address_prefix = var.azure_private_peering.secondary_peer_address_prefix
  vlan_id                       = var.azure_private_peering.vlan_id
  shared_key                    = var.azure_private_peering.shared_key

  dynamic "ipv6" {
    for_each = var.azure_private_peering.ipv6 != null ? [var.azure_private_peering.ipv6] : []
    content {
      primary_peer_address_prefix   = ipv6.value.primary_peer_address_prefix
      secondary_peer_address_prefix = ipv6.value.secondary_peer_address_prefix
      enabled                       = ipv6.value.enabled

      dynamic "microsoft_peering" {
        for_each = var.azure_private_peering.microsoft_peering_config != null ? [var.azure_private_peering.microsoft_peering_config] : []
        content {
          advertised_public_prefixes = microsoft_peering.value.advertised_public_prefixes
          customer_asn               = microsoft_peering.value.customer_asn
          routing_registry_name      = microsoft_peering.value.routing_registry_name
        }
      }
    }
  }
}

# Microsoft Peering
resource "azurerm_express_route_circuit_peering" "microsoft" {
  count = var.enable_microsoft_peering && var.microsoft_peering != null ? 1 : 0

  peering_type                  = "MicrosoftPeering"
  express_route_circuit_name    = azurerm_express_route_circuit.main.name
  resource_group_name           = var.resource_group_name
  peer_asn                      = var.microsoft_peering.peer_asn
  primary_peer_address_prefix   = var.microsoft_peering.primary_peer_address_prefix
  secondary_peer_address_prefix = var.microsoft_peering.secondary_peer_address_prefix
  vlan_id                       = var.microsoft_peering.vlan_id
  shared_key                    = var.microsoft_peering.shared_key

  microsoft_peering_config {
    advertised_public_prefixes = var.microsoft_peering.advertised_public_prefixes
    customer_asn               = var.microsoft_peering.customer_asn
    routing_registry_name      = var.microsoft_peering.routing_registry_name
    advertised_communities     = var.microsoft_peering.advertised_communities
  }

  dynamic "ipv6" {
    for_each = var.microsoft_peering.ipv6 != null ? [var.microsoft_peering.ipv6] : []
    content {
      primary_peer_address_prefix   = ipv6.value.primary_peer_address_prefix
      secondary_peer_address_prefix = ipv6.value.secondary_peer_address_prefix
      enabled                       = ipv6.value.enabled

      microsoft_peering {
        advertised_public_prefixes = ipv6.value.microsoft_peering.advertised_public_prefixes
        customer_asn               = ipv6.value.microsoft_peering.customer_asn
        routing_registry_name      = ipv6.value.microsoft_peering.routing_registry_name
      }
    }
  }

  # Associate Route Filter if Microsoft Peering
  route_filter_id = var.create_route_filter && var.enable_microsoft_peering ? azurerm_route_filter.main[0].id : null

  depends_on = [
    azurerm_express_route_circuit.main
  ]
}

# Route Filter (for Microsoft Peering)
resource "azurerm_route_filter" "main" {
  count = var.create_route_filter ? 1 : 0

  name                = var.route_filter_name != null ? var.route_filter_name : "${var.name}-route-filter"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Route Filter Rules
resource "azurerm_route_filter_rule" "rules" {
  for_each = var.create_route_filter ? { for rule in var.route_filter_rules : rule.name => rule } : {}

  name            = each.value.name
  route_filter_name = azurerm_route_filter.main[0].name
  resource_group_name = var.resource_group_name
  access          = each.value.access
  rule_type       = each.value.rule_type
  communities     = each.value.communities
}

# ExpressRoute Circuit Authorization
resource "azurerm_express_route_circuit_authorization" "authorizations" {
  for_each = var.create_circuit_authorizations ? { for auth in var.circuit_authorizations : auth.name => auth } : {}

  name                       = each.value.name
  express_route_circuit_name = azurerm_express_route_circuit.main.name
  resource_group_name        = var.resource_group_name
}

# Virtual Network Gateway Connection
resource "azurerm_virtual_network_gateway_connection" "main" {
  count = var.create_gateway_connection && var.virtual_network_gateway_id != null ? 1 : 0

  name                = var.connection_name != null ? var.connection_name : "${var.name}-connection"
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "ExpressRoute"
  virtual_network_gateway_id = var.virtual_network_gateway_id
  express_route_circuit_id   = azurerm_express_route_circuit.main.id
  authorization_key          = var.authorization_key

  routing_weight                = var.routing_weight
  enable_bgp                    = false
  express_route_gateway_bypass  = var.express_route_gateway_bypass

  # FastPath - requires UltraPerformance or ErGw3AZ gateway
  connection_mode = var.enable_fastpath ? "FastPath" : "Default"

  tags = var.tags
}

# ExpressRoute Global Reach Connections
resource "azurerm_express_route_circuit_connection" "global_reach" {
  for_each = var.enable_global_reach ? { for conn in var.global_reach_connections : conn.name => conn } : {}

  name                = each.value.name
  peering_id          = var.enable_azure_private_peering ? azurerm_express_route_circuit_peering.azure_private[0].id : null
  peer_peering_id     = each.value.peer_express_route_circuit_id
  address_prefix_ipv4 = cidrsubnet("10.0.0.0/29", 0, 0)  # /29 subnet for Global Reach
  authorization_key   = each.value.authorization_key
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_express_route_circuit.main.id
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

# Locals
locals {
  circuit_provisioning_state = azurerm_express_route_circuit.main.service_provider_provisioning_state
  
  azure_private_peering_enabled = var.enable_azure_private_peering && var.azure_private_peering != null
  microsoft_peering_enabled     = var.enable_microsoft_peering && var.microsoft_peering != null
  
  service_key = azurerm_express_route_circuit.main.service_key
}
