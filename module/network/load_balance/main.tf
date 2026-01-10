terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  sku_tier            = var.sku_tier
  edge_zone           = var.edge_zone

  # Frontend IP Configurations
  dynamic "frontend_ip_configuration" {
    for_each = { for config in var.frontend_ip_configurations : config.name => config }
    content {
      name                                               = frontend_ip_configuration.value.name
      zones                                              = frontend_ip_configuration.value.zones
      subnet_id                                          = frontend_ip_configuration.value.subnet_id
      private_ip_address                                 = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation                      = frontend_ip_configuration.value.private_ip_address_allocation
      private_ip_address_version                         = frontend_ip_configuration.value.private_ip_address_version
      public_ip_address_id                               = frontend_ip_configuration.value.public_ip_address_id
      public_ip_prefix_id                                = frontend_ip_configuration.value.public_ip_prefix_id
      gateway_load_balancer_frontend_ip_configuration_id = frontend_ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_id
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : []
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Backend Address Pools
resource "azurerm_lb_backend_address_pool" "pools" {
  for_each = { for pool in var.backend_address_pools : pool.name => pool }

  name            = each.value.name
  loadbalancer_id = azurerm_lb.main.id

  dynamic "tunnel_interface" {
    for_each = each.value.tunnel_interface
    content {
      identifier = tunnel_interface.value.identifier
      type       = tunnel_interface.value.type
      protocol   = tunnel_interface.value.protocol
      port       = tunnel_interface.value.port
    }
  }
}

# Backend Addresses
resource "azurerm_lb_backend_address_pool_address" "addresses" {
  for_each = { for addr in var.backend_addresses : addr.name => addr }

  name                                = each.value.name
  backend_address_pool_id             = azurerm_lb_backend_address_pool.pools[each.value.backend_address_pool_name].id
  virtual_network_id                  = each.value.virtual_network_id
  ip_address                          = each.value.ip_address
  backend_address_ip_configuration_id = each.value.backend_address_ip_configuration_id
}

# Health Probes
resource "azurerm_lb_probe" "probes" {
  for_each = { for probe in var.probes : probe.name => probe }

  name                = each.value.name
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = each.value.protocol
  port                = each.value.port
  request_path        = each.value.protocol != "Tcp" ? each.value.request_path : null
  interval_in_seconds = each.value.interval_in_seconds
  number_of_probes    = each.value.number_of_probes
  probe_threshold     = var.sku == "Standard" ? each.value.probe_threshold : null
}

# Load Balancing Rules
resource "azurerm_lb_rule" "rules" {
  for_each = { for rule in var.lb_rules : rule.name => rule }

  name                           = each.value.name
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids = length(each.value.backend_address_pool_names) > 0 ? [
    for pool_name in each.value.backend_address_pool_names :
    azurerm_lb_backend_address_pool.pools[pool_name].id
  ] : null
  probe_id                = each.value.probe_name != null ? azurerm_lb_probe.probes[each.value.probe_name].id : null
  floating_ip_enabled      = each.value.enable_floating_ip
  tcp_reset_enabled        = var.sku == "Standard" ? each.value.enable_tcp_reset : null
  disable_outbound_snat   = var.sku == "Standard" ? each.value.disable_outbound_snat : null
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  load_distribution       = each.value.load_distribution
}

# NAT Rules (Inbound)
resource "azurerm_lb_nat_rule" "nat_rules" {
  for_each = {
    for rule in var.nat_rules :
    rule.name => rule
    if rule.backend_address_pool_name == null
  }

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  floating_ip_enabled             = each.value.enable_floating_ip
  tcp_reset_enabled               = var.sku == "Standard" ? each.value.enable_tcp_reset : null
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
}

# NAT Pool (for VMSS)
resource "azurerm_lb_nat_pool" "nat_pools" {
  for_each = {
    for rule in var.nat_rules :
    rule.name => rule
    if rule.backend_address_pool_name != null
  }

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = each.value.protocol
  frontend_port_start            = each.value.frontend_port_start
  frontend_port_end              = each.value.frontend_port_end
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  floating_ip_enabled            = each.value.enable_floating_ip
  tcp_reset_enabled              = var.sku == "Standard" ? each.value.enable_tcp_reset : null
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
}

# Outbound Rules (Standard SKU only)
resource "azurerm_lb_outbound_rule" "outbound_rules" {
  for_each = var.sku == "Standard" ? { for rule in var.outbound_rules : rule.name => rule } : {}

  name                    = each.value.name
  loadbalancer_id         = azurerm_lb.main.id
  protocol                = each.value.protocol
  backend_address_pool_id = azurerm_lb_backend_address_pool.pools[each.value.backend_address_pool_name].id
  allocated_outbound_ports = each.value.allocated_outbound_ports
  tcp_reset_enabled         = each.value.enable_tcp_reset
  idle_timeout_in_minutes  = each.value.idle_timeout_in_minutes

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configuration_names
    content {
      name = frontend_ip_configuration.value
    }
  }
}

# HA Ports Rules (Standard SKU Internal LB only)
resource "azurerm_lb_rule" "ha_ports_rules" {
  for_each = var.sku == "Standard" ? { for rule in var.ha_ports_rules : rule.name => rule } : {}

  name                           = each.value.name
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = each.value.protocol
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids = [
    for pool_name in each.value.backend_address_pool_names :
    azurerm_lb_backend_address_pool.pools[pool_name].id
  ]
  probe_id                = each.value.probe_name != null ? azurerm_lb_probe.probes[each.value.probe_name].id : null
  floating_ip_enabled      = each.value.enable_floating_ip
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_lb.main.id
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
  frontend_ip_configuration_ids = {
    for config in var.frontend_ip_configurations :
    config.name => "${azurerm_lb.main.id}/frontendIPConfigurations/${config.name}"
  }
  
  backend_address_pool_ids = {
    for pool in var.backend_address_pools :
    pool.name => azurerm_lb_backend_address_pool.pools[pool.name].id
  }
  
  probe_ids = {
    for probe in var.probes :
    probe.name => azurerm_lb_probe.probes[probe.name].id
  }
  
  is_public = anytrue([
    for config in var.frontend_ip_configurations :
    config.public_ip_address_id != null || config.public_ip_prefix_id != null
  ])
  
  is_internal = anytrue([
    for config in var.frontend_ip_configurations :
    config.subnet_id != null
  ])
}
