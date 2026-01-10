terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

locals {
  # Combinar Public IPs existentes e novos
  all_public_ip_ids = concat(
    var.existing_public_ip_ids,
    var.create_public_ips ? [for ip in azurerm_public_ip.main : ip.id] : []
  )
}

# Public IP Prefix (se especificado)
resource "azurerm_public_ip_prefix" "main" {
  count = var.public_ip_prefix_length != null ? 1 : 0

  name                = "${var.name}-pip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = var.public_ip_prefix_length
  sku                 = "Standard"
  zones               = var.zones

  tags = var.tags
}

# Public IPs
resource "azurerm_public_ip" "main" {
  count = var.create_public_ips ? var.public_ip_count : 0

  name                = "${var.name}-pip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  zones               = var.zones

  # Usar Public IP Prefix se disponível
  public_ip_prefix_id = try(
    var.public_ip_prefix_id,
    azurerm_public_ip_prefix.main[0].id,
    null
  )

  tags = var.tags
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  name                    = var.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = var.sku_name
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  zones                   = var.zones

  tags = var.tags
}

# Associação de Public IPs ao NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  for_each = toset(local.all_public_ip_ids)

  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = each.value

  depends_on = [
    azurerm_public_ip.main
  ]
}

# Associação de Public IP Prefix ao NAT Gateway
resource "azurerm_nat_gateway_public_ip_prefix_association" "main" {
  count = var.public_ip_prefix_id != null && var.create_public_ips == false ? 1 : 0

  nat_gateway_id      = azurerm_nat_gateway.main.id
  public_ip_prefix_id = var.public_ip_prefix_id
}

# Associação de Subnets ao NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = toset(var.subnet_ids)

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count = var.diagnostic_settings.enabled ? 1 : 0

  name                           = var.diagnostic_settings.name
  target_resource_id             = azurerm_nat_gateway.main.id
  log_analytics_workspace_id     = var.diagnostic_settings.log_analytics_workspace_id
  storage_account_id             = var.diagnostic_settings.storage_account_id
  eventhub_authorization_rule_id = var.diagnostic_settings.eventhub_authorization_rule_id
  eventhub_name                  = var.diagnostic_settings.eventhub_name

  dynamic "enabled_log" {
    for_each = var.diagnostic_settings.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(var.diagnostic_settings.metric_categories)
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Alert - SNAT Port Utilization
resource "azurerm_monitor_metric_alert" "snat_ports" {
  count = var.alerts.enabled ? 1 : 0

  name                = "${var.name}-snat-ports-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_nat_gateway.main.id]
  description         = "Alert when SNAT port utilization is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/natGateways"
    metric_name      = "SNATConnectionCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.alerts.snat_port_threshold
  }

  dynamic "action" {
    for_each = var.alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Alert - Data Path Availability
resource "azurerm_monitor_metric_alert" "data_path" {
  count = var.alerts.enabled ? 1 : 0

  name                = "${var.name}-datapath-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_nat_gateway.main.id]
  description         = "Alert when data path availability is low"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/natGateways"
    metric_name      = "DatapathAvailability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.alerts.data_path_threshold
  }

  dynamic "action" {
    for_each = var.alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}
