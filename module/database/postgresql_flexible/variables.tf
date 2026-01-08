variable "name" {
  description = "Nome do PostgreSQL Flexible Server"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "O nome deve começar com letra minúscula ou número, conter apenas letras minúsculas, números e hífens, e ter entre 3 e 63 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde o PostgreSQL será criado"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde o PostgreSQL será criado"
  type        = string
}

variable "administrator_login" {
  description = "Nome do usuário administrador"
  type        = string
  
  validation {
    condition     = !contains(["admin", "administrator", "root", "guest", "public"], lower(var.administrator_login))
    error_message = "O login de administrador não pode ser 'admin', 'administrator', 'root', 'guest' ou 'public'."
  }
}

variable "administrator_password" {
  description = "Senha do usuário administrador (mínimo 8 caracteres)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.administrator_password) >= 8 && length(var.administrator_password) <= 128
    error_message = "A senha deve ter entre 8 e 128 caracteres."
  }
}

variable "sku_name" {
  description = "SKU do servidor (ex: B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Armazenamento em MB (32768 a 16777216)"
  type        = number
  default     = 32768
  
  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 16777216
    error_message = "O armazenamento deve estar entre 32768 MB (32 GB) e 16777216 MB (16 TB)."
  }
}

variable "storage_tier" {
  description = "Tier de armazenamento (P4, P6, P10, P15, P20, P30, P40, P50, P60, P70, P80)"
  type        = string
  default     = null
}

variable "auto_grow_enabled" {
  description = "Habilitar crescimento automático de armazenamento"
  type        = bool
  default     = true
}

variable "version" {
  description = "Versão do PostgreSQL (11, 12, 13, 14, 15, 16)"
  type        = string
  default     = "15"
  
  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.version)
    error_message = "A versão deve ser 11, 12, 13, 14, 15 ou 16."
  }
}

variable "zone" {
  description = "Zona de disponibilidade (1, 2 ou 3)"
  type        = string
  default     = null
  
  validation {
    condition     = var.zone == null || contains(["1", "2", "3"], var.zone)
    error_message = "A zona deve ser 1, 2 ou 3."
  }
}

variable "backup_retention_days" {
  description = "Dias de retenção de backup (7 a 35)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "O período de retenção deve estar entre 7 e 35 dias."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Habilitar backup geograficamente redundante"
  type        = bool
  default     = false
}

variable "create_mode" {
  description = "Modo de criação (Default, PointInTimeRestore, Replica, Update)"
  type        = string
  default     = "Default"
  
  validation {
    condition     = contains(["Default", "PointInTimeRestore", "Replica", "Update"], var.create_mode)
    error_message = "O create_mode deve ser Default, PointInTimeRestore, Replica ou Update."
  }
}

variable "point_in_time_restore_time_in_utc" {
  description = "Data/hora para restore point-in-time (formato RFC3339)"
  type        = string
  default     = null
}

variable "source_server_id" {
  description = "ID do servidor de origem para réplica ou restore"
  type        = string
  default     = null
}

# High Availability
variable "high_availability" {
  description = "Configurações de alta disponibilidade"
  type = object({
    mode                      = string
    standby_availability_zone = optional(string)
  })
  default = null
  
  validation {
    condition = var.high_availability == null || contains(
      ["ZoneRedundant", "SameZone"],
      var.high_availability.mode
    )
    error_message = "O modo de HA deve ser ZoneRedundant ou SameZone."
  }
}

# Maintenance Window
variable "maintenance_window" {
  description = "Janela de manutenção"
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
  
  validation {
    condition = var.maintenance_window == null || (
      var.maintenance_window.day_of_week >= 0 &&
      var.maintenance_window.day_of_week <= 6 &&
      var.maintenance_window.start_hour >= 0 &&
      var.maintenance_window.start_hour <= 23 &&
      var.maintenance_window.start_minute >= 0 &&
      var.maintenance_window.start_minute <= 59
    )
    error_message = "day_of_week deve estar entre 0-6, start_hour entre 0-23, e start_minute entre 0-59."
  }
}

# Authentication
variable "authentication" {
  description = "Configurações de autenticação"
  type = object({
    active_directory_auth_enabled = optional(bool, false)
    password_auth_enabled         = optional(bool, true)
    tenant_id                     = optional(string)
  })
  default = {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }
}

# Network
variable "delegated_subnet_id" {
  description = "ID da subnet delegada para VNet integration"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "ID da Private DNS Zone"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso público"
  type        = bool
  default     = true
}

# Firewall Rules
variable "firewall_rules" {
  description = "Lista de regras de firewall"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

# PostgreSQL Configurations
variable "postgresql_configurations" {
  description = "Configurações do PostgreSQL (key-value pairs)"
  type        = map(string)
  default     = {}
}

# Databases
variable "databases" {
  description = "Lista de databases a serem criados"
  type = list(object({
    name      = string
    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")
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

# Customer Managed Key
variable "customer_managed_key" {
  description = "Configuração de chave gerenciada pelo cliente"
  type = object({
    key_vault_key_id                     = string
    primary_user_assigned_identity_id    = optional(string)
    geo_backup_key_vault_key_id          = optional(string)
    geo_backup_user_assigned_identity_id = optional(string)
  })
  default = null
}

# Threat Protection
variable "threat_detection_enabled" {
  description = "Habilitar detecção de ameaças"
  type        = bool
  default     = false
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
  default     = ["PostgreSQLLogs"]
}

variable "diagnostic_metrics" {
  description = "Categorias de métricas para habilitar"
  type        = list(string)
  default     = ["AllMetrics"]
}

# Extensions
variable "postgresql_extensions" {
  description = "Lista de extensões do PostgreSQL para habilitar"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

# Replication
variable "replication_role" {
  description = "Papel de replicação (None, Primary, Secondary)"
  type        = string
  default     = "None"
  
  validation {
    condition     = contains(["None", "Primary", "Secondary"], var.replication_role)
    error_message = "O replication_role deve ser None, Primary ou Secondary."
  }
}
