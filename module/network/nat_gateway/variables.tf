variable "name" {
  description = "Nome do NAT Gateway"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,80}$", var.name))
    error_message = "O nome deve ter entre 1-80 caracteres e conter apenas letras, números, hífens e underscores."
  }
}

variable "location" {
  description = "Localização do NAT Gateway"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "sku_name" {
  description = "SKU do NAT Gateway (Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = var.sku_name == "Standard"
    error_message = "Atualmente apenas SKU 'Standard' é suportada."
  }
}

variable "idle_timeout_in_minutes" {
  description = "Timeout de conexões idle em minutos (4-120)"
  type        = number
  default     = 4

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 120
    error_message = "O idle timeout deve estar entre 4 e 120 minutos."
  }
}

variable "zones" {
  description = "Lista de Availability Zones para o NAT Gateway"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for zone in var.zones : contains(["1", "2", "3"], zone)
    ])
    error_message = "As zonas devem ser '1', '2' ou '3'."
  }
}

variable "public_ip_count" {
  description = "Número de Public IPs a criar e associar (1-16)"
  type        = number
  default     = 1

  validation {
    condition     = var.public_ip_count >= 1 && var.public_ip_count <= 16
    error_message = "O número de Public IPs deve estar entre 1 e 16."
  }
}

variable "public_ip_prefix_id" {
  description = "ID de um Public IP Prefix existente para usar"
  type        = string
  default     = null
}

variable "public_ip_prefix_length" {
  description = "Tamanho do Public IP Prefix a criar (28-31)"
  type        = number
  default     = null

  validation {
    condition     = var.public_ip_prefix_length == null || (var.public_ip_prefix_length >= 28 && var.public_ip_prefix_length <= 31)
    error_message = "O prefix length deve estar entre 28 e 31."
  }
}

variable "existing_public_ip_ids" {
  description = "Lista de IDs de Public IPs existentes para associar"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para associar ao NAT Gateway"
  type        = list(string)
  default     = []
}

variable "create_public_ips" {
  description = "Criar novos Public IPs automaticamente"
  type        = bool
  default     = true
}

variable "public_ip_sku" {
  description = "SKU dos Public IPs (Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = var.public_ip_sku == "Standard"
    error_message = "NAT Gateway requer Public IPs com SKU 'Standard'."
  }
}

variable "public_ip_allocation_method" {
  description = "Método de alocação dos Public IPs (Static)"
  type        = string
  default     = "Static"

  validation {
    condition     = var.public_ip_allocation_method == "Static"
    error_message = "NAT Gateway requer Public IPs com alocação 'Static'."
  }
}

variable "diagnostic_settings" {
  description = "Configurações de diagnóstico para o NAT Gateway"
  type = object({
    enabled                        = bool
    name                           = optional(string, "diag-settings")
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    log_categories                 = optional(list(string), [])
    metric_categories              = optional(list(string), ["AllMetrics"])
  })
  default = {
    enabled = false
  }
}

variable "alerts" {
  description = "Configuração de alertas para o NAT Gateway"
  type = object({
    enabled             = bool
    action_group_ids    = optional(list(string), [])
    snat_port_threshold = optional(number, 80)
    data_path_threshold = optional(number, 90)
  })
  default = {
    enabled = false
  }
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}