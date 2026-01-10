variable "name" {
  description = "Nome da Virtual Network"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}[a-zA-Z0-9_]$", var.name))
    error_message = "O nome deve começar com letra ou número, pode conter letras, números, pontos, hífens e underscores, e ter entre 2 e 64 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde a VNet será criada"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde a VNet será criada"
  type        = string
}

variable "address_space" {
  description = "Lista de blocos de endereços CIDR para a VNet"
  type        = list(string)
  
  validation {
    condition     = length(var.address_space) > 0
    error_message = "Deve haver pelo menos um bloco de endereços."
  }
}

variable "dns_servers" {
  description = "Lista de endereços IP de servidores DNS customizados"
  type        = list(string)
  default     = []
}

variable "bgp_community" {
  description = "Comunidade BGP associada à VNet (formato: 12076:xxxxx)"
  type        = string
  default     = null
}

variable "edge_zone" {
  description = "Edge Zone onde a VNet será criada"
  type        = string
  default     = null
}

variable "flow_timeout_in_minutes" {
  description = "Timeout de flow em minutos (4-30)"
  type        = number
  default     = null
  
  validation {
    condition     = var.flow_timeout_in_minutes == null || (var.flow_timeout_in_minutes >= 4 && var.flow_timeout_in_minutes <= 30)
    error_message = "O flow timeout deve estar entre 4 e 30 minutos."
  }
}

# Subnets
variable "subnets" {
  description = "Lista de subnets a serem criadas"
  type = list(object({
    name                                          = string
    address_prefixes                              = list(string)
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
    service_endpoints                             = optional(list(string), [])
    service_endpoint_policy_ids                   = optional(list(string), [])
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string), [])
      })
    })), [])
  }))
  default = []
}

# Network Security Groups
variable "network_security_groups" {
  description = "Lista de NSGs a serem criados"
  type = list(object({
    name = string
    security_rules = optional(list(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string)
      source_port_ranges           = optional(list(string))
      destination_port_range       = optional(string)
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))
      description                  = optional(string)
    })), [])
  }))
  default = []
}

# NSG to Subnet Association
variable "nsg_subnet_associations" {
  description = "Associações entre NSGs e Subnets"
  type = map(object({
    subnet_name = string
    nsg_name    = string
  }))
  default = {}
}

# Route Tables
variable "route_tables" {
  description = "Lista de Route Tables a serem criadas"
  type = list(object({
    name                          = string
    bgp_route_propagation_enabled = optional(bool, false)
    routes = optional(list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), [])
  }))
  default = []
}

# Route Table to Subnet Association
variable "route_table_subnet_associations" {
  description = "Associações entre Route Tables e Subnets"
  type = map(object({
    subnet_name      = string
    route_table_name = string
  }))
  default = {}
}

# DDoS Protection Plan
variable "ddos_protection_plan" {
  description = "Configuração do DDoS Protection Plan"
  type = object({
    enable = bool
    id     = optional(string)
  })
  default = {
    enable = false
  }
}

# VNet Peering
variable "vnet_peerings" {
  description = "Lista de VNet Peerings a serem criados"
  type = list(object({
    name                         = string
    remote_virtual_network_id    = string
    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  }))
  default = []
}

# NAT Gateway
variable "nat_gateways" {
  description = "Lista de NAT Gateways a serem criados"
  type = list(object({
    name                    = string
    sku_name                = optional(string, "Standard")
    idle_timeout_in_minutes = optional(number, 4)
    zones                   = optional(list(string), [])
    subnet_associations     = optional(list(string), [])
  }))
  default = []
}

# Public IPs para NAT Gateway
variable "nat_gateway_public_ips" {
  description = "Número de Public IPs para cada NAT Gateway"
  type        = map(number)
  default     = {}
}

# Service Endpoints
variable "service_endpoints" {
  description = "Service endpoints padrão para todas as subnets (pode ser sobrescrito por subnet)"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for endpoint in var.service_endpoints :
      contains([
        "Microsoft.Storage",
        "Microsoft.Sql",
        "Microsoft.AzureCosmosDB",
        "Microsoft.KeyVault",
        "Microsoft.ServiceBus",
        "Microsoft.EventHub",
        "Microsoft.AzureActiveDirectory",
        "Microsoft.ContainerRegistry",
        "Microsoft.CognitiveServices",
        "Microsoft.Web"
      ], endpoint)
    ])
    error_message = "Service endpoint inválido."
  }
}

# Network Watcher
variable "create_network_watcher" {
  description = "Criar Network Watcher para a região"
  type        = bool
  default     = false
}

variable "network_watcher_name" {
  description = "Nome do Network Watcher (se create_network_watcher = true)"
  type        = string
  default     = null
}

# Flow Logs
variable "enable_flow_logs" {
  description = "Habilitar NSG Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_storage_account_id" {
  description = "ID da Storage Account para Flow Logs"
  type        = string
  default     = null
}

variable "flow_logs_retention_days" {
  description = "Dias de retenção dos Flow Logs"
  type        = number
  default     = 7
}

variable "flow_logs_traffic_analytics" {
  description = "Configuração do Traffic Analytics"
  type = object({
    enabled               = bool
    workspace_id          = optional(string)
    workspace_region      = optional(string)
    workspace_resource_id = optional(string)
    interval_in_minutes   = optional(number, 10)
  })
  default = {
    enabled = false
  }
}

# Bastion Host
variable "create_bastion" {
  description = "Criar Azure Bastion Host"
  type        = bool
  default     = false
}

variable "bastion_config" {
  description = "Configuração do Azure Bastion"
  type = object({
    name                   = string
    sku                    = optional(string, "Basic")
    copy_paste_enabled     = optional(bool, true)
    file_copy_enabled      = optional(bool, false)
    ip_connect_enabled     = optional(bool, false)
    scale_units            = optional(number, 2)
    shareable_link_enabled = optional(bool, false)
    tunneling_enabled      = optional(bool, false)
  })
  default = null
}

# VPN Gateway
variable "create_vpn_gateway" {
  description = "Criar VPN Gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_config" {
  description = "Configuração do VPN Gateway"
  type = object({
    name                = string
    type                = optional(string, "Vpn")
    vpn_type            = optional(string, "RouteBased")
    sku                 = optional(string, "VpnGw1")
    generation          = optional(string, "Generation1")
    enable_bgp          = optional(bool, false)
    active_active       = optional(bool, false)
    private_ip_address_allocation = optional(string, "Dynamic")
  })
  default = null
}

# Application Gateway Subnet
variable "create_app_gateway_subnet" {
  description = "Criar subnet dedicada para Application Gateway"
  type        = bool
  default     = false
}

variable "app_gateway_subnet_prefix" {
  description = "Prefixo de endereço para subnet do Application Gateway"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
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
  default     = ["VMProtectionAlerts"]
}

variable "diagnostic_metrics" {
  description = "Categorias de métricas para habilitar"
  type        = list(string)
  default     = ["AllMetrics"]
}