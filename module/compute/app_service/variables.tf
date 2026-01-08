# Resource Group
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização dos recursos (ex: East US, Brazil South)"
  type        = string
}

# Service Plan Configuration
variable "service_plan_name" {
  description = "Nome do App Service Plan"
  type        = string
}

variable "os_type" {
  description = "Tipo de sistema operacional: Linux ou Windows"
  type        = string

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type deve ser 'Linux' ou 'Windows'"
  }
}

variable "sku_name" {
  description = "SKU do App Service Plan (ex: B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3)"
  type        = string
  default     = "B1"
}

variable "maximum_elastic_worker_count" {
  description = "Número máximo de workers para scaling (apenas Premium)"
  type        = number
  default     = null
}

variable "worker_count" {
  description = "Número de workers (instâncias)"
  type        = number
  default     = 1
}

variable "per_site_scaling_enabled" {
  description = "Habilitar scaling por site"
  type        = bool
  default     = false
}

variable "zone_balancing_enabled" {
  description = "Habilitar balanceamento entre zonas de disponibilidade"
  type        = bool
  default     = false
}

# App Service Configuration
variable "app_service_name" {
  description = "Nome do App Service (deve ser globalmente único)"
  type        = string
}

variable "https_only" {
  description = "Forçar apenas conexões HTTPS"
  type        = bool
  default     = true
}

variable "client_affinity_enabled" {
  description = "Habilitar client affinity (sticky sessions)"
  type        = bool
  default     = false
}

variable "enabled" {
  description = "App Service habilitado"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso público à internet"
  type        = bool
  default     = true
}

# Site Configuration
variable "always_on" {
  description = "Manter aplicação sempre ativa (não disponível no tier Free)"
  type        = bool
  default     = true
}

variable "ftps_state" {
  description = "Estado do FTPS: AllAllowed, FtpsOnly ou Disabled"
  type        = string
  default     = "FtpsOnly"

  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "ftps_state deve ser 'AllAllowed', 'FtpsOnly' ou 'Disabled'"
  }
}

variable "health_check_path" {
  description = "Caminho para health check (ex: /health)"
  type        = string
  default     = null
}

variable "health_check_eviction_time" {
  description = "Tempo em minutos antes de remover instância não saudável"
  type        = number
  default     = null
}

variable "http2_enabled" {
  description = "Habilitar HTTP/2"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Versão mínima do TLS: 1.0, 1.1 ou 1.2"
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version deve ser '1.0', '1.1' ou '1.2'"
  }
}

variable "remote_debugging_enabled" {
  description = "Habilitar debugging remoto"
  type        = bool
  default     = false
}

variable "remote_debugging_version" {
  description = "Versão do Visual Studio para debugging: VS2017, VS2019 ou VS2022"
  type        = string
  default     = "VS2022"
}

variable "use_32_bit_worker" {
  description = "Usar worker de 32 bits"
  type        = bool
  default     = false
}

variable "websockets_enabled" {
  description = "Habilitar WebSockets"
  type        = bool
  default     = false
}

variable "vnet_route_all_enabled" {
  description = "Rotear todo tráfego de saída pela VNet"
  type        = bool
  default     = false
}

variable "container_registry_use_managed_identity" {
  description = "Usar Managed Identity para acessar Container Registry"
  type        = bool
  default     = false
}

# Application Stack
variable "application_stack" {
  description = "Configuração da stack de aplicação (runtime)"
  type        = any
  default     = null
}

# CORS Settings
variable "cors_settings" {
  description = "Configurações de CORS"
  type = object({
    allowed_origins     = list(string)
    support_credentials = optional(bool)
  })
  default = null
}

# IP Restrictions
variable "ip_restrictions" {
  description = "Restrições de IP para acesso ao App Service"
  type = list(object({
    name                      = optional(string)
    ip_address                = optional(string)
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
    action                    = optional(string)
    priority                  = optional(number)
  }))
  default = []
}

# App Settings
variable "app_settings" {
  description = "Variáveis de ambiente da aplicação"
  type        = map(string)
  default     = {}
}

# Connection Strings
variable "connection_strings" {
  description = "Connection strings para banco de dados"
  type = list(object({
    name  = string
    type  = string # SQLServer, SQLAzure, Custom, MySql, PostgreSQL, etc
    value = string
  }))
  default   = []
  sensitive = true
}

# Managed Identity
variable "identity_type" {
  description = "Tipo de identidade: SystemAssigned, UserAssigned ou SystemAssigned, UserAssigned"
  type        = string
  default     = null

  validation {
    condition = var.identity_type == null || contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity_type)
    error_message = "identity_type deve ser 'SystemAssigned', 'UserAssigned' ou 'SystemAssigned, UserAssigned'"
  }
}

variable "identity_ids" {
  description = "IDs das User Assigned Identities"
  type        = list(string)
  default     = []
}

# Authentication
variable "auth_settings" {
  description = "Configurações de autenticação (Azure AD, etc)"
  type        = any
  default     = null
}

# Backup
variable "backup_settings" {
  description = "Configurações de backup"
  type = object({
    name                = string
    storage_account_url = string
    enabled             = optional(bool)
    schedule = object({
      frequency_interval       = number
      frequency_unit           = string # Day or Hour
      keep_at_least_one_backup = optional(bool)
      retention_period_days    = optional(number)
    })
  })
  default = null
}

# Logs
variable "enable_logs" {
  description = "Habilitar logs de diagnóstico"
  type        = bool
  default     = false
}

variable "detailed_error_messages" {
  description = "Habilitar mensagens de erro detalhadas"
  type        = bool
  default     = false
}

variable "failed_request_tracing" {
  description = "Habilitar rastreamento de requisições falhadas"
  type        = bool
  default     = false
}

variable "application_logs" {
  description = "Configurações de logs de aplicação"
  type        = any
  default     = null
}

variable "http_logs" {
  description = "Configurações de logs HTTP"
  type        = any
  default     = null
}

# Custom Domains
variable "custom_domains" {
  description = "Domínios customizados"
  type = map(object({
    hostname   = string
    ssl_state  = optional(string)
    thumbprint = optional(string)
  }))
  default = {}
}

# Deployment Slots
variable "deployment_slots" {
  description = "Slots de deployment (staging, etc)"
  type = map(object({
    app_settings = optional(map(string))
  }))
  default = null
}

# VNet Integration
variable "vnet_integration_subnet_id" {
  description = "ID da subnet para integração com VNet"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}
