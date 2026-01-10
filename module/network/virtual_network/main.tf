terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  bgp_community           = var.bgp_community
  edge_zone               = var.edge_zone
  flow_timeout_in_minutes = var.flow_timeout_in_minutes

  # DDoS Protection Plan
  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan.enable ? [1] : []
    content {
      id     = var.ddos_protection_plan.id
      enable = var.ddos_protection_plan.enable
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  private_endpoint_network_policies             = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  service_endpoints           = length(each.value.service_endpoints) > 0 ? each.value.service_endpoints : var.service_endpoints
  service_endpoint_policy_ids = each.value.service_endpoint_policy_ids

  # Delegations
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "nsgs" {
  for_each = { for nsg in var.network_security_groups : nsg.name => nsg }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# NSG Security Rules
resource "azurerm_network_security_rule" "rules" {
  for_each = merge([
    for nsg in var.network_security_groups : {
      for rule in nsg.security_rules :
      "${nsg.name}-${rule.name}" => {
        nsg_name                     = nsg.name
        name                         = rule.name
        priority                     = rule.priority
        direction                    = rule.direction
        access                       = rule.access
        protocol                     = rule.protocol
        source_port_range            = rule.source_port_range
        source_port_ranges           = rule.source_port_ranges
        destination_port_range       = rule.destination_port_range
        destination_port_ranges      = rule.destination_port_ranges
        source_address_prefix        = rule.source_address_prefix
        source_address_prefixes      = rule.source_address_prefixes
        destination_address_prefix   = rule.destination_address_prefix
        destination_address_prefixes = rule.destination_address_prefixes
        description                  = rule.description
      }
    }
  ]...)

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  source_port_ranges          = each.value.source_port_ranges
  destination_port_range      = each.value.destination_port_range
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefix       = each.value.source_address_prefix
  source_address_prefixes     = each.value.source_address_prefixes
  destination_address_prefix  = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
  description                 = each.value.description
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsgs[each.value.nsg_name].name
}

# NSG to Subnet Associations
resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = var.nsg_subnet_associations

  subnet_id                 = azurerm_subnet.subnets[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg_name].id
}

# Route Tables
resource "azurerm_route_table" "route_tables" {
  for_each = { for rt in var.route_tables : rt.name => rt }

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled

  tags = var.tags
}

# Routes
resource "azurerm_route" "routes" {
  for_each = merge([
    for rt in var.route_tables : {
      for route in rt.routes :
      "${rt.name}-${route.name}" => {
        route_table_name       = rt.name
        name                   = route.name
        address_prefix         = route.address_prefix
        next_hop_type          = route.next_hop_type
        next_hop_in_ip_address = route.next_hop_in_ip_address
      }
    }
  ]...)

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.route_tables[each.value.route_table_name].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

# Route Table to Subnet Associations
resource "azurerm_subnet_route_table_association" "rt_associations" {
  for_each = var.route_table_subnet_associations

  subnet_id      = azurerm_subnet.subnets[each.value.subnet_name].id
  route_table_id = azurerm_route_table.route_tables[each.value.route_table_name].id
}

# VNet Peering
resource "azurerm_virtual_network_peering" "peerings" {
  for_each = { for peering in var.vnet_peerings : peering.name => peering }

  name                         = each.value.name
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.main.name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}

# Public IPs para NAT Gateway
resource "azurerm_public_ip" "nat_gateway_pips" {
  for_each = merge([
    for nat_gw_name, count in var.nat_gateway_public_ips : {
      for i in range(count) :
      "${nat_gw_name}-pip-${i + 1}" => {
        nat_gateway_name = nat_gw_name
        index            = i + 1
      }
    }
  ]...)

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = try([for nat in var.nat_gateways : nat.zones if nat.name == each.value.nat_gateway_name][0], [])

  tags = var.tags
}

# NAT Gateways
resource "azurerm_nat_gateway" "nat_gateways" {
  for_each = { for nat in var.nat_gateways : nat.name => nat }

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = each.value.sku_name
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones

  tags = var.tags
}

# NAT Gateway Public IP Associations
resource "azurerm_nat_gateway_public_ip_association" "nat_pip_associations" {
  for_each = {
    for pip_key, pip in azurerm_public_ip.nat_gateway_pips :
    pip_key => pip
  }

  nat_gateway_id       = azurerm_nat_gateway.nat_gateways[each.value.tags_all["nat_gateway_name"] != null ? each.value.tags_all["nat_gateway_name"] : split("-pip-", each.key)[0]].id
  public_ip_address_id = each.value.id
}

# NAT Gateway to Subnet Associations
resource "azurerm_subnet_nat_gateway_association" "nat_associations" {
  for_each = merge([
    for nat in var.nat_gateways : {
      for subnet_name in nat.subnet_associations :
      "${nat.name}-${subnet_name}" => {
        nat_gateway_name = nat.name
        subnet_name      = subnet_name
      }
    }
  ]...)

  subnet_id      = azurerm_subnet.subnets[each.value.subnet_name].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateways[each.value.nat_gateway_name].id
}

# Network Watcher
resource "azurerm_network_watcher" "main" {
  count = var.create_network_watcher ? 1 : 0

  name                = var.network_watcher_name != null ? var.network_watcher_name : "nw-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# NSG Flow Logs
resource "azurerm_network_watcher_flow_log" "flow_logs" {
  for_each = var.enable_flow_logs ? { for nsg in var.network_security_groups : nsg.name => nsg } : {}

  name                      = "fl-${each.value.name}"
  network_watcher_name      = var.create_network_watcher ? azurerm_network_watcher.main[0].name : "NetworkWatcher_${var.location}"
  resource_group_name       = var.create_network_watcher ? var.resource_group_name : "NetworkWatcherRG"
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
  storage_account_id        = var.flow_logs_storage_account_id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.flow_logs_traffic_analytics.enabled ? [1] : []
    content {
      enabled               = var.flow_logs_traffic_analytics.enabled
      workspace_id          = var.flow_logs_traffic_analytics.workspace_id
      workspace_region      = var.flow_logs_traffic_analytics.workspace_region
      workspace_resource_id = var.flow_logs_traffic_analytics.workspace_resource_id
      interval_in_minutes   = var.flow_logs_traffic_analytics.interval_in_minutes
    }
  }

  tags = var.tags
}

# Bastion Subnet
resource "azurerm_subnet" "bastion" {
  count = var.create_bastion ? 1 : 0

  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 250)]
}

# Bastion Public IP
resource "azurerm_public_ip" "bastion" {
  count = var.create_bastion ? 1 : 0

  name                = "${var.bastion_config.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Bastion Host
resource "azurerm_bastion_host" "main" {
  count = var.create_bastion ? 1 : 0

  name                   = var.bastion_config.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  sku                    = var.bastion_config.sku
  copy_paste_enabled     = var.bastion_config.copy_paste_enabled
  file_copy_enabled      = var.bastion_config.sku == "Standard" ? var.bastion_config.file_copy_enabled : null
  ip_connect_enabled     = var.bastion_config.sku == "Standard" ? var.bastion_config.ip_connect_enabled : null
  scale_units            = var.bastion_config.sku == "Standard" ? var.bastion_config.scale_units : null
  shareable_link_enabled = var.bastion_config.sku == "Standard" ? var.bastion_config.shareable_link_enabled : null
  tunneling_enabled      = var.bastion_config.sku == "Standard" ? var.bastion_config.tunneling_enabled : null

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.tags
}

# VPN Gateway Subnet
resource "azurerm_subnet" "gateway" {
  count = var.create_vpn_gateway ? 1 : 0

  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 8, 251)]
}

# VPN Gateway Public IP
resource "azurerm_public_ip" "vpn_gateway" {
  count = var.create_vpn_gateway ? (var.vpn_gateway_config.active_active ? 2 : 1) : 0

  name                = "${var.vpn_gateway_config.name}-pip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.create_vpn_gateway ? 1 : 0

  name                = var.vpn_gateway_config.name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.vpn_gateway_config.type
  vpn_type            = var.vpn_gateway_config.vpn_type
  sku                 = var.vpn_gateway_config.sku
  generation          = var.vpn_gateway_config.generation
  enable_bgp          = var.vpn_gateway_config.enable_bgp
  active_active       = var.vpn_gateway_config.active_active

  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = var.vpn_gateway_config.private_ip_address_allocation
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  dynamic "ip_configuration" {
    for_each = var.vpn_gateway_config.active_active ? [1] : []
    content {
      name                          = "vnetGatewayConfig2"
      public_ip_address_id          = azurerm_public_ip.vpn_gateway[1].id
      private_ip_address_allocation = var.vpn_gateway_config.private_ip_address_allocation
      subnet_id                     = azurerm_subnet.gateway[0].id
    }
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  count = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_virtual_network.main.id
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
  subnet_ids = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
  
  nsg_ids = {
    for k, v in azurerm_network_security_group.nsgs : k => v.id
  }
  
  route_table_ids = {
    for k, v in azurerm_route_table.route_tables : k => v.id
  }
}
