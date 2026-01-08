variable "name" {
  description = "Nome do Management Group (ID único)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_().]{1,90}$", var.name))
    error_message = "O nome deve ter entre 1-90 caracteres e conter apenas letras, números, hífens, underscores, parênteses e pontos."
  }
}

variable "display_name" {
  description = "Nome de exibição do Management Group"
  type        = string
  default     = null
}

variable "parent_management_group_id" {
  description = "ID do Management Group pai (se null, será criado no root)"
  type        = string
  default     = null
}

variable "subscription_ids" {
  description = "Lista de IDs de subscriptions para associar ao Management Group"
  type        = list(string)
  default     = []
}

variable "policy_assignments" {
  description = "Azure Policies para atribuir ao Management Group"
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

variable "role_assignments" {
  description = "Lista de role assignments para o Management Group"
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

variable "custom_policy_definitions" {
  description = "Definições de políticas customizadas para criar no Management Group"
  type = list(object({
    name         = string
    display_name = string
    description  = optional(string)
    policy_type  = optional(string, "Custom")
    mode         = optional(string, "All")
    metadata     = optional(string)
    parameters   = optional(string)
    policy_rule  = string
  }))
  default = []
}

variable "policy_set_definitions" {
  description = "Policy Set Definitions (Initiatives) para criar no Management Group"
  type = list(object({
    name                  = string
    display_name          = string
    description           = optional(string)
    policy_type           = optional(string, "Custom")
    metadata              = optional(string)
    parameters            = optional(string)
    policy_definition_references = list(object({
      policy_definition_id = string
      parameter_values     = optional(string)
      reference_id         = optional(string)
      policy_group_names   = optional(list(string))
    }))
    policy_definition_groups = optional(list(object({
      name                            = string
      display_name                    = optional(string)
      category                        = optional(string)
      description                     = optional(string)
      additional_metadata_resource_id = optional(string)
    })))
  }))
  default = []
}

variable "blueprints" {
  description = "Azure Blueprints para criar no Management Group"
  type = list(object({
    name          = string
    display_name  = optional(string)
    description   = optional(string)
    target_scope  = string
    time_created  = optional(string)
    versions      = optional(map(string))
  }))
  default = []
}

variable "child_management_groups" {
  description = "Management Groups filhos para criar"
  type = map(object({
    display_name = optional(string)
    subscription_ids = optional(list(string), [])
  }))
  default = {}
}

variable "enable_default_policies" {
  description = "Habilitar conjunto de políticas padrão recomendadas"
  type        = bool
  default     = false
}

variable "default_location" {
  description = "Localização padrão para recursos que requerem localização (como identities de policies)"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags para aplicar a recursos que suportam tags"
  type        = map(string)
  default     = {}
}