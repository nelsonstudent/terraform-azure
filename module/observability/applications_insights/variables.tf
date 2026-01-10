variable "name" {
  description = "Nome do Application Insights"
  type        = string
}

variable "location" {
  description = "Localização do recurso Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "application_type" {
  description = "Tipo de aplicação (web, ios, java, etc)"
  type        = string
  default     = "web"

  validation {
    condition     = contains(["web", "ios", "other", "java", "MobileCenter", "Node.JS", "phone", "store"], var.application_type)
    error_message = "O tipo de aplicação deve ser: web, ios, other, java, MobileCenter, Node.JS, phone ou store."
  }
}

variable "workspace_id" {
  description = "ID do Log Analytics Workspace para integração"
  type        = string
  default     = null
}

variable "retention_in_days" {
  description = "Período de retenção dos dados em dias"
  type        = number
  default     = 90

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.retention_in_days)
    error_message = "O período de retenção deve ser: 30, 60, 90, 120, 180, 270, 365, 550 ou 730 dias."
  }
}

variable "daily_data_cap_in_gb" {
  description = "Limite diário de ingestão de dados em GB"
  type        = number
  default     = null
}

variable "daily_data_cap_notifications_disabled" {
  description = "Desabilitar notificações quando atingir o limite diário"
  type        = bool
  default     = false
}

variable "sampling_percentage" {
  description = "Percentual de sampling (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.sampling_percentage >= 0 && var.sampling_percentage <= 100
    error_message = "O percentual de sampling deve estar entre 0 e 100."
  }
}

variable "disable_ip_masking" {
  description = "Desabilitar mascaramento de IP"
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Desabilitar autenticação local (API Key)"
  type        = bool
  default     = false
}

variable "internet_ingestion_enabled" {
  description = "Habilitar ingestão de dados via internet pública"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Habilitar queries via internet pública"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para aplicar ao recurso"
  type        = map(string)
  default     = {}
}

variable "enable_smart_detection" {
  description = "Habilitar regras de detecção inteligente"
  type        = bool
  default     = true
}

variable "action_group_ids" {
  description = "IDs dos Action Groups para alertas"
  type        = list(string)
  default     = []
}