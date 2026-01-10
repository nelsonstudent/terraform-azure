variable "subscription_id" {
  description = "ID da subscription para habilitar o Defender"
  type        = string
  default     = null
}

variable "resource_type" {
  description = "Tipo de recurso para proteção (VirtualMachines, SqlServers, AppServices, StorageAccounts, KubernetesService, ContainerRegistry, KeyVaults, Dns, Arm, OpenSourceRelationalDatabases, Containers, CosmosDbs, CloudPosture, Api)"
  type        = string

  validation {
    condition = contains([
      "VirtualMachines",
      "SqlServers",
      "AppServices",
      "StorageAccounts",
      "KubernetesService",
      "ContainerRegistry",
      "KeyVaults",
      "Dns",
      "Arm",
      "OpenSourceRelationalDatabases",
      "Containers",
      "CosmosDbs",
      "CloudPosture",
      "Api"
    ], var.resource_type)
    error_message = "Tipo de recurso inválido. Consulte a documentação para tipos suportados."
  }
}

variable "tier" {
  description = "Tier de preços (Standard ou Free)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Free"], var.tier)
    error_message = "O tier deve ser 'Standard' ou 'Free'."
  }
}

variable "subplan" {
  description = "Subplan para tipos de recursos específicos (P1, P2 para VMs e Containers)"
  type        = string
  default     = null
}

variable "extensions" {
  description = "Extensões para tipos de recursos específicos"
  type = list(object({
    name                             = string
    additional_extension_properties  = optional(map(string))
  }))
  default = []
}

variable "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace para integração"
  type        = string
  default     = null
}

variable "auto_provisioning" {
  description = "Configuração de auto-provisioning de agentes"
  type = object({
    enabled                       = bool
    log_analytics_workspace_id    = optional(string)
    security_center_subscription  = optional(string)
  })
  default = {
    enabled = true
  }
}

variable "security_contacts" {
  description = "Contatos de segurança para notificações"
  type = list(object({
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
    name                = optional(string, "default1")
  }))
  default = []
}

variable "email_security_contact" {
  description = "Email principal para contato de segurança (simplificado)"
  type        = string
  default     = null
}

variable "phone_security_contact" {
  description = "Telefone para contato de segurança (simplificado)"
  type        = string
  default     = null
}

variable "alert_notifications_enabled" {
  description = "Habilitar notificações de alertas"
  type        = bool
  default     = true
}

variable "alerts_to_admins_enabled" {
  description = "Enviar alertas para administradores da subscription"
  type        = bool
  default     = true
}

variable "assessments_settings" {
  description = "Configurações de assessment"
  type = map(object({
    enabled = bool
  }))
  default = {}
}

variable "workflow_automations" {
  description = "Automações de workflow para resposta a alertas"
  type = list(object({
    name                = string
    location            = string
    resource_group_name = string
    description         = optional(string)
    enabled             = optional(bool, true)
    scopes              = list(string)
    sources = list(object({
      event_source = string
      rule_sets = optional(list(object({
        rules = list(object({
          property_path     = string
          operator          = string
          expected_value    = string
          property_type     = string
        }))
      })))
    }))
    actions = list(object({
      type               = string
      resource_id        = string
      trigger_url        = optional(string)
      connection_string  = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = []
}

variable "jit_policies" {
  description = "Políticas de Just-In-Time VM Access"
  type = list(object({
    name                = string
    location            = string
    resource_group_name = string
    virtual_machine_ids = list(string)
    rules               = list(object({
      number                        = number
      protocol                      = string
      allowed_source_address_prefix = string
      max_request_access_duration   = string
    }))
  }))
  default = []
}

variable "advanced_threat_protection" {
  description = "Configuração de Advanced Threat Protection para recursos específicos"
  type = list(object({
    target_resource_id = string
    enabled            = bool
  }))
  default = []
}

variable "regulatory_compliance_standards" {
  description = "Standards de compliance regulatório para habilitar"
  type = list(object({
    name    = string
    enabled = bool
  }))
  default = []
}

variable "security_center_pricing" {
  description = "Mapa de tipos de recursos e seus tiers (alternativa para configuração múltipla)"
  type = map(object({
    tier       = string
    subplan    = optional(string)
    extensions = optional(list(object({
      name                             = string
      additional_extension_properties  = optional(map(string))
    })))
  }))
  default = {}
}

variable "defender_for_containers_settings" {
  description = "Configurações específicas para Defender for Containers"
  type = object({
    scan_images_on_push                  = optional(bool, true)
    agentless_vulnerability_assessment   = optional(bool, true)
    runtime_threat_protection            = optional(bool, true)
  })
  default = {}
}

variable "defender_cspm_enabled" {
  description = "Habilitar Defender CSPM (Cloud Security Posture Management)"
  type        = bool
  default     = false
}

variable "mcsb_enabled" {
  description = "Habilitar Microsoft Cloud Security Benchmark"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para recursos que suportam tags"
  type        = map(string)
  default     = {}
}