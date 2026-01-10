variable "name" {
  description = "Nome do Key Vault (deve ser globalmente único)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "O nome deve ter entre 3-24 caracteres, começar com letra, e conter apenas letras, números e hífens."
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

variable "sku_name" {
  description = "SKU do Key Vault (standard ou premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "O SKU deve ser 'standard' ou 'premium'."
  }
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "enabled_for_deployment" {
  description = "Habilitar para deployment de VMs"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Habilitar para criptografia de disco"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Habilitar para deployment de templates ARM"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Usar RBAC ao invés de Access Policies"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Habilitar proteção contra purge (exclusão permanente)"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Dias de retenção para soft delete (7-90)"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "O período de retenção deve estar entre 7 e 90 dias."
  }
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso via rede pública"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Configurações de Network ACLs"
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = []
  }
}

variable "access_policies" {
  description = "Lista de access policies (usado quando RBAC está desabilitado)"
  type = list(object({
    object_id               = string
    tenant_id               = optional(string)
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = []
}

variable "secrets" {
  description = "Map de secrets para criar no Key Vault"
  type = map(object({
    value        = string
    content_type = optional(string)
    tags         = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}

variable "keys" {
  description = "Map de keys para criar no Key Vault"
  type = map(object({
    key_type     = string
    key_size     = optional(number)
    key_opts     = list(string)
    curve        = optional(string)
    expiration_date = optional(string)
    tags         = optional(map(string), {})
  }))
  default = {}
}

variable "certificates" {
  description = "Map de certificados para criar no Key Vault"
  type = map(object({
    contents     = optional(string)
    password     = optional(string)
    policy       = optional(any)
    tags         = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}

variable "private_endpoint_enabled" {
  description = "Habilitar Private Endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "ID da subnet para Private Endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "IDs das Private DNS Zones para Private Endpoint"
  type        = list(string)
  default     = []
}

variable "diagnostic_settings" {
  description = "Configurações de diagnóstico"
  type = object({
    enabled                        = bool
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs = optional(list(object({
      category = string
      enabled  = bool
    })), [])
    metrics = optional(list(object({
      category = string
      enabled  = bool
    })), [])
  })
  default = {
    enabled = false
  }
}

variable "tags" {
  description = "Tags para aplicar ao recurso"
  type        = map(string)
  default     = {}
}

variable "contact_email" {
  description = "Email de contato para notificações de certificados"
  type        = string
  default     = null
}