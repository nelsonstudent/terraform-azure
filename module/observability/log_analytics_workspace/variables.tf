variable "name" {
  description = "Nome do Log Analytics Workspace"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{2,61}[a-zA-Z0-9]$", var.name))
    error_message = "O nome deve começar e terminar com letra/número, pode conter hífens, e ter entre 4 e 63 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde o workspace será criado"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde o workspace será criado"
  type        = string
}

variable "sku" {
  description = "SKU do workspace (Free, PerGB2018, PerNode, Premium, Standalone, Unlimited, CapacityReservation)"
  type        = string
  default     = "PerGB2018"
  
  validation {
    condition = contains([
      "Free", "PerGB2018", "PerNode", "Premium", "Standalone", "Unlimited", "CapacityReservation"
    ], var.sku)
    error_message = "SKU deve ser um dos valores válidos."
  }
}

variable "retention_in_days" {
  description = "Dias de retenção de logs (30-730, ou 7 para Free tier)"
  type        = number
  default     = 30
  
  validation {
    condition     = (var.retention_in_days >= 30 && var.retention_in_days <= 730) || var.retention_in_days == 7
    error_message = "Retenção deve ser 7 (Free tier) ou entre 30 e 730 dias."
  }
}

variable "daily_quota_gb" {
  description = "Quota diária de ingestão em GB (-1 para ilimitado)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Permitir ingestão de dados via internet pública"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Permitir queries via internet pública"
  type        = bool
  default     = true
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacidade de reserva para commitment tier (100-5000 GB)"
  type        = number
  default     = null
  
  validation {
    condition = var.reservation_capacity_in_gb_per_day == null || (
      var.reservation_capacity_in_gb_per_day >= 100 &&
      var.reservation_capacity_in_gb_per_day <= 5000
    )
    error_message = "Capacidade de reserva deve estar entre 100 e 5000 GB."
  }
}

variable "local_authentication_enabled" {
  description = "Desabilitar autenticação via chaves (forçar Azure AD)"
  type        = bool
  default     = false
}

variable "cmk_for_query_forced" {
  description = "Forçar Customer Managed Key para queries"
  type        = bool
  default     = false
}

# Data Export Rules
variable "data_export_rules" {
  description = "Lista de regras de exportação de dados"
  type = list(object({
    name                    = string
    enabled                 = optional(bool, true)
    destination_resource_id = string
    table_names             = list(string)
  }))
  default = []
}

# Linked Services
variable "linked_services" {
  description = "Lista de serviços vinculados"
  type = list(object({
    name                     = string
    resource_id              = optional(string)
    write_access_resource_id = optional(string)
  }))
  default = []
}

# Linked Storage Accounts
variable "linked_storage_accounts" {
  description = "Storage Accounts vinculados para diferentes tipos de dados"
  type = object({
    custom_logs          = optional(list(string))
    azure_watson         = optional(list(string))
    query                = optional(list(string))
    alerts               = optional(list(string))
  })
  default = {}
}

# Saved Searches (Queries)
variable "saved_searches" {
  description = "Lista de queries salvas"
  type = list(object({
    name                       = string
    display_name               = string
    category                   = string
    query                      = string
    function_alias             = optional(string)
    function_parameters        = optional(list(string))
  }))
  default = []
}

# Solutions
variable "solutions" {
  description = "Lista de solutions a serem instaladas"
  type = list(object({
    solution_name = string
    publisher     = optional(string, "Microsoft")
    product       = optional(string)
    plan_name     = optional(string)
    plan_publisher = optional(string, "Microsoft")
    plan_product   = optional(string)
  }))
  default = []
}

# Common Solutions
variable "enable_common_solutions" {
  description = "Habilitar solutions comuns automaticamente"
  type = object({
    security_center            = optional(bool, false)
    update_management          = optional(bool, false)
    change_tracking            = optional(bool, false)
    sql_assessment             = optional(bool, false)
    container_insights         = optional(bool, false)
    vm_insights                = optional(bool, false)
    service_map                = optional(bool, false)
    azure_automation           = optional(bool, false)
    activity_log_analytics     = optional(bool, false)
    key_vault_analytics        = optional(bool, false)
    network_performance_monitor = optional(bool, false)
  })
  default = {}
}

# Tables (Custom Logs)
variable "custom_tables" {
  description = "Lista de tabelas customizadas"
  type = list(object({
    name           = string
    retention_days = optional(number)
    total_retention_days = optional(number)
    
    plan = optional(string, "Analytics")
    
    schema = object({
      columns = list(object({
        name = string
        type = string
      }))
    })
  }))
  default = []
}

# Data Collection Endpoint
variable "create_data_collection_endpoint" {
  description = "Criar Data Collection Endpoint"
  type        = bool
  default     = false
}

variable "data_collection_endpoint_name" {
  description = "Nome do Data Collection Endpoint"
  type        = string
  default     = null
}

variable "data_collection_endpoint_public_network_access_enabled" {
  description = "Permitir acesso público ao DCE"
  type        = bool
  default     = true
}

# Identity
variable "identity_type" {
  description = "Tipo de identidade gerenciada (SystemAssigned, UserAssigned)"
  type        = string
  default     = null
  
  validation {
    condition = var.identity_type == null || contains(
      ["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"],
      var.identity_type
    )
    error_message = "identity_type deve ser SystemAssigned, UserAssigned ou ambos."
  }
}

variable "identity_ids" {
  description = "Lista de IDs de identidades gerenciadas"
  type        = list(string)
  default     = []
}

# Customer Managed Key
variable "customer_managed_key" {
  description = "Configuração de Customer Managed Key"
  type = object({
    key_vault_key_id   = string
    identity_client_id = optional(string)
  })
  default = null
}

# Monitoring
variable "enable_diagnostic_settings" {
  description = "Habilitar diagnostic settings para o próprio workspace"
  type        = bool
  default     = false
}

variable "diagnostic_settings_storage_account_id" {
  description = "Storage Account ID para diagnostic settings"
  type        = string
  default     = null
}

variable "diagnostic_logs" {
  description = "Categorias de logs para diagnostic settings"
  type        = list(string)
  default     = ["Audit"]
}

variable "diagnostic_metrics" {
  description = "Categorias de métricas para diagnostic settings"
  type        = list(string)
  default     = ["AllMetrics"]
}

# Tags
variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}