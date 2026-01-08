variable "name" {
  description = "Nome do Azure Redis Cache"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.name))
    error_message = "O nome deve conter apenas letras, números e hífens, com até 63 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde o Redis Cache será criado"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde o Redis Cache será criado"
  type        = string
}

variable "capacity" {
  description = "Tamanho do cache (0, 1, 2, 3, 4, 5, 6 para Basic/Standard; 1-5 para Premium)"
  type        = number
  
  validation {
    condition     = var.capacity >= 0 && var.capacity <= 6
    error_message = "A capacidade deve estar entre 0 e 6."
  }
}

variable "family" {
  description = "Família do SKU (C para Basic/Standard, P para Premium)"
  type        = string
  
  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "A família deve ser 'C' (Basic/Standard) ou 'P' (Premium)."
  }
}

variable "sku_name" {
  description = "SKU do Redis Cache (Basic, Standard, Premium)"
  type        = string
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "O SKU deve ser 'Basic', 'Standard' ou 'Premium'."
  }
}

variable "enable_non_ssl_port" {
  description = "Habilitar porta não-SSL (6379)"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Versão mínima do TLS (1.0, 1.1, 1.2)"
  type        = string
  default     = "1.2"
  
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "A versão do TLS deve ser '1.0', '1.1' ou '1.2'."
  }
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso à rede pública"
  type        = bool
  default     = true
}

variable "replicas_per_master" {
  description = "Número de réplicas por master (apenas Premium)"
  type        = number
  default     = null
  
  validation {
    condition     = var.replicas_per_master == null || (var.replicas_per_master >= 1 && var.replicas_per_master <= 3)
    error_message = "O número de réplicas deve estar entre 1 e 3."
  }
}

variable "replicas_per_primary" {
  description = "Número de réplicas por primary (apenas Premium)"
  type        = number
  default     = null
  
  validation {
    condition     = var.replicas_per_primary == null || (var.replicas_per_primary >= 1 && var.replicas_per_primary <= 3)
    error_message = "O número de réplicas deve estar entre 1 e 3."
  }
}

variable "shard_count" {
  description = "Número de shards (apenas Premium, requer clustering)"
  type        = number
  default     = null
  
  validation {
    condition     = var.shard_count == null || (var.shard_count >= 1 && var.shard_count <= 10)
    error_message = "O número de shards deve estar entre 1 e 10."
  }
}

variable "subnet_id" {
  description = "ID da subnet para implantação do Redis Cache (apenas Premium)"
  type        = string
  default     = null
}

variable "private_static_ip_address" {
  description = "IP privado estático (apenas com subnet_id)"
  type        = string
  default     = null
}

variable "zones" {
  description = "Lista de zonas de disponibilidade (apenas Premium)"
  type        = list(string)
  default     = null
  
  validation {
    condition     = var.zones == null || alltrue([for z in var.zones : contains(["1", "2", "3"], z)])
    error_message = "As zonas devem ser '1', '2' ou '3'."
  }
}

variable "redis_configuration" {
  description = "Configurações do Redis"
  type = object({
    aof_backup_enabled              = optional(bool)
    aof_storage_connection_string_0 = optional(string)
    aof_storage_connection_string_1 = optional(string)
    enable_authentication           = optional(bool)
    maxmemory_reserved              = optional(number)
    maxmemory_delta                 = optional(number)
    maxmemory_policy                = optional(string)
    maxfragmentationmemory_reserved = optional(number)
    rdb_backup_enabled              = optional(bool)
    rdb_backup_frequency            = optional(number)
    rdb_backup_max_snapshot_count   = optional(number)
    rdb_storage_connection_string   = optional(string)
    notify_keyspace_events          = optional(string)
  })
  default = {
    enable_authentication = true
    maxmemory_policy      = "volatile-lru"
  }
}

variable "patch_schedule" {
  description = "Janela de manutenção para patches"
  type = list(object({
    day_of_week        = string
    start_hour_utc     = number
    maintenance_window = optional(string)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for schedule in var.patch_schedule :
      contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], schedule.day_of_week)
    ])
    error_message = "day_of_week deve ser um dia válido da semana em inglês."
  }
  
  validation {
    condition = alltrue([
      for schedule in var.patch_schedule :
      schedule.start_hour_utc >= 0 && schedule.start_hour_utc <= 23
    ])
    error_message = "start_hour_utc deve estar entre 0 e 23."
  }
}

variable "firewall_rules" {
  description = "Lista de regras de firewall"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "identity_type" {
  description = "Tipo de identidade gerenciada (SystemAssigned, UserAssigned)"
  type        = string
  default     = null
  
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "O identity_type deve ser 'SystemAssigned', 'UserAssigned' ou 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "Lista de IDs de identidades gerenciadas atribuídas pelo usuário"
  type        = list(string)
  default     = []
}

variable "redis_version" {
  description = "Versão do Redis (4 ou 6)"
  type        = number
  default     = 6
  
  validation {
    condition     = contains([4, 6], var.redis_version)
    error_message = "A versão do Redis deve ser 4 ou 6."
  }
}

variable "tenant_settings" {
  description = "Configurações de tenant personalizadas"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

# Private Endpoint Configuration
variable "enable_private_endpoint" {
  description = "Habilitar Private Endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "ID da subnet para o Private Endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Lista de IDs de Private DNS Zones"
  type        = list(string)
  default     = []
}

# Monitoring and Diagnostics
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
  default     = ["ConnectedClientList"]
}

variable "diagnostic_metrics" {
  description = "Categorias de métricas para habilitar"
  type        = list(string)
  default     = ["AllMetrics"]
}