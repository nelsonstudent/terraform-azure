variable "name" {
  description = "Nome da Storage Account (deve ser único globalmente, apenas letras minúsculas e números)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "O nome deve conter apenas letras minúsculas e números, com 3 a 24 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde a Storage Account será criada"
  type        = string
}

variable "location" {
  description = "Localização do Azure onde a Storage Account será criada"
  type        = string
}

variable "account_tier" {
  description = "Tier da Storage Account (Standard ou Premium)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "O account_tier deve ser 'Standard' ou 'Premium'."
  }
}

variable "account_replication_type" {
  description = "Tipo de replicação (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
  
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "O tipo de replicação deve ser um dos seguintes: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "account_kind" {
  description = "Tipo da Storage Account (BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2)"
  type        = string
  default     = "StorageV2"
  
  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "O account_kind deve ser um dos seguintes: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "access_tier" {
  description = "Access tier para BlobStorage e StorageV2 (Hot ou Cool)"
  type        = string
  default     = "Hot"
  
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "O access_tier deve ser 'Hot' ou 'Cool'."
  }
}

variable "enable_https_traffic_only" {
  description = "Habilitar apenas tráfego HTTPS"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Versão mínima do TLS (TLS1_0, TLS1_1, TLS1_2)"
  type        = string
  default     = "TLS1_2"
  
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "A versão do TLS deve ser TLS1_0, TLS1_1 ou TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Permitir que itens aninhados sejam públicos"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Habilitar acesso via chave compartilhada"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso à rede pública"
  type        = bool
  default     = true
}

variable "default_to_oauth_authentication" {
  description = "Usar autenticação OAuth por padrão"
  type        = bool
  default     = false
}

variable "is_hns_enabled" {
  description = "Habilitar Hierarchical Namespace (Data Lake Gen2)"
  type        = bool
  default     = false
}

variable "nfsv3_enabled" {
  description = "Habilitar NFSv3"
  type        = bool
  default     = false
}

variable "large_file_share_enabled" {
  description = "Habilitar Large File Share"
  type        = bool
  default     = false
}

variable "network_rules" {
  description = "Regras de rede para a Storage Account"
  type = object({
    default_action             = string
    bypass                     = list(string)
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

variable "blob_properties" {
  description = "Propriedades de blob (versionamento, soft delete, etc)"
  type = object({
    versioning_enabled       = bool
    change_feed_enabled      = bool
    last_access_time_enabled = bool
    delete_retention_days    = number
    container_delete_retention_days = number
  })
  default = {
    versioning_enabled       = false
    change_feed_enabled      = false
    last_access_time_enabled = false
    delete_retention_days    = 7
    container_delete_retention_days = 7
  }
}

variable "containers" {
  description = "Lista de containers a serem criados"
  type = list(object({
    name                  = string
    container_access_type = string
  }))
  default = []
}

variable "file_shares" {
  description = "Lista de file shares a serem criados"
  type = list(object({
    name   = string
    quota  = number
  }))
  default = []
}

variable "queues" {
  description = "Lista de queues a serem criadas"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "Lista de tables a serem criadas"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

variable "identity_type" {
  description = "Tipo de identidade gerenciada (SystemAssigned, UserAssigned ou ambos)"
  type        = string
  default     = null
  
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "O identity_type deve ser 'SystemAssigned', 'UserAssigned' ou 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "Lista de IDs de identidades gerenciadas atribuídas pelo usuário"
  type        = list(string)
  default     = []
}