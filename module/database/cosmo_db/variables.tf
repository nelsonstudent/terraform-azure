# Resource Group
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização primária do Cosmos DB"
  type        = string
}

# Cosmos DB Account
variable "cosmosdb_account_name" {
  description = "Nome da conta Cosmos DB (deve ser globalmente único)"
  type        = string
}

variable "offer_type" {
  description = "Offer type: Standard"
  type        = string
  default     = "Standard"
}

variable "kind" {
  description = "Kind da conta: GlobalDocumentDB, MongoDB, Parse"
  type        = string
  default     = "GlobalDocumentDB"

  validation {
    condition     = contains(["GlobalDocumentDB", "MongoDB", "Parse"], var.kind)
    error_message = "kind deve ser 'GlobalDocumentDB', 'MongoDB' ou 'Parse'"
  }
}

variable "enable_automatic_failover" {
  description = "Habilitar failover automático"
  type        = bool
  default     = true
}

variable "enable_multiple_write_locations" {
  description = "Habilitar múltiplas regiões de escrita"
  type        = bool
  default     = false
}

variable "is_virtual_network_filter_enabled" {
  description = "Habilitar filtro de Virtual Network"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso público"
  type        = bool
  default     = true
}

variable "enable_free_tier" {
  description = "Habilitar free tier (400 RU/s + 5 GB)"
  type        = bool
  default     = false
}

variable "analytical_storage_enabled" {
  description = "Habilitar analytical storage (Synapse Link)"
  type        = bool
  default     = false
}

variable "analytical_storage_schema_type" {
  description = "Schema type para analytical storage: WellDefined ou FullFidelity"
  type        = string
  default     = "WellDefined"
}

variable "access_key_metadata_writes_enabled" {
  description = "Permitir writes de metadata com access key"
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Desabilitar autenticação local (força Azure AD)"
  type        = bool
  default     = false
}

variable "network_acl_bypass_for_azure_services" {
  description = "Bypass de ACL para serviços Azure"
  type        = bool
  default     = false
}

variable "network_acl_bypass_ids" {
  description = "IDs de recursos para bypass de ACL"
  type        = list(string)
  default     = []
}

variable "default_identity_type" {
  description = "Identity type padrão para data plane: FirstPartyIdentity, SystemAssignedIdentity, UserAssignedIdentity"
  type        = string
  default     = null
}

# Consistency Policy
variable "consistency_policy" {
  description = "Política de consistência"
  type = object({
    consistency_level       = string
    max_interval_in_seconds = optional(number)
    max_staleness_prefix    = optional(number)
  })
  default = {
    consistency_level = "Session"
  }

  validation {
    condition     = contains(["BoundedStaleness", "ConsistentPrefix", "Eventual", "Session", "Strong"], var.consistency_policy.consistency_level)
    error_message = "consistency_level inválido"
  }
}

# Geo Locations
variable "geo_locations" {
  description = "Localizações geográficas para replicação"
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool)
  }))
}

# Capabilities
variable "capabilities" {
  description = "Capabilities (EnableServerless, EnableCassandra, EnableGremlin, EnableTable, EnableMongo, etc)"
  type        = list(string)
  default     = []
}

# Virtual Network Rules
variable "virtual_network_rules" {
  description = "Regras de Virtual Network"
  type = list(object({
    id                                   = string
    ignore_missing_vnet_service_endpoint = optional(bool)
  }))
  default = []
}

# IP Range Filter
variable "ip_range_filter" {
  description = "IPs ou CIDRs permitidos (separados por vírgula)"
  type        = string
  default     = ""
}

# Backup Policy
variable "backup_policy" {
  description = "Política de backup"
  type = object({
    type                = string
    interval_in_minutes = optional(number)
    retention_in_hours  = optional(number)
    storage_redundancy  = optional(string)
  })
  default = null
}

# CORS Rules
variable "cors_rules" {
  description = "Regras CORS"
  type = list(object({
    allowed_origins    = list(string)
    allowed_methods    = list(string)
    allowed_headers    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

# Identity
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

# Capacity
variable "capacity_total_throughput_limit" {
  description = "Limite total de throughput (RU/s) para a conta"
  type        = number
  default     = null
}

# SQL API (Core API)
variable "sql_databases" {
  description = "SQL Databases (Core API)"
  type = map(object({
    throughput              = optional(number)
    autoscale_max_throughput = optional(number)
  }))
  default = {}
}

variable "sql_containers" {
  description = "SQL Containers"
  type = map(object({
    database_name          = string
    partition_key_path     = string
    partition_key_version  = optional(number)
    throughput             = optional(number)
    autoscale_max_throughput = optional(number)
    default_ttl            = optional(number)
    analytical_storage_ttl = optional(number)
    indexing_policy = optional(object({
      indexing_mode     = optional(string)
      included_paths    = optional(list(string))
      excluded_paths    = optional(list(string))
      composite_indexes = optional(list(list(object({
        path  = string
        order = string
      }))))
      spatial_indexes = optional(list(string))
    }))
    unique_keys = optional(list(object({
      paths = list(string)
    })))
    conflict_resolution_policy = optional(object({
      mode                          = string
      conflict_resolution_path      = optional(string)
      conflict_resolution_procedure = optional(string)
    }))
  }))
  default = {}
}

# MongoDB API
variable "mongo_databases" {
  description = "MongoDB Databases"
  type = map(object({
    throughput              = optional(number)
    autoscale_max_throughput = optional(number)
  }))
  default = {}
}

variable "mongo_collections" {
  description = "MongoDB Collections"
  type = map(object({
    database_name           = string
    shard_key               = optional(string)
    throughput              = optional(number)
    autoscale_max_throughput = optional(number)
    default_ttl_seconds     = optional(number)
    analytical_storage_ttl  = optional(number)
    indexes = optional(list(object({
      keys   = list(string)
      unique = optional(bool)
    })))
  }))
  default = {}
}

# Cassandra API
variable "cassandra_keyspaces" {
  description = "Cassandra Keyspaces"
  type = map(object({
    throughput              = optional(number)
    autoscale_max_throughput = optional(number)
  }))
  default = {}
}

variable "cassandra_tables" {
  description = "Cassandra Tables"
  type = map(object({
    keyspace_name           = string
    throughput              = optional(number)
    autoscale_max_throughput = optional(number)
    default_ttl             = optional(number)
    analytical_storage_ttl  = optional(number)
    schema = object({
      columns = list(object({
        name = string
        type = string
      }))
      partition_keys = list(string)
      cluster_keys = optional(list(object({
        name     = string
        order_by = string
      })))
    })
  }))
  default = {}
}

# Gremlin API (Graph)
variable "gremlin_databases" {
  description = "Gremlin Databases"
  type = map(object({
    throughput              = optional(number)
    autoscale_max_throughput = optional(number)
  }))
  default = {}
}

variable "gremlin_graphs" {
  description = "Gremlin Graphs"
  type = map(object({
    database_name          = string
    partition_key_path     = string
    throughput             = optional(number)
    autoscale_max_throughput = optional(number)
    default_ttl            = optional(number)
    indexing_policy = optional(object({
      indexing_mode  = optional(string)
      automatic      = optional(bool)
      included_paths = optional(list(string))
      excluded_paths = optional(list(string))
    }))
    unique_keys = optional(list(object({
      paths = list(string)
    })))
    conflict_resolution_policy = optional(object({
      mode                          = string
      conflict_resolution_path      = optional(string)
      conflict_resolution_procedure = optional(string)
    }))
  }))
  default = {}
}

# Table API (Key-Value)
variable "tables" {
  description = "Tables (Table API)"
  type = map(object({
    throughput              = optional(number)
    autoscale_max_throughput = optional(number)
  }))
  default = {}
}

# Private Endpoint
variable "enable_private_endpoint" {
  description = "Criar Private Endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_name" {
  description = "Nome do Private Endpoint"
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  description = "ID da subnet para o Private Endpoint"
  type        = string
  default     = null
}

variable "private_endpoint_subresource_name" {
  description = "Subresource name: Sql, MongoDB, Cassandra, Gremlin, Table"
  type        = string
  default     = "Sql"

  validation {
    condition     = contains(["Sql", "MongoDB", "Cassandra", "Gremlin", "Table"], var.private_endpoint_subresource_name)
    error_message = "private_endpoint_subresource_name inválido"
  }
}

variable "private_dns_zone_ids" {
  description = "IDs das Private DNS Zones"
  type        = list(string)
  default     = null
}

# Diagnostic Settings
variable "enable_diagnostic_settings" {
  description = "Habilitar Diagnostic Settings"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  type        = string
  default     = null
}

variable "diagnostic_logs" {
  description = "Categorias de logs"
  type        = list(string)
  default = [
    "DataPlaneRequests",
    "MongoRequests",
    "QueryRuntimeStatistics",
    "PartitionKeyStatistics",
    "PartitionKeyRUConsumption",
    "ControlPlaneRequests",
    "CassandraRequests",
    "GremlinRequests",
    "TableApiRequests"
  ]
}

variable "diagnostic_metrics" {
  description = "Métricas"
  type        = list(string)
  default = [
    "Requests"
  ]
}

# Tags
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}
