variable "name" {
  description = "Nome do ExpressRoute Circuit"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,78}[a-zA-Z0-9]$", var.name))
    error_message = "O nome deve começar e terminar com letra ou número, pode conter letras, números, hífens e underscores, e ter entre 2 e 80 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde o ExpressRoute será criado"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde o ExpressRoute será criado"
  type        = string
}

# ExpressRoute Circuit Configuration
variable "service_provider_name" {
  description = "Nome do service provider (ex: Equinix, AT&T, Verizon)"
  type        = string
}

variable "peering_location" {
  description = "Localização do peering (ex: Silicon Valley, Washington DC)"
  type        = string
}

variable "bandwidth_in_mbps" {
  description = "Largura de banda em Mbps (50, 100, 200, 500, 1000, 2000, 5000, 10000)"
  type        = number
  
  validation {
    condition     = contains([50, 100, 200, 500, 1000, 2000, 5000, 10000], var.bandwidth_in_mbps)
    error_message = "A largura de banda deve ser um dos valores válidos: 50, 100, 200, 500, 1000, 2000, 5000, 10000."
  }
}

variable "sku" {
  description = "Configuração do SKU"
  type = object({
    tier   = string  # Standard, Premium, Local
    family = string  # MeteredData, UnlimitedData
  })
  
  validation {
    condition     = contains(["Standard", "Premium", "Local"], var.sku.tier)
    error_message = "O tier deve ser Standard, Premium ou Local."
  }
  
  validation {
    condition     = contains(["MeteredData", "UnlimitedData"], var.sku.family)
    error_message = "A family deve ser MeteredData ou UnlimitedData."
  }
}

variable "allow_classic_operations" {
  description = "Permitir operações do modelo clássico"
  type        = bool
  default     = false
}

variable "express_route_port_id" {
  description = "ID do ExpressRoute Direct port"
  type        = string
  default     = null
}

variable "bandwidth_in_gbps" {
  description = "Largura de banda em Gbps (para ExpressRoute Direct)"
  type        = number
  default     = null
}

# Azure Private Peering
variable "enable_azure_private_peering" {
  description = "Habilitar Azure Private Peering"
  type        = bool
  default     = false
}

variable "azure_private_peering" {
  description = "Configuração do Azure Private Peering"
  type = object({
    peer_asn                  = number
    primary_peer_address_prefix   = string
    secondary_peer_address_prefix = string
    vlan_id                   = number
    shared_key                = optional(string)
    ipv6 = optional(object({
      primary_peer_address_prefix   = string
      secondary_peer_address_prefix = string
      enabled                       = bool
    }))
    microsoft_peering_config = optional(object({
      advertised_public_prefixes = list(string)
      customer_asn               = optional(number)
      routing_registry_name      = optional(string)
    }))
  })
  default   = null
  sensitive = true
}

# Microsoft Peering
variable "enable_microsoft_peering" {
  description = "Habilitar Microsoft Peering"
  type        = bool
  default     = false
}

variable "microsoft_peering" {
  description = "Configuração do Microsoft Peering"
  type = object({
    peer_asn                      = number
    primary_peer_address_prefix   = string
    secondary_peer_address_prefix = string
    vlan_id                       = number
    shared_key                    = optional(string)
    customer_asn                  = optional(number)
    routing_registry_name         = optional(string, "ARIN")
    advertised_public_prefixes    = list(string)
    advertised_communities        = optional(list(string))
    ipv6 = optional(object({
      primary_peer_address_prefix   = string
      secondary_peer_address_prefix = string
      microsoft_peering = object({
        advertised_public_prefixes = list(string)
        customer_asn               = optional(number)
        routing_registry_name      = optional(string)
      })
      enabled = bool
    }))
  })
  default   = null
  sensitive = true
}

# ExpressRoute Gateway Connection
variable "create_gateway_connection" {
  description = "Criar conexão com Virtual Network Gateway"
  type        = bool
  default     = false
}

variable "virtual_network_gateway_id" {
  description = "ID do Virtual Network Gateway para conexão"
  type        = string
  default     = null
}

variable "authorization_key" {
  description = "Chave de autorização para conexão"
  type        = string
  default     = null
  sensitive   = true
}

variable "connection_name" {
  description = "Nome da conexão do gateway"
  type        = string
  default     = null
}

variable "routing_weight" {
  description = "Peso de roteamento para a conexão"
  type        = number
  default     = 0
}

variable "enable_fastpath" {
  description = "Habilitar FastPath (requer UltraPerformance ou ErGw3AZ gateway)"
  type        = bool
  default     = false
}

variable "express_route_gateway_bypass" {
  description = "Bypass do ExpressRoute Gateway"
  type        = bool
  default     = false
}

# Route Filters
variable "create_route_filter" {
  description = "Criar Route Filter para Microsoft Peering"
  type        = bool
  default     = false
}

variable "route_filter_name" {
  description = "Nome do Route Filter"
  type        = string
  default     = null
}

variable "route_filter_rules" {
  description = "Lista de regras do Route Filter"
  type = list(object({
    name            = string
    access          = string  # Allow, Deny
    rule_type       = string  # Community
    communities     = list(string)
  }))
  default = []
}

# ExpressRoute Circuit Authorization
variable "create_circuit_authorizations" {
  description = "Criar autorizações do circuit"
  type        = bool
  default     = false
}

variable "circuit_authorizations" {
  description = "Lista de autorizações do circuit"
  type = list(object({
    name = string
  }))
  default = []
}

# Global Reach
variable "enable_global_reach" {
  description = "Habilitar ExpressRoute Global Reach"
  type        = bool
  default     = false
}

variable "global_reach_connections" {
  description = "Lista de conexões Global Reach"
  type = list(object({
    name                          = string
    peer_express_route_circuit_id = string
    authorization_key             = optional(string)
  }))
  default   = []
  sensitive = true
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
  default     = ["PeeringRouteLog"]
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