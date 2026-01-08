variable "name" {
  description = "Nome do Application Gateway"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,78}[a-zA-Z0-9]$", var.name))
    error_message = "O nome deve começar e terminar com letra ou número, pode conter letras, números, hífens e underscores, e ter entre 2 e 80 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde o Application Gateway será criado"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde o Application Gateway será criado"
  type        = string
}

variable "sku" {
  description = "Configuração do SKU do Application Gateway"
  type = object({
    name     = string
    tier     = string
    capacity = optional(number)
  })
  
  validation {
    condition = contains(
      ["Standard_Small", "Standard_Medium", "Standard_Large", "Standard_v2", "WAF_Medium", "WAF_Large", "WAF_v2"],
      var.sku.name
    )
    error_message = "O SKU name deve ser um dos valores válidos."
  }
  
  validation {
    condition = contains(
      ["Standard", "Standard_v2", "WAF", "WAF_v2"],
      var.sku.tier
    )
    error_message = "O SKU tier deve ser Standard, Standard_v2, WAF ou WAF_v2."
  }
}

variable "zones" {
  description = "Lista de zonas de disponibilidade (apenas para v2 SKUs)"
  type        = list(string)
  default     = null
  
  validation {
    condition     = var.zones == null || alltrue([for z in var.zones : contains(["1", "2", "3"], z)])
    error_message = "As zonas devem ser '1', '2' ou '3'."
  }
}

# Autoscaling (v2 only)
variable "autoscale_configuration" {
  description = "Configuração de autoscaling (apenas v2 SKUs)"
  type = object({
    min_capacity = number
    max_capacity = optional(number)
  })
  default = null
  
  validation {
    condition = var.autoscale_configuration == null || (
      var.autoscale_configuration.min_capacity >= 0 &&
      var.autoscale_configuration.min_capacity <= 125 &&
      (var.autoscale_configuration.max_capacity == null ||
        var.autoscale_configuration.max_capacity <= 125)
    )
    error_message = "Capacidade deve estar entre 0 e 125."
  }
}

# Network
variable "subnet_id" {
  description = "ID da subnet onde o Application Gateway será implantado"
  type        = string
}

variable "enable_http2" {
  description = "Habilitar HTTP/2"
  type        = bool
  default     = false
}

variable "force_firewall_policy_association" {
  description = "Forçar associação de Firewall Policy"
  type        = bool
  default     = false
}

# Frontend Configuration
variable "frontend_ip_configuration_name" {
  description = "Nome da configuração de IP frontend"
  type        = string
  default     = "frontend-ip-config"
}

variable "public_ip_address_id" {
  description = "ID do Public IP Address (para frontend público)"
  type        = string
  default     = null
}

variable "private_ip_address" {
  description = "IP privado para frontend (se não usar public IP)"
  type        = string
  default     = null
}

variable "private_ip_address_allocation" {
  description = "Método de alocação do IP privado (Static ou Dynamic)"
  type        = string
  default     = "Dynamic"
  
  validation {
    condition     = contains(["Static", "Dynamic"], var.private_ip_address_allocation)
    error_message = "A alocação deve ser Static ou Dynamic."
  }
}

# Frontend Ports
variable "frontend_ports" {
  description = "Lista de portas frontend"
  type = list(object({
    name = string
    port = number
  }))
  default = [
    {
      name = "http"
      port = 80
    },
    {
      name = "https"
      port = 443
    }
  ]
}

# Backend Address Pools
variable "backend_address_pools" {
  description = "Lista de backend address pools"
  type = list(object({
    name         = string
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
}

# Backend HTTP Settings
variable "backend_http_settings" {
  description = "Lista de configurações HTTP backend"
  type = list(object({
    name                                = string
    cookie_based_affinity               = string
    affinity_cookie_name                = optional(string)
    path                                = optional(string, "/")
    port                                = number
    protocol                            = string
    request_timeout                     = optional(number, 30)
    probe_name                          = optional(string)
    pick_host_name_from_backend_address = optional(bool, false)
    host_name                           = optional(string)
    trusted_root_certificate_names      = optional(list(string), [])
    connection_draining = optional(object({
      enabled           = bool
      drain_timeout_sec = number
    }))
  }))
  
  validation {
    condition = alltrue([
      for setting in var.backend_http_settings :
      contains(["Enabled", "Disabled"], setting.cookie_based_affinity)
    ])
    error_message = "cookie_based_affinity deve ser 'Enabled' ou 'Disabled'."
  }
  
  validation {
    condition = alltrue([
      for setting in var.backend_http_settings :
      contains(["Http", "Https"], setting.protocol)
    ])
    error_message = "protocol deve ser 'Http' ou 'Https'."
  }
}

# HTTP Listeners
variable "http_listeners" {
  description = "Lista de HTTP listeners"
  type = list(object({
    name                           = string
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = string
    host_name                      = optional(string)
    host_names                     = optional(list(string))
    require_sni                    = optional(bool, false)
    ssl_certificate_name           = optional(string)
    firewall_policy_id             = optional(string)
    ssl_profile_name               = optional(string)
    custom_error_configuration = optional(list(object({
      status_code           = string
      custom_error_page_url = string
    })), [])
  }))
  
  validation {
    condition = alltrue([
      for listener in var.http_listeners :
      contains(["Http", "Https"], listener.protocol)
    ])
    error_message = "protocol deve ser 'Http' ou 'Https'."
  }
}

# Request Routing Rules
variable "request_routing_rules" {
  description = "Lista de regras de roteamento"
  type = list(object({
    name                        = string
    rule_type                   = string
    http_listener_name          = string
    backend_address_pool_name   = optional(string)
    backend_http_settings_name  = optional(string)
    redirect_configuration_name = optional(string)
    rewrite_rule_set_name       = optional(string)
    url_path_map_name           = optional(string)
    priority                    = optional(number)
  }))
  
  validation {
    condition = alltrue([
      for rule in var.request_routing_rules :
      contains(["Basic", "PathBasedRouting"], rule.rule_type)
    ])
    error_message = "rule_type deve ser 'Basic' ou 'PathBasedRouting'."
  }
}

# Health Probes
variable "probes" {
  description = "Lista de health probes"
  type = list(object({
    name                                      = string
    protocol                                  = string
    path                                      = string
    interval                                  = optional(number, 30)
    timeout                                   = optional(number, 30)
    unhealthy_threshold                       = optional(number, 3)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    host                                      = optional(string)
    port                                      = optional(number)
    minimum_servers                           = optional(number, 0)
    match = optional(object({
      body        = optional(string)
      status_code = list(string)
    }))
  }))
  default = []
  
  validation {
    condition = alltrue([
      for probe in var.probes :
      contains(["Http", "Https"], probe.protocol)
    ])
    error_message = "protocol deve ser 'Http' ou 'Https'."
  }
}

# SSL Certificates
variable "ssl_certificates" {
  description = "Lista de certificados SSL"
  type = list(object({
    name                = string
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default   = []
  sensitive = true
}

# Trusted Root Certificates
variable "trusted_root_certificates" {
  description = "Lista de certificados raiz confiáveis"
  type = list(object({
    name                = string
    data                = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default   = []
  sensitive = true
}

# SSL Policy
variable "ssl_policy" {
  description = "Política SSL"
  type = object({
    disabled_protocols   = optional(list(string), [])
    policy_type          = optional(string, "Predefined")
    policy_name          = optional(string, "AppGwSslPolicy20170401S")
    cipher_suites        = optional(list(string), [])
    min_protocol_version = optional(string)
  })
  default = null
}

# WAF Configuration
variable "waf_configuration" {
  description = "Configuração do Web Application Firewall"
  type = object({
    enabled                  = bool
    firewall_mode            = string
    rule_set_type            = optional(string, "OWASP")
    rule_set_version         = string
    file_upload_limit_mb     = optional(number, 100)
    request_body_check       = optional(bool, true)
    max_request_body_size_kb = optional(number, 128)
    disabled_rule_group = optional(list(object({
      rule_group_name = string
      rules           = optional(list(number))
    })), [])
    exclusion = optional(list(object({
      match_variable          = string
      selector_match_operator = optional(string)
      selector                = optional(string)
    })), [])
  })
  default = null
  
  validation {
    condition = var.waf_configuration == null || contains(
      ["Detection", "Prevention"],
      var.waf_configuration.firewall_mode
    )
    error_message = "firewall_mode deve ser 'Detection' ou 'Prevention'."
  }
}

# Firewall Policy ID (v2 WAF)
variable "firewall_policy_id" {
  description = "ID da Web Application Firewall Policy (v2)"
  type        = string
  default     = null
}

# URL Path Maps
variable "url_path_maps" {
  description = "Lista de URL path maps para path-based routing"
  type = list(object({
    name                                = string
    default_backend_address_pool_name   = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_redirect_configuration_name = optional(string)
    default_rewrite_rule_set_name       = optional(string)
    path_rule = list(object({
      name                        = string
      paths                       = list(string)
      backend_address_pool_name   = optional(string)
      backend_http_settings_name  = optional(string)
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
      firewall_policy_id          = optional(string)
    }))
  }))
  default = []
}

# Redirect Configurations
variable "redirect_configurations" {
  description = "Lista de configurações de redirecionamento"
  type = list(object({
    name                 = string
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool, false)
    include_query_string = optional(bool, false)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for config in var.redirect_configurations :
      contains(["Permanent", "Found", "SeeOther", "Temporary"], config.redirect_type)
    ])
    error_message = "redirect_type deve ser Permanent, Found, SeeOther ou Temporary."
  }
}

# Rewrite Rule Sets
variable "rewrite_rule_sets" {
  description = "Lista de rewrite rule sets"
  type = list(object({
    name = string
    rewrite_rule = list(object({
      name          = string
      rule_sequence = number
      condition = optional(list(object({
        variable    = string
        pattern     = string
        ignore_case = optional(bool, false)
        negate      = optional(bool, false)
      })), [])
      request_header_configuration = optional(list(object({
        header_name  = string
        header_value = string
      })), [])
      response_header_configuration = optional(list(object({
        header_name  = string
        header_value = string
      })), [])
      url = optional(object({
        path         = optional(string)
        query_string = optional(string)
        components   = optional(string)
        reroute      = optional(bool)
      }))
    }))
  }))
  default = []
}

# Custom Error Pages
variable "custom_error_configuration" {
  description = "Configuração de páginas de erro personalizadas"
  type = list(object({
    status_code           = string
    custom_error_page_url = string
  }))
  default = []
}

# Identity
variable "identity_type" {
  description = "Tipo de identidade gerenciada (SystemAssigned, UserAssigned)"
  type        = string
  default     = null
  
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "O identity_type deve ser SystemAssigned ou UserAssigned."
  }
}

variable "identity_ids" {
  description = "Lista de IDs de identidades gerenciadas atribuídas pelo usuário"
  type        = list(string)
  default     = []
}

# Global Configuration
variable "global_configuration" {
  description = "Configuração global do Application Gateway"
  type = object({
    request_buffering_enabled  = optional(bool, true)
    response_buffering_enabled = optional(bool, true)
  })
  default = null
}

# Private Link Configuration
variable "private_link_configuration" {
  description = "Configuração de Private Link"
  type = list(object({
    name = string
    ip_configuration = list(object({
      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = string
      primary                       = bool
      private_ip_address            = optional(string)
    }))
  }))
  default = []
}

# Monitoring
variable "enable_diagnostic_settings" {
  description = "Habilitar configurações de diagnóstico"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace para diagnósticos"
  type        = string
  default     = null
}

variable "diagnostic_logs" {
  description = "Categorias de logs para habilitar"
  type        = list(string)
  default     = ["ApplicationGatewayAccessLog", "ApplicationGatewayPerformanceLog", "ApplicationGatewayFirewallLog"]
}

variable "diagnostic_metrics" {
  description = "Categorias de métricas para habilitar"
  type        = list(string)
  default     = ["AllMetrics"]
}

# Tags
variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}