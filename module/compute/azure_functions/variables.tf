# Resource Group
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização dos recursos (ex: East US, Brazil South)"
  type        = string
}

# Storage Account (obrigatório para Functions)
variable "storage_account_name" {
  description = "Nome da Storage Account (deve ser globalmente único, apenas letras minúsculas e números)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name deve ter entre 3-24 caracteres, apenas letras minúsculas e números"
  }
}

variable "storage_account_tier" {
  description = "Tier da Storage Account: Standard ou Premium"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier deve ser 'Standard' ou 'Premium'"
  }
}

variable "storage_account_replication_type" {
  description = "Tipo de replicação: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type inválido"
  }
}

variable "storage_default_action" {
  description = "Ação padrão para network rules: Allow ou Deny"
  type        = string
  default     = "Allow"
}

variable "storage_ip_rules" {
  description = "Lista de IPs permitidos na Storage Account"
  type        = list(string)
  default     = []
}

variable "storage_subnet_ids" {
  description = "Lista de subnet IDs permitidas na Storage Account"
  type        = list(string)
  default     = []
}

variable "use_storage_access_key" {
  description = "Usar access key da storage account (false para usar Managed Identity)"
  type        = bool
  default     = true
}

# Service Plan
variable "service_plan_name" {
  description = "Nome do App Service Plan / Consumption Plan"
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
  description = "SKU do plano: Y1 (Consumption), EP1/EP2/EP3 (Elastic Premium), P1v2/P2v2/P3v2 (Premium)"
  type        = string
  default     = "Y1"
}

variable "maximum_elastic_worker_count" {
  description = "Número máximo de workers para Elastic Premium"
  type        = number
  default     = null
}

variable "worker_count" {
  description = "Número de workers"
  type        = number
  default     = null
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

# Function App Configuration
variable "function_app_name" {
  description = "Nome da Function App (deve ser globalmente único)"
  type        = string
}

variable "https_only" {
  description = "Forçar apenas conexões HTTPS"
  type        = bool
  default     = true
}

variable "enabled" {
  description = "Function App habilitada"
  type        = bool
  default     = true
}

variable "builtin_logging_enabled" {
  description = "Habilitar logging integrado"
  type        = bool
  default     = true
}

variable "client_certificate_enabled" {
  description = "Exigir certificado de cliente"
  type        = bool
  default     = false
}

variable "client_certificate_mode" {
  description = "Modo de certificado: Required, Optional ou OptionalInteractiveUser"
  type        = string
  default     = "Optional"
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso público à internet"
  type        = bool
  default     = true
}

variable "functions_extension_version" {
  description = "Versão do Azure Functions runtime: ~4, ~3, ~2, ~1"
  type        = string
  default     = "~4"

  validation {
    condition     = contains(["~4", "~3", "~2", "~1"], var.functions_extension_version)
    error_message = "functions_extension_version deve ser '~4', '~3', '~2' ou '~1'"
  }
}

variable "functions_worker_runtime" {
  description = "Runtime: dotnet, dotnet-isolated, node, python, java, powershell, custom"
  type        = string
  default     = "node"

  validation {
    condition     = contains(["dotnet", "dotnet-isolated", "node", "python", "java", "powershell", "custom"], var.functions_worker_runtime)
    error_message = "functions_worker_runtime inválido"
  }
}

variable "run_from_package_url" {
  description = "URL do pacote de deployment (blob storage)"
  type        = string
  default     = null
}

# Site Configuration
variable "always_on" {
  description = "Manter função sempre ativa (não disponível no Consumption plan)"
  type        = bool
  default     = false
}

variable "api_definition_url" {
  description = "URL da definição da API (OpenAPI/Swagger)"
  type        = string
  default     = null
}

variable "api_management_api_id" {
  description = "ID da API no Azure API Management"
  type        = string
  default     = null
}

variable "app_command_line" {
  description = "Comando de inicialização customizado"
  type        = string
  default     = null
}

variable "app_scale_limit" {
  description = "Limite máximo de scale out (instâncias)"
  type        = number
  default     = null
}

variable "ftps_state" {
  description = "Estado do FTPS: AllAllowed, FtpsOnly ou Disabled"
  type        = string
  default     = "Disabled"
}

variable "health_check_path" {
  description = "Caminho para health check"
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
}

variable "pre_warmed_instance_count" {
  description = "Número de instâncias pre-warmed (Elastic Premium)"
  type        = number
  default     = null
}

variable "remote_debugging_enabled" {
  description = "Habilitar debugging remoto"
  type        = bool
  default     = false
}

variable "remote_debugging_version" {
  description = "Versão do Visual Studio: VS2017, VS2019, VS2022"
  type        = string
  default     = "VS2022"
}

variable "runtime_scale_monitoring_enabled" {
  description = "Habilitar monitoramento de scale baseado em runtime"
  type        = bool
  default     = true
}

variable "use_32_bit_worker" {
  description = "Usar worker de 32 bits"
  type        = bool
  default     = false
}

variable "vnet_route_all_enabled" {
  description = "Rotear todo tráfego de saída pela VNet"
  type        = bool
  default     = false
}

variable "websockets_enabled" {
  description = "Habilitar WebSockets"
  type        = bool
  default     = false
}

variable "elastic_instance_minimum" {
  description = "Número mínimo de instâncias (Elastic Premium)"
  type        = number
  default     = null
}

variable "site_config_worker_count" {
  description = "Número de workers no site config"
  type        = number
  default     = null
}

# Application Stack
variable "application_stack" {
  description = "Configuração da stack de aplicação (runtime e versão)"
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
  description = "Restrições de IP para acesso"
  type = list(object({
    name                      = optional(string)
    ip_address                = optional(string)
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
    action                    = optional(string)
    priority                  = optional(number)
    headers                   = optional(any)
  }))
  default = []
}

# App Settings
variable "app_settings" {
  description = "Variáveis de ambiente da Function App"
  type        = map(string)
  default     = {}
}

# Connection Strings
variable "connection_strings" {
  description = "Connection strings"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default   = []
  sensitive = true
}

# Managed Identity
variable "identity_type" {
  description = "Tipo de identidade: SystemAssigned, UserAssigned ou SystemAssigned, UserAssigned"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition = var.identity_type == null || contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity_type)
    error_message = "identity_type inválido"
  }
}

variable "identity_ids" {
  description = "IDs das User Assigned Identities"
  type        = list(string)
  default     = []
}

# Sticky Settings (para slots)
variable "sticky_settings" {
  description = "Settings que não devem ser trocados durante slot swap"
  type = object({
    app_setting_names       = optional(list(string))
    connection_string_names = optional(list(string))
  })
  default = null
}

# Deployment Slots
variable "deployment_slots" {
  description = "Slots de deployment"
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

# Application Insights
variable "create_application_insights" {
  description = "Criar Application Insights automaticamente"
  type        = bool
  default     = true
}

variable "application_insights_connection_string" {
  description = "Connection string do Application Insights (se já existir)"
  type        = string
  default     = null
  sensitive   = true
}

variable "application_insights_key" {
  description = "Instrumentation key do Application Insights (se já existir)"
  type        = string
  default     = null
  sensitive   = true
}

variable "application_insights_type" {
  description = "Tipo do Application Insights: web, other, etc"
  type        = string
  default     = "web"
}

variable "application_insights_retention_days" {
  description = "Dias de retenção de dados no Application Insights"
  type        = number
  default     = 90
}

variable "application_insights_sampling_percentage" {
  description = "Percentual de sampling (0-100)"
  type        = number
  default     = 100
}

# App Service Logs
variable "app_service_logs" {
  description = "Configurações de logs"
  type = object({
    disk_quota_mb         = optional(number)
    retention_period_days = optional(number)
  })
  default = null
}

# Storage Triggers
variable "storage_queues" {
  description = "Storage Queues para triggers"
  type        = map(any)
  default     = {}
}

variable "storage_containers" {
  description = "Storage Containers para blob triggers"
  type = map(object({
    access_type = optional(string)
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}
