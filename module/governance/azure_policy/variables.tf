variable "policy_type" {
  description = "Tipo de policy a criar: 'definition', 'set_definition' (initiative), 'assignment' ou 'exemption'"
  type        = string
  default     = "definition"

  validation {
    condition     = contains(["definition", "set_definition", "assignment", "exemption"], var.policy_type)
    error_message = "O policy_type deve ser: 'definition', 'set_definition', 'assignment' ou 'exemption'."
  }
}

# Policy Definition Variables
variable "name" {
  description = "Nome da policy definition, assignment ou exemption"
  type        = string
}

variable "display_name" {
  description = "Nome de exibição"
  type        = string
  default     = null
}

variable "description" {
  description = "Descrição da policy"
  type        = string
  default     = null
}

variable "mode" {
  description = "Modo da policy (All, Indexed, Microsoft.KeyVault.Data, etc)"
  type        = string
  default     = "All"

  validation {
    condition = contains([
      "All",
      "Indexed",
      "Microsoft.KeyVault.Data",
      "Microsoft.Kubernetes.Data",
      "Microsoft.Network.Data",
      "Microsoft.ContainerService.Data"
    ], var.mode)
    error_message = "Modo inválido. Use: All, Indexed, ou um dos modos específicos de resource provider."
  }
}

variable "policy_rule" {
  description = "Regra da policy em formato JSON (string ou objeto)"
  type        = any
  default     = null
}

variable "parameters" {
  description = "Parâmetros da policy definition em formato JSON"
  type        = string
  default     = null
}

variable "metadata" {
  description = "Metadata da policy em formato JSON"
  type        = string
  default     = null
}

variable "management_group_id" {
  description = "ID do Management Group para criar a policy definition (se null, usa subscription)"
  type        = string
  default     = null
}

# Policy Set Definition (Initiative) Variables
variable "policy_definitions" {
  description = "Lista de policy definitions para incluir na initiative"
  type = list(object({
    policy_definition_id = string
    parameter_values     = optional(string)
    reference_id         = optional(string)
    policy_group_names   = optional(list(string))
  }))
  default = []
}

variable "policy_definition_groups" {
  description = "Grupos para organizar policies dentro de uma initiative"
  type = list(object({
    name                            = string
    display_name                    = optional(string)
    category                        = optional(string)
    description                     = optional(string)
    additional_metadata_resource_id = optional(string)
  }))
  default = []
}

# Policy Assignment Variables
variable "scope" {
  description = "Escopo para policy assignment (subscription, resource group, management group)"
  type        = string
  default     = null
}

variable "policy_definition_id" {
  description = "ID da policy definition ou initiative para atribuir"
  type        = string
  default     = null
}

variable "enforce" {
  description = "Se a policy deve ser enforced (true) ou apenas audit (false)"
  type        = bool
  default     = true
}

variable "location" {
  description = "Localização para managed identity (quando needed)"
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Tipo de identity (SystemAssigned ou UserAssigned)"
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "O identity_type deve ser 'SystemAssigned' ou 'UserAssigned'."
  }
}

variable "identity_ids" {
  description = "IDs das user-assigned identities (quando identity_type = UserAssigned)"
  type        = list(string)
  default     = null
}

variable "not_scopes" {
  description = "Lista de escopos a excluir da policy assignment"
  type        = list(string)
  default     = []
}

variable "non_compliance_messages" {
  description = "Mensagens de não conformidade customizadas"
  type = list(object({
    message                        = string
    policy_definition_reference_id = optional(string)
  }))
  default = []
}

variable "overrides" {
  description = "Overrides para policy assignment"
  type = list(object({
    value = string
    selectors = optional(list(object({
      kind   = string
      in     = optional(list(string))
      not_in = optional(list(string))
    })))
  }))
  default = []
}

variable "resource_selectors" {
  description = "Resource selectors para filtrar recursos"
  type = list(object({
    name = string
    selectors = list(object({
      kind   = string
      in     = optional(list(string))
      not_in = optional(list(string))
    }))
  }))
  default = []
}

# Policy Exemption Variables
variable "policy_assignment_id" {
  description = "ID do policy assignment para criar exemption"
  type        = string
  default     = null
}

variable "exemption_category" {
  description = "Categoria da exemption (Waiver ou Mitigated)"
  type        = string
  default     = "Waiver"

  validation {
    condition     = var.exemption_category == null || contains(["Waiver", "Mitigated"], var.exemption_category)
    error_message = "O exemption_category deve ser 'Waiver' ou 'Mitigated'."
  }
}

variable "expires_on" {
  description = "Data de expiração da exemption (formato: YYYY-MM-DDTHH:MM:SSZ)"
  type        = string
  default     = null
}

variable "policy_definition_reference_ids" {
  description = "IDs de referência de policies específicas para exemption (para initiatives)"
  type        = list(string)
  default     = null
}

variable "metadata_exemption" {
  description = "Metadata para exemption"
  type        = string
  default     = null
}

# Remediation Variables
variable "create_remediation_task" {
  description = "Criar remediation task para policy assignment"
  type        = bool
  default     = false
}

variable "remediation_scope" {
  description = "Escopo para remediation task"
  type        = string
  default     = null
}

variable "resource_discovery_mode" {
  description = "Modo de descoberta de recursos (ExistingNonCompliant ou ReEvaluateCompliance)"
  type        = string
  default     = "ExistingNonCompliant"

  validation {
    condition     = contains(["ExistingNonCompliant", "ReEvaluateCompliance"], var.resource_discovery_mode)
    error_message = "O resource_discovery_mode deve ser 'ExistingNonCompliant' ou 'ReEvaluateCompliance'."
  }
}

variable "failure_percentage" {
  description = "Percentual de falha aceitável para remediation"
  type        = number
  default     = null

  validation {
    condition     = var.failure_percentage == null || (var.failure_percentage >= 0 && var.failure_percentage <= 100)
    error_message = "O failure_percentage deve estar entre 0 e 100."
  }
}

variable "parallel_deployments" {
  description = "Número de deployments paralelos para remediation"
  type        = number
  default     = null
}

variable "resource_count" {
  description = "Número máximo de recursos para remediar"
  type        = number
  default     = null
}

# Common Variables
variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}