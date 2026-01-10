output "id" {
  description = "ID da Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "Nome da Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_virtual_network.main.resource_group_name
}

output "location" {
  description = "Localização da Virtual Network"
  value       = azurerm_virtual_network.main.location
}

output "address_space" {
  description = "Blocos de endereços da VNet"
  value       = azurerm_virtual_network.main.address_space
}

output "guid" {
  description = "GUID da Virtual Network"
  value       = azurerm_virtual_network.main.guid
}

output "dns_servers" {
  description = "Servidores DNS configurados"
  value       = azurerm_virtual_network.main.dns_servers
}

# Subnets
output "subnet_ids" {
  description = "Map de IDs das subnets"
  value       = local.subnet_ids
}

output "subnets" {
  description = "Informações detalhadas das subnets"
  value = {
    for k, v in azurerm_subnet.subnets : k => {
      id               = v.id
      name             = v.name
      address_prefixes = v.address_prefixes
      service_endpoints = v.service_endpoints
    }
  }
}

output "subnet_address_prefixes" {
  description = "Map de address prefixes por subnet"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.address_prefixes
  }
}

# Network Security Groups
output "nsg_ids" {
  description = "Map de IDs dos Network Security Groups"
  value       = local.nsg_ids
}

output "network_security_groups" {
  description = "Informações detalhadas dos NSGs"
  value = {
    for k, v in azurerm_network_security_group.nsgs : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

output "nsg_subnet_associations" {
  description = "Associações entre NSGs e Subnets"
  value = {
    for k, v in azurerm_subnet_network_security_group_association.nsg_associations : k => {
      subnet_id = v.subnet_id
      nsg_id    = v.network_security_group_id
    }
  }
}

# Route Tables
output "route_table_ids" {
  description = "Map de IDs das Route Tables"
  value       = local.route_table_ids
}

output "route_tables" {
  description = "Informações detalhadas das Route Tables"
  value = {
    for k, v in azurerm_route_table.route_tables : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

output "route_table_subnet_associations" {
  description = "Associações entre Route Tables e Subnets"
  value = {
    for k, v in azurerm_subnet_route_table_association.rt_associations : k => {
      subnet_id      = v.subnet_id
      route_table_id = v.route_table_id
    }
  }
}

# VNet Peering
output "vnet_peerings" {
  description = "Informações dos VNet Peerings"
  value = {
    for k, v in azurerm_virtual_network_peering.peerings : k => {
      id                           = v.id
      name                         = v.name
      remote_virtual_network_id    = v.remote_virtual_network_id
      allow_virtual_network_access = v.allow_virtual_network_access
      allow_forwarded_traffic      = v.allow_forwarded_traffic
      allow_gateway_transit        = v.allow_gateway_transit
      use_remote_gateways          = v.use_remote_gateways
    }
  }
}

# NAT Gateways
output "nat_gateways" {
  description = "Informações dos NAT Gateways"
  value = {
    for k, v in azurerm_nat_gateway.nat_gateways : k => {
      id                      = v.id
      name                    = v.name
      resource_group_name     = v.resource_group_name
      location                = v.location
      sku_name                = v.sku_name
      idle_timeout_in_minutes = v.idle_timeout_in_minutes
      zones                   = v.zones
    }
  }
}

output "nat_gateway_public_ips" {
  description = "Public IPs dos NAT Gateways"
  value = {
    for k, v in azurerm_public_ip.nat_gateway_pips : k => {
      id         = v.id
      name       = v.name
      ip_address = v.ip_address
    }
  }
}

# Network Watcher
output "network_watcher_id" {
  description = "ID do Network Watcher"
  value       = var.create_network_watcher ? azurerm_network_watcher.main[0].id : null
}

output "network_watcher_name" {
  description = "Nome do Network Watcher"
  value       = var.create_network_watcher ? azurerm_network_watcher.main[0].name : null
}

# Flow Logs
output "flow_logs" {
  description = "Informações dos NSG Flow Logs"
  value = var.enable_flow_logs ? {
    for k, v in azurerm_network_watcher_flow_log.flow_logs : k => {
      id                        = v.id
      name                      = v.name
      network_security_group_id = v.network_security_group_id
      enabled                   = v.enabled
    }
  } : {}
}

# Bastion
output "bastion_id" {
  description = "ID do Azure Bastion Host"
  value       = var.create_bastion ? azurerm_bastion_host.main[0].id : null
}

output "bastion_name" {
  description = "Nome do Azure Bastion Host"
  value       = var.create_bastion ? azurerm_bastion_host.main[0].name : null
}

output "bastion_dns_name" {
  description = "DNS name do Azure Bastion Host"
  value       = var.create_bastion ? azurerm_bastion_host.main[0].dns_name : null
}

output "bastion_public_ip" {
  description = "Public IP do Azure Bastion"
  value       = var.create_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

# VPN Gateway
output "vpn_gateway_id" {
  description = "ID do VPN Gateway"
  value       = var.create_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
}

output "vpn_gateway_name" {
  description = "Nome do VPN Gateway"
  value       = var.create_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].name : null
}

output "vpn_gateway_public_ips" {
  description = "Public IPs do VPN Gateway"
  value = var.create_vpn_gateway ? [
    for pip in azurerm_public_ip.vpn_gateway : pip.ip_address
  ] : []
}

# Summary outputs
output "vnet_summary" {
  description = "Resumo das informações da VNet"
  value = {
    id            = azurerm_virtual_network.main.id
    name          = azurerm_virtual_network.main.name
    location      = azurerm_virtual_network.main.location
    address_space = azurerm_virtual_network.main.address_space
    guid          = azurerm_virtual_network.main.guid
    subnets_count = length(azurerm_subnet.subnets)
    nsgs_count    = length(azurerm_network_security_group.nsgs)
    route_tables_count = length(azurerm_route_table.route_tables)
    peerings_count = length(azurerm_virtual_network_peering.peerings)
    nat_gateways_count = length(azurerm_nat_gateway.nat_gateways)
    has_bastion   = var.create_bastion
    has_vpn_gateway = var.create_vpn_gateway
  }
}

output "subnet_list" {
  description = "Lista simples de nomes das subnets"
  value       = [for s in azurerm_subnet.subnets : s.name]
}

output "nsg_list" {
  description = "Lista simples de nomes dos NSGs"
  value       = [for nsg in azurerm_network_security_group.nsgs : nsg.name]
}

output "route_table_list" {
  description = "Lista simples de nomes das Route Tables"
  value       = [for rt in azurerm_route_table.route_tables : rt.name]
}

# Outputs úteis para outros módulos
output "vnet_id" {
  description = "ID da VNet (útil para referência em outros módulos)"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nome da VNet (útil para referência em outros módulos)"
  value       = azurerm_virtual_network.main.name
}

output "vnet_location" {
  description = "Localização da VNet (útil para referência em outros módulos)"
  value       = azurerm_virtual_network.main.location
}

output "vnet_resource_group_name" {
  description = "Resource Group da VNet (útil para referência em outros módulos)"
  value       = azurerm_virtual_network.main.resource_group_name
}

# Outputs por tipo de subnet
output "gateway_subnet_id" {
  description = "ID da GatewaySubnet (se criada)"
  value       = var.create_vpn_gateway ? azurerm_subnet.gateway[0].id : null
}

output "bastion_subnet_id" {
  description = "ID da AzureBastionSubnet (se criada)"
  value       = var.create_bastion ? azurerm_subnet.bastion[0].id : null
}