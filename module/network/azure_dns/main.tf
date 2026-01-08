terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Public DNS Zone
resource "azurerm_dns_zone" "public" {
  count = var.create_public_zone ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name

  # SOA Record
  dynamic "soa_record" {
    for_each = var.soa_record != null ? [var.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      serial_number = soa_record.value.serial_number
      ttl          = soa_record.value.ttl
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "private" {
  count = var.create_private_zone ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name

  # SOA Record
  dynamic "soa_record" {
    for_each = var.soa_record != null ? [var.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Virtual Network Links (Private DNS only)
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = var.create_private_zone ? { for link in var.vnet_links : link.name => link } : {}

  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private[0].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled

  tags = var.tags
}

# Locals para determinar qual zona usar
locals {
  zone_name = var.create_public_zone ? azurerm_dns_zone.public[0].name : azurerm_private_dns_zone.private[0].name
  zone_id   = var.create_public_zone ? azurerm_dns_zone.public[0].id : azurerm_private_dns_zone.private[0].id
}

# A Records - Public
resource "azurerm_dns_a_record" "public_a" {
  for_each = var.create_public_zone ? { for record in var.a_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# A Records - Private
resource "azurerm_private_dns_a_record" "private_a" {
  for_each = var.create_private_zone ? { for record in var.a_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# AAAA Records - Public
resource "azurerm_dns_aaaa_record" "public_aaaa" {
  for_each = var.create_public_zone ? { for record in var.aaaa_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# AAAA Records - Private
resource "azurerm_private_dns_aaaa_record" "private_aaaa" {
  for_each = var.create_private_zone ? { for record in var.aaaa_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# CNAME Records - Public
resource "azurerm_dns_cname_record" "public_cname" {
  for_each = var.create_public_zone ? { for record in var.cname_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record

  tags = var.tags
}

# CNAME Records - Private
resource "azurerm_private_dns_cname_record" "private_cname" {
  for_each = var.create_private_zone ? { for record in var.cname_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record

  tags = var.tags
}

# MX Records - Public
resource "azurerm_dns_mx_record" "public_mx" {
  for_each = var.create_public_zone ? { for record in var.mx_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }

  tags = var.tags
}

# MX Records - Private
resource "azurerm_private_dns_mx_record" "private_mx" {
  for_each = var.create_private_zone ? { for record in var.mx_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }

  tags = var.tags
}

# NS Records - Public
resource "azurerm_dns_ns_record" "public_ns" {
  for_each = var.create_public_zone ? { for record in var.ns_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# PTR Records - Public
resource "azurerm_dns_ptr_record" "public_ptr" {
  for_each = var.create_public_zone ? { for record in var.ptr_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# PTR Records - Private
resource "azurerm_private_dns_ptr_record" "private_ptr" {
  for_each = var.create_private_zone ? { for record in var.ptr_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records

  tags = var.tags
}

# SRV Records - Public
resource "azurerm_dns_srv_record" "public_srv" {
  for_each = var.create_public_zone ? { for record in var.srv_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      priority = record.value.priority
      weight   = record.value.weight
      port     = record.value.port
      target   = record.value.target
    }
  }

  tags = var.tags
}

# SRV Records - Private
resource "azurerm_private_dns_srv_record" "private_srv" {
  for_each = var.create_private_zone ? { for record in var.srv_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      priority = record.value.priority
      weight   = record.value.weight
      port     = record.value.port
      target   = record.value.target
    }
  }

  tags = var.tags
}

# TXT Records - Public
resource "azurerm_dns_txt_record" "public_txt" {
  for_each = var.create_public_zone ? { for record in var.txt_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  tags = var.tags
}

# TXT Records - Private
resource "azurerm_private_dns_txt_record" "private_txt" {
  for_each = var.create_private_zone ? { for record in var.txt_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  tags = var.tags
}

# CAA Records - Public only
resource "azurerm_dns_caa_record" "public_caa" {
  for_each = var.create_public_zone ? { for record in var.caa_records : record.name => record } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.records
    content {
      flags = record.value.flags
      tag   = record.value.tag
      value = record.value.value
    }
  }

  tags = var.tags
}

# Traffic Manager CNAME Records
resource "azurerm_dns_cname_record" "traffic_manager" {
  for_each = var.create_public_zone && var.create_traffic_manager_records ? {
    for record in var.traffic_manager_records : record.name => record
  } : {}

  name                = each.value.name
  zone_name           = azurerm_dns_zone.public[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.traffic_manager_fqdn

  tags = var.tags
}

# Azure Service Records (Private Link endpoints)
resource "azurerm_private_dns_a_record" "azure_services" {
  for_each = var.create_private_zone && var.create_azure_service_records ? {
    for record in var.azure_service_records : record.name => record
  } : {}

  name                = each.value.name
  zone_name           = azurerm_private_dns_zone.private[0].name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = [each.value.ip_address]

  tags = var.tags
}

# Diagnostic Settings - Public DNS
resource "azurerm_monitor_diagnostic_setting" "public_dns" {
  count = var.create_public_zone && var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_dns_zone.public[0].id
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

# Diagnostic Settings - Private DNS
resource "azurerm_monitor_diagnostic_setting" "private_dns" {
  count = var.create_private_zone && var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_private_dns_zone.private[0].id
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
