# Project Configuration
variable "project_name" {
  description = "Nome do projeto no Azure DevOps"
  type        = string
}

variable "project_description" {
  description = "Descrição do projeto"
  type        = string
  default     = ""
}

variable "project_visibility" {
  description = "Visibilidade do projeto: private ou public"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public"], var.project_visibility)
    error_message = "project_visibility deve ser 'private' ou 'public'"
  }
}

variable "version_control" {
  description = "Sistema de controle de versão: Git ou Tfvc"
  type        = string
  default     = "Git"

  validation {
    condition     = contains(["Git", "Tfvc"], var.version_control)
    error_message = "version_control deve ser 'Git' ou 'Tfvc'"
  }
}

variable "work_item_template" {
  description = "Template de work items: Agile, Basic, Scrum ou CMMI"
  type        = string
  default     = "Agile"

  validation {
    condition     = contains(["Agile", "Basic", "Scrum", "CMMI"], var.work_item_template)
    error_message = "work_item_template deve ser 'Agile', 'Basic', 'Scrum' ou 'CMMI'"
  }
}

# Project Features
variable "enable_boards" {
  description = "Habilitar Azure Boards"
  type        = bool
  default     = true
}

variable "enable_repos" {
  description = "Habilitar Azure Repos"
  type        = bool
  default     = true
}

variable "enable_pipelines" {
  description = "Habilitar Azure Pipelines"
  type        = bool
  default     = true
}

variable "enable_test_plans" {
  description = "Habilitar Azure Test Plans"
  type        = bool
  default     = false
}

variable "enable_artifacts" {
  description = "Habilitar Azure Artifacts"
  type        = bool
  default     = true
}

# Repositories
variable "repositories" {
  description = "Mapa de repositórios Git a serem criados"
  type = map(object({
    default_branch = string
    init_type      = string # Clean, Import, Uninitialized
  }))
  default = {}
}

# Service Connection
variable "create_service_connection" {
  description = "Criar service connection para Azure Resource Manager"
  type        = bool
  default     = false
}

variable "service_connection_name" {
  description = "Nome da service connection"
  type        = string
  default     = ""
}

variable "service_connection_description" {
  description = "Descrição da service connection"
  type        = string
  default     = ""
}

variable "service_principal_id" {
  description = "ID do Service Principal para autenticação"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tenant_id" {
  description = "Tenant ID do Azure AD"
  type        = string
  default     = ""
}

variable "subscription_id" {
  description = "Subscription ID do Azure"
  type        = string
  default     = ""
}

variable "subscription_name" {
  description = "Nome da Subscription do Azure"
  type        = string
  default     = ""
}

# Pipelines
variable "pipelines" {
  description = "Mapa de pipelines a serem criados"
  type = map(object({
    repository_name = string
    branch_name     = string
    yaml_path       = string
    variables       = map(string)
  }))
  default = {}
}

# Variable Groups
variable "variable_groups" {
  description = "Mapa de variable groups a serem criados"
  type = map(object({
    description    = string
    allow_access   = bool
    variables      = map(string)
    key_vault_name = optional(string)
  }))
  default = {}
}

# Branch Policies
variable "branch_policies" {
  description = "Políticas de branch para pull requests"
  type = map(object({
    repository_name                = string
    branch_name                    = string
    minimum_reviewers              = number
    blocking                       = bool
    submitter_can_vote             = bool
    last_pusher_cannot_approve     = bool
    allow_completion_with_rejects  = bool
    reset_votes_on_push            = bool
  }))
  default = {}
}

# Build Validation Policies
variable "build_validation_policies" {
  description = "Políticas de validação de build em branches"
  type = map(object({
    repository_name   = string
    branch_name       = string
    pipeline_name     = string
    display_name      = string
    blocking          = bool
    valid_duration    = number
    filename_patterns = list(string)
  }))
  default = {}
}

# Environments
variable "environments" {
  description = "Ambientes para deployment"
  type = map(object({
    description = string
  }))
  default = {}
}

# Teams
variable "teams" {
  description = "Times dentro do projeto"
  type = map(object({
    description    = string
    administrators = list(string)
    members        = list(string)
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags para organização e billing"
  type        = map(string)
  default     = {}
}
