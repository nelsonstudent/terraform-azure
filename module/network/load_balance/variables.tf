variable "name" {
  description = "Nome do Load Balancer"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,78}[a-zA-Z0-9]$", var.name))
    error_message = "O nome deve começar e terminar com letra ou número, pode conter letras, números, hífens e underscores, e ter entre 2 e 80 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde o Load Balancer será criado"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde o Load Balancer será criado"
  type        = string
}

variable "sku" {
  description = "SKU do Load Balancer (Basic, Standard, Gateway)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard", "Gateway"], var.sku)
    error_message = "O SKU deve ser Basic, Standard ou Gateway."
  }
}

variable "sku_tier" {
  description = "Tier do SKU (Regional, Global)"
  type        = string
  default     = "Regional"
  
  validation {
    condition     = contains(["Regional", "Global"], var.sku_tier)
    error_message = "O SKU tier deve ser Regional ou Global."
  }
}

variable "edge_zone" {
  description = "Edge Zone onde o Load Balancer será implantado"
  type        = string
  default     = null
}

# Frontend Configuration
variable "frontend_ip_configurations" {
  description = "Lista de configurações de IP frontend"
  type = list(object({
    name                          = string
    zones                         = optional(list(string), [])
    subnet_id                     = optional(string)
    private_ip_address            = optional(string)
    private_ip_address_allocation = optional(string, "Dynamic")
    private_ip_address_version    = optional(string, "IPv4")
    public_ip_address_id          = optional(string)
    public_ip_prefix_id           = optional(string)
    gateway_load_balancer_frontend_ip_configuration_id = optional(string)
  }))
  
  validation {
    condition     = length(var.frontend_ip_configurations) > 0
    error_message = "Deve haver pelo menos uma configuração de IP frontend."
  }
}

# Backend Address Pools
variable "backend_address_pools" {
  description = "Lista de backend address pools"
  type = list(object({
    name            = string
    tunnel_interface = optional(list(object({
      identifier = number
      type       = string
      protocol   = string
      port       = number
    })), [])
  }))
  
  validation {
    condition     = length(var.backend_address_pools) > 0
    error_message = "Deve haver pelo menos um backend address pool."
  }
}

# Backend Addresses (para adicionar endereços aos pools)
variable "backend_addresses" {
  description = "Lista de endereços backend para adicionar aos pools"
  type = list(object({
    name                                = string
    backend_address_pool_name           = string
    virtual_network_id                  = optional(string)
    ip_address                          = optional(string)
    backend_address_ip_configuration_id = optional(string)
  }))
  default = []
}

# Health Probes
variable "probes" {
  description = "Lista de health probes"
  type = list(object({
    name                = string
    protocol            = string
    port                = number
    request_path        = optional(string)
    interval_in_seconds = optional(number, 15)
    number_of_probes    = optional(number, 2)
    probe_threshold     = optional(number, 1)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for probe in var.probes :
      contains(["Tcp", "Http", "Https"], probe.protocol)
    ])
    error_message = "O protocolo do probe deve ser Tcp, Http ou Https."
  }
}

# Load Balancing Rules
variable "lb_rules" {
  description = "Lista de regras de balanceamento de carga"
  type = list(object({
    name                           = string
    protocol                       = string
    frontend_port                  = number
    backend_port                   = number
    frontend_ip_configuration_name = string
    backend_address_pool_names     = optional(list(string), [])
    probe_name                     = optional(string)
    enable_floating_ip             = optional(bool, false)
    enable_tcp_reset               = optional(bool, false)
    disable_outbound_snat          = optional(bool, false)
    idle_timeout_in_minutes        = optional(number, 4)
    load_distribution              = optional(string, "Default")
  }))
  default = []
  
  validation {
    condition = alltrue([
      for rule in var.lb_rules :
      contains(["Tcp", "Udp", "All"], rule.protocol)
    ])
    error_message = "O protocolo da regra deve ser Tcp, Udp ou All."
  }
  
  validation {
    condition = alltrue([
      for rule in var.lb_rules :
      contains(["Default", "SourceIP", "SourceIPProtocol"], rule.load_distribution)
    ])
    error_message = "load_distribution deve ser Default, SourceIP ou SourceIPProtocol."
  }
}

# NAT Rules
variable "nat_rules" {
  description = "Lista de regras NAT inbound"
  type = list(object({
    name                           = string
    protocol                       = string
    frontend_port                  = optional(number)
    backend_port                   = number
    frontend_ip_configuration_name = string
    frontend_port_start            = optional(number)
    frontend_port_end              = optional(number)
    backend_address_pool_name      = optional(string)
    enable_floating_ip             = optional(bool, false)
    enable_tcp_reset               = optional(bool, false)
    idle_timeout_in_minutes        = optional(number, 4)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for rule in var.nat_rules :
      contains(["Tcp", "Udp", "All"], rule.protocol)
    ])
    error_message = "O protocolo da regra NAT deve ser Tcp, Udp ou All."
  }
}

# Outbound Rules (Standard SKU only)
variable "outbound_rules" {
  description = "Lista de regras outbound (apenas Standard SKU)"
  type = list(object({
    name                     = string
    protocol                 = string
    backend_address_pool_name = string
    frontend_ip_configuration_names = list(string)
    allocated_outbound_ports = optional(number)
    enable_tcp_reset         = optional(bool, false)
    idle_timeout_in_minutes  = optional(number, 4)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for rule in var.outbound_rules :
      contains(["Tcp", "Udp", "All"], rule.protocol)
    ])
    error_message = "O protocolo da regra outbound deve ser Tcp, Udp ou All."
  }
}

# High Availability Ports Rule (Standard SKU only)
variable "ha_ports_rules" {
  description = "Lista de regras HA Ports para internal load balancers"
  type = list(object({
    name                           = string
    protocol                       = string
    frontend_ip_configuration_name = string
    backend_address_pool_names     = list(string)
    probe_name                     = optional(string)
    enable_floating_ip             = optional(bool, false)
    idle_timeout_in_minutes        = optional(number, 4)
  }))
  default = []
}

# Identity
variable "identity_type" {
  description = "Tipo de identidade gerenciada (SystemAssigned, UserAssigned)"
  type        = string
  default     = null
  
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "O identity_type deve ser SystemAssigned, UserAssigned ou ambos."
  }
}

variable "identity_ids" {
  description = "Lista de IDs de identidades gerenciadas atribuídas pelo usuário"
  type        = list(string)
  default     = []
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
  default     = ["LoadBalancerAlertEvent", "LoadBalancerProbeHealthStatus"]
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

# Additional Settings
variable "zones" {
  description = "Zonas de disponibilidade para o Load Balancer (Standard SKU)"
  type        = list(string)
  default     = null
  
  validation {
    condition     = var.zones == null || alltrue([for z in var.zones : contains(["1", "2", "3"], z)])
    error_message = "As zonas devem ser '1', '2' ou '3'."
  }
}