# Resource Group
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização dos recursos (ex: East US, Brazil South)"
  type        = string
}

# Log Analytics Workspace
variable "create_log_analytics_workspace" {
  description = "Criar Log Analytics Workspace automaticamente"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Nome do Log Analytics Workspace"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace existente (se create_log_analytics_workspace = false)"
  type        = string
  default     = null
}

variable "log_analytics_sku" {
  description = "SKU do Log Analytics: Free, PerNode, Premium, Standard, Standalone, Unlimited, PerGB2018"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Dias de retenção de logs"
  type        = number
  default     = 30
}

# Container Apps Environment
variable "environment_name" {
  description = "Nome do Container Apps Environment"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "ID da subnet para infraestrutura do Container Apps (opcional, para VNet integration)"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Habilitar load balancer interno (requer VNet)"
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Habilitar redundância de zona (availability zones)"
  type        = bool
  default     = false
}

variable "workload_profiles" {
  description = "Workload profiles para Consumption e Dedicated"
  type = list(object({
    name                  = string
    workload_profile_type = string # Consumption, D4, D8, D16, D32, E4, E8, E16, E32
    minimum_count         = optional(number)
    maximum_count         = optional(number)
  }))
  default = []
}

# Container App
variable "container_app_name" {
  description = "Nome do Container App"
  type        = string
}

variable "revision_mode" {
  description = "Modo de revisão: Single ou Multiple"
  type        = string
  default     = "Single"

  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "revision_mode deve ser 'Single' ou 'Multiple'"
  }
}

variable "workload_profile_name" {
  description = "Nome do workload profile a usar (Consumption por padrão)"
  type        = string
  default     = null
}

variable "revision_suffix" {
  description = "Sufixo da revisão (auto-gerado se null)"
  type        = string
  default     = null
}

# Template Configuration
variable "min_replicas" {
  description = "Número mínimo de réplicas"
  type        = number
  default     = 0

  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 30
    error_message = "min_replicas deve estar entre 0 e 30"
  }
}

variable "max_replicas" {
  description = "Número máximo de réplicas"
  type        = number
  default     = 10

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 30
    error_message = "max_replicas deve estar entre 1 e 30"
  }
}

# Containers
variable "containers" {
  description = "Lista de containers a executar"
  type = list(object({
    name    = string
    image   = string
    cpu     = number
    memory  = string
    args    = optional(list(string))
    command = optional(list(string))
    env = optional(list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    })))
    liveness_probe = optional(object({
      transport                = string # HTTP, TCP
      port                     = number
      path                     = optional(string)
      host                     = optional(string)
      initial_delay            = optional(number)
      interval_seconds         = optional(number)
      timeout                  = optional(number)
      failure_count_threshold  = optional(number)
      success_count_threshold  = optional(number)
      headers = optional(list(object({
        name  = string
        value = string
      })))
    }))
    readiness_probe = optional(object({
      transport                = string
      port                     = number
      path                     = optional(string)
      host                     = optional(string)
      initial_delay            = optional(number)
      interval_seconds         = optional(number)
      timeout                  = optional(number)
      failure_count_threshold  = optional(number)
      success_count_threshold  = optional(number)
      headers = optional(list(object({
        name  = string
        value = string
      })))
    }))
    startup_probe = optional(object({
      transport                = string
      port                     = number
      path                     = optional(string)
      host                     = optional(string)
      initial_delay            = optional(number)
      interval_seconds         = optional(number)
      timeout                  = optional(number)
      failure_count_threshold  = optional(number)
      headers = optional(list(object({
        name  = string
        value = string
      })))
    }))
    volume_mounts = optional(list(object({
      name = string
      path = string
    })))
  }))
}

# Init Containers
variable "init_containers" {
  description = "Init containers para executar antes dos containers principais"
  type = list(object({
    name    = string
    image   = string
    cpu     = optional(number)
    memory  = optional(string)
    args    = optional(list(string))
    command = optional(list(string))
    env = optional(list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    })))
    volume_mounts = optional(list(object({
      name = string
      path = string
    })))
  }))
  default = []
}

# Volumes
variable "volumes" {
  description = "Volumes para os containers"
  type = list(object({
    name         = string
    storage_type = string # AzureFile, EmptyDir, Secret
    storage_name = optional(string)
  }))
  default = []
}

# Secrets
variable "secrets" {
  description = "Secrets para o Container App"
  type = list(object({
    name  = string
    value = string
  }))
  default   = []
  sensitive = true
}

# Ingress Configuration
variable "ingress_enabled" {
  description = "Habilitar ingress (tráfego HTTP/HTTPS)"
  type        = bool
  default     = true
}

variable "ingress_external_enabled" {
  description = "Habilitar ingress externo (público)"
  type        = bool
  default     = true
}

variable "ingress_target_port" {
  description = "Porta do container que receberá tráfego"
  type        = number
  default     = 80
}

variable "ingress_transport" {
  description = "Protocolo de transporte: auto, http, http2, tcp"
  type        = string
  default     = "auto"

  validation {
    condition     = contains(["auto", "http", "http2", "tcp"], var.ingress_transport)
    error_message = "ingress_transport deve ser 'auto', 'http', 'http2' ou 'tcp'"
  }
}

variable "ingress_allow_insecure_connections" {
  description = "Permitir conexões HTTP não seguras"
  type        = bool
  default     = false
}

variable "ingress_exposed_port" {
  description = "Porta exposta externamente (apenas para transport = tcp)"
  type        = number
  default     = null
}

variable "ingress_traffic_weights" {
  description = "Distribuição de tráfego entre revisões"
  type = list(object({
    percentage      = number
    latest_revision = optional(bool)
    revision_suffix = optional(string)
    label           = optional(string)
  }))
  default = [
    {
      percentage      = 100
      latest_revision = true
    }
  ]
}

# Custom Domains
variable "custom_domains" {
  description = "Domínios customizados"
  type = list(object({
    name                     = string
    certificate_binding_type = optional(string)
    certificate_id           = optional(string)
  }))
  default = []
}

# IP Security Restrictions
variable "ip_security_restrictions" {
  description = "Restrições de IP para ingress"
  type = list(object({
    name             = string
    ip_address_range = string
    action           = string # Allow or Deny
    description      = optional(string)
  }))
  default = []
}

# Scale Rules
variable "http_scale_rules" {
  description = "Regras de escala baseadas em requisições HTTP"
  type = list(object({
    name                = string
    concurrent_requests = number
  }))
  default = []
}

variable "tcp_scale_rules" {
  description = "Regras de escala baseadas em conexões TCP"
  type = list(object({
    name                = string
    concurrent_requests = number
  }))
  default = []
}

variable "azure_queue_scale_rules" {
  description = "Regras de escala baseadas em Azure Storage Queue"
  type = list(object({
    name         = string
    queue_name   = string
    queue_length = number
    authentication = object({
      secret_name       = string
      trigger_parameter = string
    })
  }))
  default = []
}

variable "custom_scale_rules" {
  description = "Regras de escala customizadas (KEDA scalers)"
  type = list(object({
    name             = string
    custom_rule_type = string
    metadata         = map(string)
    authentication = optional(list(object({
      secret_name       = string
      trigger_parameter = string
    })))
  }))
  default = []
}

# Dapr Configuration
variable "dapr_enabled" {
  description = "Habilitar Dapr (Distributed Application Runtime)"
  type        = bool
  default     = false
}

variable "dapr_app_id" {
  description = "ID da aplicação Dapr"
  type        = string
  default     = null
}

variable "dapr_app_port" {
  description = "Porta que o Dapr usará para se comunicar com a aplicação"
  type        = number
  default     = null
}

variable "dapr_app_protocol" {
  description = "Protocolo Dapr: http, grpc ou h2c"
  type        = string
  default     = "http"

  validation {
    condition     = var.dapr_app_protocol == null || contains(["http", "grpc", "h2c"], var.dapr_app_protocol)
    error_message = "dapr_app_protocol deve ser 'http', 'grpc' ou 'h2c'"
  }
}

# Dapr Components
variable "dapr_components" {
  description = "Componentes Dapr (state stores, pub/sub, bindings)"
  type = map(object({
    component_type = string
    version        = string
    ignore_errors  = optional(bool)
    init_timeout   = optional(string)
    scopes         = optional(list(string))
    metadata = optional(list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    })))
    secrets = optional(list(object({
      name  = string
      value = string
    })))
  }))
  default = {}
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
    error_message = "identity_type inválido"
  }
}

variable "identity_ids" {
  description = "IDs das User Assigned Identities"
  type        = list(string)
  default     = []
}

# Registry Configuration
variable "registries" {
  description = "Container registries para pull de imagens"
  type = list(object({
    server               = string
    username             = optional(string)
    password_secret_name = optional(string)
    identity             = optional(string) # Para usar Managed Identity com ACR
  }))
  default = []
}

# Environment Storage (para volumes persistentes)
variable "environment_storages" {
  description = "Storage Accounts para volumes persistentes"
  type = map(object({
    account_name = string
    access_key   = string
    share_name   = string
    access_mode  = string # ReadOnly or ReadWrite
  }))
  default   = {}
  sensitive = true
}

# Certificates
variable "certificates" {
  description = "Certificados para custom domains"
  type = map(object({
    certificate_blob_base64 = string
    certificate_password    = optional(string)
  }))
  default   = {}
  sensitive = true
}

# Tags
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}
