output "id" {
  description = "ID do ExpressRoute Circuit"
  value       = azurerm_express_route_circuit.main.id
}

output "name" {
  description = "Nome do ExpressRoute Circuit"
  value       = azurerm_express_route_circuit.main.name
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_express_route_circuit.main.resource_group_name
}

output "location" {
  description = "Localização do ExpressRoute Circuit"
  value       = azurerm_express_route_circuit.main.location
}

output "service_key" {
  description = "Service Key do ExpressRoute Circuit (para fornecer ao service provider)"
  value       = azurerm_express_route_circuit.main.service_key
  sensitive   = true
}

output "service_provider_provisioning_state" {
  description = "Estado de provisionamento do service provider"
  value       = azurerm_express_route_circuit.main.service_provider_provisioning_state
}

output "circuit_provisioning_state" {
  description = "Estado de provisionamento do circuit"
  value       = local.circuit_provisioning_state
}

output "bandwidth_in_mbps" {
  description = "Largura de banda em Mbps"
  value       = azurerm_express_route_circuit.main.bandwidth_in_mbps
}

output "bandwidth_in_gbps" {
  description = "Largura de banda em Gbps (ExpressRoute Direct)"
  value       = azurerm_express_route_circuit.main.bandwidth_in_gbps
}

output "sku" {
  description = "Informações do SKU"
  value = {
    tier   = var.sku.tier
    family = var.sku.family
  }
}

output "service_provider_name" {
  description = "Nome do service provider"
  value       = azurerm_express_route_circuit.main.service_provider_name
}

output "peering_location" {
  description = "Localização do peering"
  value       = azurerm_express_route_circuit.main.peering_location
}

# Azure Private Peering
output "azure_private_peering_id" {
  description = "ID do Azure Private Peering"
  value       = local.azure_private_peering_enabled ? azurerm_express_route_circuit_peering.azure_private[0].id : null
}

output "azure_private_peering_state" {
  description = "Estado do Azure Private Peering"
  value       = local.azure_private_peering_enabled ? azurerm_express_route_circuit_peering.azure_private[0].peering_type : null
}

output "azure_private_peering_primary_azure_port" {
  description = "Porta primária do Azure para Private Peering"
  value       = local.azure_private_peering_enabled ? azurerm_express_route_circuit_peering.azure_private[0].primary_azure_port : null
}

output "azure_private_peering_secondary_azure_port" {
  description = "Porta secundária do Azure para Private Peering"
  value       = local.azure_private_peering_enabled ? azurerm_express_route_circuit_peering.azure_private[0].secondary_azure_port : null
}

output "azure_private_peering_azure_asn" {
  description = "ASN do Azure para Private Peering"
  value       = local.azure_private_peering_enabled ? azurerm_express_route_circuit_peering.azure_private[0].azure_asn : null
}

# Microsoft Peering
output "microsoft_peering_id" {
  description = "ID do Microsoft Peering"
  value       = local.microsoft_peering_enabled ? azurerm_express_route_circuit_peering.microsoft[0].id : null
}

output "microsoft_peering_state" {
  description = "Estado do Microsoft Peering"
  value       = local.microsoft_peering_enabled ? azurerm_express_route_circuit_peering.microsoft[0].peering_type : null
}

output "microsoft_peering_primary_azure_port" {
  description = "Porta primária do Azure para Microsoft Peering"
  value       = local.microsoft_peering_enabled ? azurerm_express_route_circuit_peering.microsoft[0].primary_azure_port : null
}

output "microsoft_peering_secondary_azure_port" {
  description = "Porta secundária do Azure para Microsoft Peering"
  value       = local.microsoft_peering_enabled ? azurerm_express_route_circuit_peering.microsoft[0].secondary_azure_port : null
}

output "microsoft_peering_azure_asn" {
  description = "ASN do Azure para Microsoft Peering"
  value       = local.microsoft_peering_enabled ? azurerm_express_route_circuit_peering.microsoft[0].azure_asn : null
}

# Route Filter
output "route_filter_id" {
  description = "ID do Route Filter"
  value       = var.create_route_filter ? azurerm_route_filter.main[0].id : null
}

output "route_filter_rules" {
  description = "Informações das regras do Route Filter"
  value = {
    for rule in var.route_filter_rules :
    rule.name => {
      id          = var.create_route_filter ? azurerm_route_filter_rule.rules[rule.name].id : null
      access      = rule.access
      rule_type   = rule.rule_type
      communities = rule.communities
    }
  }
}

# Circuit Authorizations
output "circuit_authorizations" {
  description = "Informações das autorizações do circuit"
  value = {
    for auth in var.circuit_authorizations :
    auth.name => {
      id                     = var.create_circuit_authorizations ? azurerm_express_route_circuit_authorization.authorizations[auth.name].id : null
      authorization_key      = var.create_circuit_authorizations ? azurerm_express_route_circuit_authorization.authorizations[auth.name].authorization_key : null
      authorization_use_status = var.create_circuit_authorizations ? azurerm_express_route_circuit_authorization.authorizations[auth.name].authorization_use_status : null
    }
  }
  sensitive = true
}

# Gateway Connection
output "gateway_connection_id" {
  description = "ID da conexão do gateway"
  value       = var.create_gateway_connection ? azurerm_virtual_network_gateway_connection.main[0].id : null
}

output "gateway_connection_name" {
  description = "Nome da conexão do gateway"
  value       = var.create_gateway_connection ? azurerm_virtual_network_gateway_connection.main[0].name : null
}

# Global Reach Connections
output "global_reach_connections" {
  description = "Informações das conexões Global Reach"
  value = {
    for conn in var.global_reach_connections :
    conn.name => {
      id                          = var.enable_global_reach ? azurerm_express_route_circuit_connection.global_reach[conn.name].id : null
      peer_express_route_circuit_id = conn.peer_express_route_circuit_id
    }
  }
}

# Summary
output "circuit_summary" {
  description = "Resumo das informações do ExpressRoute Circuit"
  value = {
    id                                = azurerm_express_route_circuit.main.id
    name                              = azurerm_express_route_circuit.main.name
    location                          = azurerm_express_route_circuit.main.location
    service_provider                  = azurerm_express_route_circuit.main.service_provider_name
    peering_location                  = azurerm_express_route_circuit.main.peering_location
    bandwidth_mbps                    = azurerm_express_route_circuit.main.bandwidth_in_mbps
    sku_tier                          = var.sku.tier
    sku_family                        = var.sku.family
    provisioning_state                = azurerm_express_route_circuit.main.service_provider_provisioning_state
    azure_private_peering_enabled     = local.azure_private_peering_enabled
    microsoft_peering_enabled         = local.microsoft_peering_enabled
    global_reach_enabled              = var.enable_global_reach
    gateway_connection_created        = var.create_gateway_connection
    route_filter_created              = var.create_route_filter
  }
}

# Peering Information
output "peering_info" {
  description = "Informações consolidadas dos peerings"
  value = {
    azure_private = local.azure_private_peering_enabled ? {
      id                            = azurerm_express_route_circuit_peering.azure_private[0].id
      vlan_id                       = var.azure_private_peering.vlan_id
      peer_asn                      = var.azure_private_peering.peer_asn
      primary_peer_address_prefix   = var.azure_private_peering.primary_peer_address_prefix
      secondary_peer_address_prefix = var.azure_private_peering.secondary_peer_address_prefix
      azure_asn                     = azurerm_express_route_circuit_peering.azure_private[0].azure_asn
    } : null
    
    microsoft = local.microsoft_peering_enabled ? {
      id                            = azurerm_express_route_circuit_peering.microsoft[0].id
      vlan_id                       = var.microsoft_peering.vlan_id
      peer_asn                      = var.microsoft_peering.peer_asn
      primary_peer_address_prefix   = var.microsoft_peering.primary_peer_address_prefix
      secondary_peer_address_prefix = var.microsoft_peering.secondary_peer_address_prefix
      azure_asn                     = azurerm_express_route_circuit_peering.microsoft[0].azure_asn
      advertised_public_prefixes    = var.microsoft_peering.advertised_public_prefixes
    } : null
  }
}

# FastPath Status
output "fastpath_enabled" {
  description = "Indica se FastPath está habilitado"
  value       = var.create_gateway_connection ? var.enable_fastpath : null
}

# Connection Status
output "is_connected" {
  description = "Indica se o circuit está provisionado e conectado"
  value       = azurerm_express_route_circuit.main.service_provider_provisioning_state == "Provisioned"
}

# Lists for easy reference
output "peering_types_enabled" {
  description = "Lista de tipos de peering habilitados"
  value = compact([
    local.azure_private_peering_enabled ? "AzurePrivatePeering" : "",
    local.microsoft_peering_enabled ? "MicrosoftPeering" : ""
  ])
}

output "authorization_names" {
  description = "Lista de nomes das autorizações criadas"
  value       = var.create_circuit_authorizations ? [for auth in var.circuit_authorizations : auth.name] : []
}