output "id" {
  description = "ID do Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "name" {
  description = "Nome do Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_application_gateway.main.resource_group_name
}

output "location" {
  description = "Localização do Application Gateway"
  value       = azurerm_application_gateway.main.location
}

# Frontend Configuration
output "frontend_ip_configuration" {
  description = "Configuração de IP frontend"
  value = {
    id                   = local.frontend_ip_configuration_id
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_address_id
    private_ip_address   = var.private_ip_address
  }
}

output "frontend_ports" {
  description = "Portas frontend configuradas"
  value = {
    for port in var.frontend_ports :
    port.name => {
      name = port.name
      port = port.port
    }
  }
}

# Backend Configuration
output "backend_address_pool_ids" {
  description = "Map de IDs dos backend address pools"
  value       = local.backend_address_pool_ids
}

output "backend_address_pools" {
  description = "Informações dos backend address pools"
  value = {
    for pool in var.backend_address_pools :
    pool.name => {
      id           = local.backend_address_pool_ids[pool.name]
      name         = pool.name
      fqdns        = pool.fqdns
      ip_addresses = pool.ip_addresses
    }
  }
}

output "backend_http_settings_ids" {
  description = "Map de IDs das configurações HTTP backend"
  value       = local.backend_http_settings_ids
}

output "backend_http_settings" {
  description = "Informações das configurações HTTP backend"
  value = {
    for setting in var.backend_http_settings :
    setting.name => {
      id                    = local.backend_http_settings_ids[setting.name]
      name                  = setting.name
      port                  = setting.port
      protocol              = setting.protocol
      cookie_based_affinity = setting.cookie_based_affinity
      request_timeout       = setting.request_timeout
    }
  }
}

# Listeners
output "http_listener_ids" {
  description = "Map de IDs dos HTTP listeners"
  value       = local.http_listener_ids
}

output "http_listeners" {
  description = "Informações dos HTTP listeners"
  value = {
    for listener in var.http_listeners :
    listener.name => {
      id                   = local.http_listener_ids[listener.name]
      name                 = listener.name
      protocol             = listener.protocol
      frontend_port_name   = listener.frontend_port_name
      host_name            = listener.host_name
      ssl_certificate_name = listener.ssl_certificate_name
    }
  }
}

# Routing Rules
output "request_routing_rules" {
  description = "Informações das regras de roteamento"
  value = {
    for rule in var.request_routing_rules :
    rule.name => {
      name                       = rule.name
      rule_type                  = rule.rule_type
      http_listener_name         = rule.http_listener_name
      backend_address_pool_name  = rule.backend_address_pool_name
      backend_http_settings_name = rule.backend_http_settings_name
      url_path_map_name          = rule.url_path_map_name
      priority                   = rule.priority
    }
  }
}

# Probes
output "probes" {
  description = "Informações dos health probes"
  value = {
    for probe in var.probes :
    probe.name => {
      name                = probe.name
      protocol            = probe.protocol
      path                = probe.path
      interval            = probe.interval
      timeout             = probe.timeout
      unhealthy_threshold = probe.unhealthy_threshold
    }
  }
}

# Identity
output "identity" {
  description = "Identidade gerenciada do Application Gateway"
  value = var.identity_type != null ? {
    type         = azurerm_application_gateway.main.identity[0].type
    principal_id = azurerm_application_gateway.main.identity[0].principal_id
    tenant_id    = azurerm_application_gateway.main.identity[0].tenant_id
  } : null
}

# SKU Information
output "sku" {
  description = "Informações do SKU"
  value = {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.sku.capacity
  }
}

output "autoscale_configuration" {
  description = "Configuração de autoscaling"
  value       = var.autoscale_configuration
}

output "zones" {
  description = "Zonas de disponibilidade"
  value       = var.zones
}

# WAF
output "waf_enabled" {
  description = "Indica se o WAF está habilitado"
  value       = var.waf_configuration != null ? var.waf_configuration.enabled : false
}

output "waf_mode" {
  description = "Modo do WAF (Detection ou Prevention)"
  value       = var.waf_configuration != null ? var.waf_configuration.firewall_mode : null
}

output "firewall_policy_id" {
  description = "ID da Firewall Policy (v2)"
  value       = var.firewall_policy_id
}

# SSL
output "ssl_certificates" {
  description = "Lista de nomes dos certificados SSL configurados"
  value       = [for cert in var.ssl_certificates : cert.name]
}

output "ssl_policy" {
  description = "Política SSL configurada"
  value       = var.ssl_policy
}

# URL Path Maps
output "url_path_maps" {
  description = "Informações dos URL path maps"
  value = {
    for map in var.url_path_maps :
    map.name => {
      name                               = map.name
      default_backend_address_pool_name  = map.default_backend_address_pool_name
      default_backend_http_settings_name = map.default_backend_http_settings_name
      path_rules_count                   = length(map.path_rule)
    }
  }
}

# Redirect Configurations
output "redirect_configurations" {
  description = "Configurações de redirecionamento"
  value = {
    for config in var.redirect_configurations :
    config.name => {
      name                 = config.name
      redirect_type        = config.redirect_type
      target_listener_name = config.target_listener_name
      target_url           = config.target_url
    }
  }
}

# Rewrite Rule Sets
output "rewrite_rule_sets" {
  description = "Rewrite rule sets configurados"
  value = {
    for set in var.rewrite_rule_sets :
    set.name => {
      name        = set.name
      rules_count = length(set.rewrite_rule)
    }
  }
}

# Private Link
output "private_link_configurations" {
  description = "Configurações de Private Link"
  value = {
    for config in var.private_link_configuration :
    config.name => {
      name             = config.name
      ip_configs_count = length(config.ip_configuration)
    }
  }
}

# Summary
output "gateway_summary" {
  description = "Resumo das informações do Application Gateway"
  value = {
    id                         = azurerm_application_gateway.main.id
    name                       = azurerm_application_gateway.main.name
    location                   = azurerm_application_gateway.main.location
    sku_name                   = var.sku.name
    sku_tier                   = var.sku.tier
    zones                      = var.zones
    enable_http2               = var.enable_http2
    backend_pools_count        = length(var.backend_address_pools)
    http_listeners_count       = length(var.http_listeners)
    routing_rules_count        = length(var.request_routing_rules)
    probes_count               = length(var.probes)
    ssl_certificates_count     = length(var.ssl_certificates)
    waf_enabled                = var.waf_configuration != null ? var.waf_configuration.enabled : false
    autoscaling_enabled        = var.autoscale_configuration != null
  }
}

# Capacity Information
output "capacity_info" {
  description = "Informações de capacidade"
  value = var.autoscale_configuration != null ? {
    mode         = "autoscale"
    min_capacity = var.autoscale_configuration.min_capacity
    max_capacity = var.autoscale_configuration.max_capacity
  } : {
    mode     = "manual"
    capacity = var.sku.capacity
  }
}

# HTTP/2 Status
output "http2_enabled" {
  description = "Status do HTTP/2"
  value       = var.enable_http2
}

# Lists for easy reference
output "backend_pool_names" {
  description = "Lista de nomes dos backend pools"
  value       = [for pool in var.backend_address_pools : pool.name]
}

output "listener_names" {
  description = "Lista de nomes dos listeners"
  value       = [for listener in var.http_listeners : listener.name]
}

output "probe_names" {
  description = "Lista de nomes dos probes"
  value       = [for probe in var.probes : probe.name]
}

# Public IP (if used)
output "public_ip_address_id" {
  description = "ID do Public IP Address (se usado)"
  value       = var.public_ip_address_id
}

# Private IP (if used)
output "private_ip_address" {
  description = "Endereço IP privado (se usado)"
  value       = var.private_ip_address
}

# Subnet
output "subnet_id" {
  description = "ID da subnet onde o Application Gateway está implantado"
  value       = var.subnet_id
}