variable "name" {
  description = "Nome da DNS Zone"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-._]*[a-zA-Z0-9])?$", var.name))
    error_message = "O nome deve ser um nome de domínio válido."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde a DNS Zone será criada"
  type        = string
}

variable "zone_type" {
  description = "Tipo da DNS Zone (Public ou Private)"
  type        = string
  default     = "Public"
  
  validation {
    condition     = contains(["Public", "Private"], var.zone_type)
    error_message = "O zone_type deve ser 'Public' ou 'Private'."
  }
}

# Public DNS Zone Settings
variable "create_public_zone" {
  description = "Criar Public DNS Zone"
  type        = bool
  default     = true
}

# Private DNS Zone Settings
variable "create_private_zone" {
  description = "Criar Private DNS Zone"
  type        = bool
  default     = false
}

variable "registration_enabled" {
  description = "Habilitar auto-registro de VMs na Private DNS Zone"
  type        = bool
  default     = false
}

variable "vnet_links" {
  description = "Lista de VNets para vincular à Private DNS Zone"
  type = list(object({
    name                 = string
    virtual_network_id   = string
    registration_enabled = optional(bool, false)
  }))
  default = []
}

# SOA Record (apenas Public DNS)
variable "soa_record" {
  description = "Configuração do registro SOA (apenas Public DNS)"
  type = object({
    email         = string
    expire_time   = optional(number, 2419200)
    minimum_ttl   = optional(number, 300)
    refresh_time  = optional(number, 3600)
    retry_time    = optional(number, 300)
    serial_number = optional(number)
    ttl           = optional(number, 3600)
  })
  default = null
}

# A Records
variable "a_records" {
  description = "Lista de registros A"
  type = list(object({
    name    = string
    ttl     = optional(number, 3600)
    records = list(string)
  }))
  default = []
}

# AAAA Records
variable "aaaa_records" {
  description = "Lista de registros AAAA (IPv6)"
  type = list(object({
    name    = string
    ttl     = optional(number, 3600)
    records = list(string)
  }))
  default = []
}

# CNAME Records
variable "cname_records" {
  description = "Lista de registros CNAME"
  type = list(object({
    name   = string
    ttl    = optional(number, 3600)
    record = string
  }))
  default = []
}

# MX Records
variable "mx_records" {
  description = "Lista de registros MX"
  type = list(object({
    name = string
    ttl  = optional(number, 3600)
    records = list(object({
      preference = number
      exchange   = string
    }))
  }))
  default = []
}

# NS Records
variable "ns_records" {
  description = "Lista de registros NS"
  type = list(object({
    name    = string
    ttl     = optional(number, 3600)
    records = list(string)
  }))
  default = []
}

# PTR Records
variable "ptr_records" {
  description = "Lista de registros PTR"
  type = list(object({
    name    = string
    ttl     = optional(number, 3600)
    records = list(string)
  }))
  default = []
}

# SRV Records
variable "srv_records" {
  description = "Lista de registros SRV"
  type = list(object({
    name = string
    ttl  = optional(number, 3600)
    records = list(object({
      priority = number
      weight   = number
      port     = number
      target   = string
    }))
  }))
  default = []
}

# TXT Records
variable "txt_records" {
  description = "Lista de registros TXT"
  type = list(object({
    name    = string
    ttl     = optional(number, 3600)
    records = list(string)
  }))
  default = []
}

# CAA Records
variable "caa_records" {
  description = "Lista de registros CAA (Certificate Authority Authorization)"
  type = list(object({
    name = string
    ttl  = optional(number, 3600)
    records = list(object({
      flags = number
      tag   = string
      value = string
    }))
  }))
  default = []
}

# DNSSEC Settings (Public DNS only)
variable "enable_dnssec" {
  description = "Habilitar DNSSEC na zona (apenas Public DNS)"
  type        = bool
  default     = false
}

# Zone Settings
variable "number_of_record_sets" {
  description = "Número máximo de record sets na zona"
  type        = number
  default     = null
}

# Tags
variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

# Traffic Manager Profile Integration
variable "create_traffic_manager_records" {
  description = "Criar registros CNAME para Traffic Manager"
  type        = bool
  default     = false
}

variable "traffic_manager_records" {
  description = "Lista de registros CNAME para Traffic Manager endpoints"
  type = list(object({
    name                   = string
    ttl                    = optional(number, 300)
    traffic_manager_fqdn   = string
  }))
  default = []
}

# Azure Service Records (Private DNS)
variable "create_azure_service_records" {
  description = "Criar registros para serviços Azure (Private Link)"
  type        = bool
  default     = false
}

variable "azure_service_records" {
  description = "Registros A para Private Endpoints de serviços Azure"
  type = list(object({
    name        = string
    ip_address  = string
    ttl         = optional(number, 300)
  }))
  default = []
}

# Alias Records (Public DNS)
variable "create_alias_records" {
  description = "Criar registros alias para recursos Azure"
  type        = bool
  default     = false
}

variable "alias_records" {
  description = "Lista de registros alias"
  type = list(object({
    name                   = string
    type                   = string  # A, AAAA, CNAME
    ttl                    = optional(number, 3600)
    target_resource_id     = string
    target_resource_name   = optional(string)
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
  default     = ["QueryLog"]
}

variable "diagnostic_metrics" {
  description = "Categorias de métricas para habilitar"
  type        = list(string)
  default     = ["AllMetrics"]
}