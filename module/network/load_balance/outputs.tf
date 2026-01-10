output "id" {
  description = "ID do Load Balancer"
  value       = azurerm_lb.main.id
}

output "name" {
  description = "Nome do Load Balancer"
  value       = azurerm_lb.main.name
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_lb.main.resource_group_name
}

output "location" {
  description = "Localização do Load Balancer"
  value       = azurerm_lb.main.location
}

output "sku" {
  description = "SKU do Load Balancer"
  value       = azurerm_lb.main.sku
}

output "sku_tier" {
  description = "SKU Tier do Load Balancer"
  value       = azurerm_lb.main.sku_tier
}

# Frontend IP Configurations
output "frontend_ip_configuration_ids" {
  description = "Map de IDs das configurações de IP frontend"
  value       = local.frontend_ip_configuration_ids
}

output "frontend_ip_configurations" {
  description = "Informações das configurações de IP frontend"
  value = {
    for config in var.frontend_ip_configurations :
    config.name => {
      id                   = local.frontend_ip_configuration_ids[config.name]
      name                 = config.name
      private_ip_address   = config.private_ip_address
      public_ip_address_id = config.public_ip_address_id
      subnet_id            = config.subnet_id
      zones                = config.zones
    }
  }
}

output "private_ip_address" {
  description = "Endereço IP privado do Load Balancer (se internal)"
  value       = local.is_internal ? try(azurerm_lb.main.private_ip_address, null) : null
}

output "private_ip_addresses" {
  description = "Lista de endereços IP privados"
  value       = local.is_internal ? azurerm_lb.main.private_ip_addresses : []
}

# Backend Address Pools
output "backend_address_pool_ids" {
  description = "Map de IDs dos backend address pools"
  value       = local.backend_address_pool_ids
}

output "backend_address_pools" {
  description = "Informações dos backend address pools"
  value = {
    for pool in var.backend_address_pools :
    pool.name => {
      id   = azurerm_lb_backend_address_pool.pools[pool.name].id
      name = pool.name
    }
  }
}

output "backend_addresses" {
  description = "Informações dos endereços backend"
  value = {
    for addr in var.backend_addresses :
    addr.name => {
      id                     = azurerm_lb_backend_address_pool_address.addresses[addr.name].id
      name                   = addr.name
      backend_address_pool   = addr.backend_address_pool_name
      ip_address             = addr.ip_address
    }
  }
}

# Health Probes
output "probe_ids" {
  description = "Map de IDs dos health probes"
  value       = local.probe_ids
}

output "probes" {
  description = "Informações dos health probes"
  value = {
    for probe in var.probes :
    probe.name => {
      id                  = azurerm_lb_probe.probes[probe.name].id
      name                = probe.name
      protocol            = probe.protocol
      port                = probe.port
      request_path        = probe.request_path
      interval_in_seconds = probe.interval_in_seconds
      number_of_probes    = probe.number_of_probes
    }
  }
}

# Load Balancing Rules
output "lb_rules" {
  description = "Informações das regras de balanceamento"
  value = {
    for rule in var.lb_rules :
    rule.name => {
      id                             = azurerm_lb_rule.rules[rule.name].id
      name                           = rule.name
      protocol                       = rule.protocol
      frontend_port                  = rule.frontend_port
      backend_port                   = rule.backend_port
      frontend_ip_configuration_name = rule.frontend_ip_configuration_name
      backend_address_pool_names     = rule.backend_address_pool_names
      probe_name                     = rule.probe_name
      load_distribution              = rule.load_distribution
    }
  }
}

# NAT Rules
output "nat_rules" {
  description = "Informações das regras NAT"
  value = merge(
    {
      for rule in var.nat_rules :
      rule.name => {
        id                             = try(azurerm_lb_nat_rule.nat_rules[rule.name].id, null)
        name                           = rule.name
        protocol                       = rule.protocol
        frontend_port                  = rule.frontend_port
        backend_port                   = rule.backend_port
        frontend_ip_configuration_name = rule.frontend_ip_configuration_name
      }
      if rule.backend_address_pool_name == null
    },
    {
      for rule in var.nat_rules :
      rule.name => {
        id                             = try(azurerm_lb_nat_pool.nat_pools[rule.name].id, null)
        name                           = rule.name
        protocol                       = rule.protocol
        frontend_port_start            = rule.frontend_port_start
        frontend_port_end              = rule.frontend_port_end
        backend_port                   = rule.backend_port
        frontend_ip_configuration_name = rule.frontend_ip_configuration_name
      }
      if rule.backend_address_pool_name != null
    }
  )
}

# Outbound Rules
output "outbound_rules" {
  description = "Informações das regras outbound"
  value = {
    for rule in var.outbound_rules :
    rule.name => {
      id                              = var.sku == "Standard" ? azurerm_lb_outbound_rule.outbound_rules[rule.name].id : null
      name                            = rule.name
      protocol                        = rule.protocol
      backend_address_pool_name       = rule.backend_address_pool_name
      frontend_ip_configuration_names = rule.frontend_ip_configuration_names
      allocated_outbound_ports        = rule.allocated_outbound_ports
    }
  }
}

# HA Ports Rules
output "ha_ports_rules" {
  description = "Informações das regras HA Ports"
  value = {
    for rule in var.ha_ports_rules :
    rule.name => {
      id                             = var.sku == "Standard" ? azurerm_lb_rule.ha_ports_rules[rule.name].id : null
      name                           = rule.name
      protocol                       = rule.protocol
      frontend_ip_configuration_name = rule.frontend_ip_configuration_name
      backend_address_pool_names     = rule.backend_address_pool_names
    }
  }
}

# Identity
output "identity" {
  description = "Identidade gerenciada do Load Balancer"
  value = var.identity_type != null ? {
    type         = azurerm_lb.main.identity[0].type
    principal_id = azurerm_lb.main.identity[0].principal_id
    tenant_id    = azurerm_lb.main.identity[0].tenant_id
  } : null
}

# Load Balancer Type
output "is_public" {
  description = "Indica se o Load Balancer é público"
  value       = local.is_public
}

output "is_internal" {
  description = "Indica se o Load Balancer é interno"
  value       = local.is_internal
}

# Summary
output "lb_summary" {
  description = "Resumo das informações do Load Balancer"
  value = {
    id                        = azurerm_lb.main.id
    name                      = azurerm_lb.main.name
    location                  = azurerm_lb.main.location
    sku                       = azurerm_lb.main.sku
    sku_tier                  = azurerm_lb.main.sku_tier
    type                      = local.is_public ? "Public" : "Internal"
    frontend_configs_count    = length(var.frontend_ip_configurations)
    backend_pools_count       = length(var.backend_address_pools)
    probes_count              = length(var.probes)
    lb_rules_count            = length(var.lb_rules)
    nat_rules_count           = length(var.nat_rules)
    outbound_rules_count      = length(var.outbound_rules)
    ha_ports_rules_count      = length(var.ha_ports_rules)
  }
}

# Lists for easy reference
output "frontend_ip_configuration_names" {
  description = "Lista de nomes das configurações de IP frontend"
  value       = [for config in var.frontend_ip_configurations : config.name]
}

output "backend_address_pool_names" {
  description = "Lista de nomes dos backend address pools"
  value       = [for pool in var.backend_address_pools : pool.name]
}

output "probe_names" {
  description = "Lista de nomes dos probes"
  value       = [for probe in var.probes : probe.name]
}

output "lb_rule_names" {
  description = "Lista de nomes das regras de balanceamento"
  value       = [for rule in var.lb_rules : rule.name]
}

# Zones
output "zones" {
  description = "Zonas de disponibilidade"
  value       = var.zones
}

# Configuration Info
output "configuration_info" {
  description = "Informações de configuração úteis"
  value = {
    sku                = var.sku
    sku_tier           = var.sku_tier
    zones              = var.zones
    type               = local.is_public ? "Public" : "Internal"
    zone_redundant     = var.zones != null && length(var.zones) > 1
    standard_sku       = var.sku == "Standard"
    supports_outbound  = var.sku == "Standard"
    supports_ha_ports  = var.sku == "Standard" && local.is_internal
  }
}