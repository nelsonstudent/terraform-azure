variable "name" {
  description = "Nome da Managed Identity"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{3,128}$", var.name))
    error_message = "O nome deve ter entre 3-128 caracteres e conter apenas letras, números, hífens e underscores."
  }
}

variable "location" {
  description = "Localização do recurso Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "tags" {
  description = "Tags para aplicar ao recurso"
  type        = map(string)
  default     = {}
}

variable "role_assignments" {
  description = "Lista de role assignments para a Managed Identity"
  type = list(object({
    scope                = string
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

variable "federated_identity_credentials" {
  description = "Federated Identity Credentials para Workload Identity (Kubernetes, GitHub Actions, etc)"
  type = list(object({
    name      = string
    issuer    = string
    subject   = string
    audiences = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for fic in var.federated_identity_credentials :
      can(regex("^[a-zA-Z0-9-]{3,120}$", fic.name))
    ])
    error_message = "O nome do federated credential deve ter entre 3-120 caracteres e conter apenas letras, números e hífens."
  }
}

variable "key_vault_access" {
  description = "Configuração de acesso ao Key Vault"
  type = object({
    enabled             = bool
    key_vault_id        = optional(string)
    key_permissions     = optional(list(string), [])
    secret_permissions  = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions = optional(list(string), [])
  })
  default = {
    enabled = false
  }
}

variable "storage_account_access" {
  description = "Configuração de acesso a Storage Accounts"
  type = list(object({
    storage_account_id   = string
    role_definition_name = string
  }))
  default = []
}

variable "sql_database_access" {
  description = "Configuração de acesso a SQL Databases"
  type = list(object({
    sql_server_name     = string
    database_name       = string
    resource_group_name = optional(string)
  }))
  default = []
}

variable "container_registry_access" {
  description = "Configuração de acesso a Container Registries"
  type = list(object({
    registry_id          = string
    role_definition_name = string
  }))
  default = []
}

variable "aks_access" {
  description = "Configuração de acesso a clusters AKS"
  type = list(object({
    cluster_id           = string
    role_definition_name = string
  }))
  default = []
}

variable "app_configuration_access" {
  description = "Configuração de acesso a App Configuration"
  type = list(object({
    app_config_id        = string
    role_definition_name = string
  }))
  default = []
}

variable "event_hub_access" {
  description = "Configuração de acesso a Event Hubs"
  type = list(object({
    event_hub_id         = string
    role_definition_name = string
  }))
  default = []
}

variable "service_bus_access" {
  description = "Configuração de acesso a Service Bus"
  type = list(object({
    service_bus_id       = string
    role_definition_name = string
  }))
  default = []
}

variable "cognitive_services_access" {
  description = "Configuração de acesso a Cognitive Services"
  type = list(object({
    cognitive_account_id = string
    role_definition_name = string
  }))
  default = []
}