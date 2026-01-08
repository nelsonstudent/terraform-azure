variable "name" {
  description = "Nome do Resource Group"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_().]{1,90}$", var.name))
    error_message = "O nome deve ter entre 1-90 caracteres e conter apenas letras, números, hífens, underscores, parênteses e pontos."
  }
}

variable "location" {
  description = "Localização do Resource Group"
  type        = string
}

variable "tags" {
  description = "Tags para aplicar ao Resource Group"
  type        = map(string)
  default     = {}
}

variable "managed_by" {
  description = "ID do recurso que gerencia este Resource Group"
  type        = string
  default     = null
}

variable "lock_level" {
  description = "Nível do lock (CanNotDelete ou ReadOnly)"
  type        = string
  default     = null

  validation {
    condition     = var.lock_level == null || contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "O lock_level deve ser 'CanNotDelete', 'ReadOnly' ou null."
  }
}

variable "lock_notes" {
  description = "Notas sobre o lock do Resource Group"
  type        = string
  default     = "Locked by Terraform"
}

variable "role_assignments" {
  description = "Lista de role assignments para o Resource Group"
  type = list(object({
    principal_id         = string
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
    description          = optional(string)
    condition            = optional(string)
    condition_version    = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for ra in var.role_assignments :
      (ra.role_definition_name != null && ra.role_definition_id == null) ||
      (ra.role_definition_name == null && ra.role_definition_id != null)
    ])
    error_message = "Cada role assignment deve ter role_definition_name OU role_definition_id, mas não ambos."
  }
}

variable "policy_assignments" {
  description = "Azure Policies para atribuir ao Resource Group"
  type = list(object({
    name                 = string
    policy_definition_id = string
    description          = optional(string)
    display_name         = optional(string)
    enforce              = optional(bool, true)
    identity_type        = optional(string)
    location             = optional(string)
    parameters           = optional(string)
    metadata             = optional(string)
    non_compliance_messages = optional(list(object({
      message                        = string
      policy_definition_reference_id = optional(string)
    })))
  }))
  default = []
}

variable "diagnostic_settings" {
  description = "Configurações de diagnóstico para Activity Log do Resource Group"
  type = object({
    enabled                        = bool
    name                           = optional(string, "diag-settings")
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    log_categories                 = optional(list(string), ["Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth"])
  })
  default = {
    enabled = false
  }
}

variable "budget" {
  description = "Configuração de budget para o Resource Group"
  type = object({
    enabled       = bool
    name          = optional(string)
    amount        = number
    time_grain    = optional(string, "Monthly")
    start_date    = optional(string)
    end_date      = optional(string)
    notifications = optional(list(object({
      enabled        = bool
      threshold      = number
      operator       = optional(string, "GreaterThanOrEqualTo")
      contact_emails = list(string)
      contact_roles  = optional(list(string), [])
      contact_groups = optional(list(string), [])
    })), [])
  })
  default = {
    enabled = false
    amount  = 0
  }

  validation {
    condition     = !var.budget.enabled || var.budget.amount > 0
    error_message = "O amount do budget deve ser maior que 0 quando enabled é true."
  }

  validation {
    condition     = var.budget.time_grain == null || contains(["Monthly", "Quarterly", "Annually"], var.budget.time_grain)
    error_message = "O time_grain deve ser 'Monthly', 'Quarterly' ou 'Annually'."
  }
}

variable "prevent_deletion" {
  description = "Prevenir deleção acidental do Resource Group (cria lock CanNotDelete)"
  type        = bool
  default     = false
}

variable "enable_delete_lock" {
  description = "Alias para prevent_deletion (mantido para compatibilidade)"
  type        = bool
  default     = null
}

variable "subscription_id" {
  description = "ID da subscription (opcional, usa a atual se não especificado)"
  type        = string
  default     = null
}