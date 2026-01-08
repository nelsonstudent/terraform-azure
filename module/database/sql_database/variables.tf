# Resource Group
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização do SQL Server"
  type        = string
}

# SQL Server Configuration
variable "sql_server_name" {
  description = "Nome do SQL Server (deve ser globalmente único)"
  type        = string
}

variable "sql_server_version" {
  description = "Versão do SQL Server: 2.0 ou 12.0"
  type        = string
  default     = "12.0"

  validation {
    condition     = contains(["2.0", "12.0"], var.sql_server_version)
    error_message = "sql_server_version deve ser '2.0' ou '12.0'"
  }
}

variable "administrator_login" {
  description = "Username do administrador do SQL Server"
  type        = string
}

variable "administrator_login_password" {
  description = "Password do administrador do SQL Server"
  type        = string
  sensitive   = true
}

variable "minimum_tls_version" {
  description = "Versão mínima do TLS: 1.0, 1.1, 1.2, Disabled"
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "Disabled"], var.minimum_tls_version)
    error_message = "minimum_tls_version deve ser '1.0', '1.1', '1.2' ou 'Disabled'"
  }
}

variable "public_network_access_enabled" {
  description = "Habilitar acesso público à internet"
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Habilitar restrição de rede de saída"
  type        = bool
  default     = false
}

# Azure AD Administrator
variable "azuread_administrator" {
  description = "Configuração do administrador Azure AD"
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool)
  })
  default = null
}

# Identity
variable "identity_type" {
  description = "Tipo de identidade: SystemAssigned ou UserAssigned"
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "identity_type deve ser 'SystemAssigned' ou 'UserAssigned'"
  }
}

variable "identity_ids" {
  description = "IDs das User Assigned Identities"
  type        = list(string)
  default     = []
}

# Database Configuration
variable "database_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "collation" {
  description = "Collation do banco de dados"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "license_type" {
  description = "Tipo de licença: LicenseIncluded ou BasePrice (Azure Hybrid Benefit)"
  type        = string
  default     = "LicenseIncluded"

  validation {
    condition     = contains(["LicenseIncluded", "BasePrice"], var.license_type)
    error_message = "license_type deve ser 'LicenseIncluded' ou 'BasePrice'"
  }
}

variable "max_size_gb" {
  description = "Tamanho máximo do banco em GB"
  type        = number
  default     = 32
}

variable "sku_name" {
  description = "SKU do banco: Basic, S0-S12, P1-P15, GP_S_Gen5_2, GP_Gen5_2, BC_Gen5_2, HS_Gen5_2"
  type        = string
  default     = "S0"
}

variable "zone_redundant" {
  description = "Habilitar zone redundancy (Premium/Business Critical)"
  type        = bool
  default     = false
}

variable "read_scale" {
  description = "Habilitar read scale-out (Premium/Business Critical)"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Número de réplicas de leitura (Hyperscale)"
  type        = number
  default     = 0
}

variable "auto_pause_delay_in_minutes" {
  description = "Delay para auto-pause em minutos (Serverless)"
  type        = number
  default     = null
}

variable "min_capacity" {
  description = "Capacidade mínima em vCores (Serverless)"
  type        = number
  default     = null
}

variable "storage_account_type" {
  description = "Tipo de storage: Geo, Local, Zone, GeoZone"
  type        = string
  default     = "Geo"

  validation {
    condition     = contains(["Geo", "Local", "Zone", "GeoZone"], var.storage_account_type)
    error_message = "storage_account_type deve ser 'Geo', 'Local', 'Zone' ou 'GeoZone'"
  }
}

variable "transparent_data_encryption_enabled" {
  description = "Habilitar Transparent Data Encryption (TDE)"
  type        = bool
  default     = true
}

variable "ledger_enabled" {
  description = "Habilitar ledger (blockchain-style)"
  type        = bool
  default     = false
}

variable "maintenance_configuration_name" {
  description = "Nome da configuração de manutenção"
  type        = string
  default     = null
}

variable "elastic_pool_id" {
  description = "ID do Elastic Pool"
  type        = string
  default     = null
}

variable "geo_backup_enabled" {
  description = "Habilitar geo-backup"
  type        = bool
  default     = true
}

# Database Creation Mode
variable "create_mode" {
  description = "Modo de criação: Default, Copy, Secondary, PointInTimeRestore, Restore, Recovery, RestoreExternalBackup"
  type        = string
  default     = "Default"
}

variable "creation_source_database_id" {
  description = "ID do banco de dados source (para Copy/Secondary)"
  type        = string
  default     = null
}

variable "restore_point_in_time" {
  description = "Ponto no tempo para restore"
  type        = string
  default     = null
}

variable "recover_database_id" {
  description = "ID do banco para recovery"
  type        = string
  default     = null
}

variable "restore_dropped_database_id" {
  description = "ID do banco deletado para restore"
  type        = string
  default     = null
}

# Threat Detection Policy
variable "threat_detection_policy" {
  description = "Política de detecção de ameaças"
  type = object({
    state                      = string
    disabled_alerts            = optional(list(string))
    email_account_admins       = optional(bool)
    email_addresses            = optional(list(string))
    retention_days             = optional(number)
    storage_account_access_key = optional(string)
    storage_endpoint           = optional(string)
  })
  default   = null
  sensitive = true
}

# Retention Policies
variable "short_term_retention_policy" {
  description = "Política de retenção de curto prazo"
  type = object({
    retention_days           = number
    backup_interval_in_hours = optional(number)
  })
  default = null
}

variable "long_term_retention_policy" {
  description = "Política de retenção de longo prazo"
  type = object({
    weekly_retention  = optional(string)
    monthly_retention = optional(string)
    yearly_retention  = optional(string)
    week_of_year      = optional(number)
  })
  default = null
}

# Firewall Rules
variable "firewall_rules" {
  description = "Regras de firewall do SQL Server"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

# Virtual Network Rules
variable "virtual_network_rules" {
  description = "Regras de Virtual Network"
  type = map(object({
    subnet_id = string
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

variable "private_dns_zone_ids" {
  description = "IDs das Private DNS Zones"
  type        = list(string)
  default     = null
}

# Auditing
variable "enable_auditing" {
  description = "Habilitar auditing"
  type        = bool
  default     = false
}

variable "auditing_storage_endpoint" {
  description = "Endpoint da Storage Account para auditing"
  type        = string
  default     = null
}

variable "auditing_storage_account_access_key" {
  description = "Access key da Storage Account para auditing"
  type        = string
  default     = null
  sensitive   = true
}

variable "auditing_retention_days" {
  description = "Dias de retenção dos logs de audit"
  type        = number
  default     = 90
}

variable "auditing_log_analytics_enabled" {
  description = "Enviar logs de audit para Log Analytics"
  type        = bool
  default     = true
}

# Microsoft Defender for SQL
variable "enable_threat_detection" {
  description = "Habilitar Microsoft Defender for SQL"
  type        = bool
  default     = false
}

variable "threat_detection_storage_endpoint" {
  description = "Endpoint da Storage Account para threat detection"
  type        = string
  default     = null
}

variable "threat_detection_storage_account_access_key" {
  description = "Access key da Storage Account para threat detection"
  type        = string
  default     = null
  sensitive   = true
}

variable "threat_detection_disabled_alerts" {
  description = "Alertas desabilitados"
  type        = list(string)
  default     = []
}

variable "threat_detection_retention_days" {
  description = "Dias de retenção"
  type        = number
  default     = 90
}

variable "threat_detection_email_account_admins" {
  description = "Enviar email para admins da subscription"
  type        = bool
  default     = true
}

variable "threat_detection_email_addresses" {
  description = "Lista de emails para alertas"
  type        = list(string)
  default     = []
}

# Vulnerability Assessment
variable "enable_vulnerability_assessment" {
  description = "Habilitar Vulnerability Assessment"
  type        = bool
  default     = false
}

variable "vulnerability_assessment_storage_container_path" {
  description = "Path do container para vulnerability assessment"
  type        = string
  default     = null
}

variable "vulnerability_assessment_storage_account_access_key" {
  description = "Access key para vulnerability assessment"
  type        = string
  default     = null
  sensitive   = true
}

variable "vulnerability_assessment_recurring_scans" {
  description = "Configuração de scans recorrentes"
  type = object({
    enabled                   = bool
    email_subscription_admins = optional(bool)
    emails                    = optional(list(string))
  })
  default = null
}

# Failover Group
variable "create_failover_group" {
  description = "Criar Failover Group"
  type        = bool
  default     = false
}

variable "failover_group_name" {
  description = "Nome do Failover Group"
  type        = string
  default     = null
}

variable "failover_group_partner_server_id" {
  description = "ID do servidor parceiro para failover"
  type        = string
  default     = null
}

variable "failover_group_read_write_endpoint_mode" {
  description = "Modo do endpoint read-write: Automatic ou Manual"
  type        = string
  default     = "Automatic"

  validation {
    condition     = contains(["Automatic", "Manual"], var.failover_group_read_write_endpoint_mode)
    error_message = "failover_group_read_write_endpoint_mode deve ser 'Automatic' ou 'Manual'"
  }
}

variable "failover_group_grace_minutes" {
  description = "Grace period em minutos para failover automático"
  type        = number
  default     = 60
}

variable "read_only_endpoint_failover_policy_enabled" {
  description = "Habilitar endpoint read-only"
  type        = bool
  default     = false
}

# Elastic Pool
variable "create_elastic_pool" {
  description = "Criar Elastic Pool"
  type        = bool
  default     = false
}

variable "elastic_pool_name" {
  description = "Nome do Elastic Pool"
  type        = string
  default     = null
}

variable "elastic_pool_max_size_gb" {
  description = "Tamanho máximo do Elastic Pool em GB"
  type        = number
  default     = 50
}

variable "elastic_pool_zone_redundant" {
  description = "Habilitar zone redundancy no Elastic Pool"
  type        = bool
  default     = false
}

variable "elastic_pool_license_type" {
  description = "Tipo de licença do Elastic Pool"
  type        = string
  default     = "LicenseIncluded"
}

variable "elastic_pool_sku_name" {
  description = "Nome do SKU do Elastic Pool"
  type        = string
  default     = "BasicPool"
}

variable "elastic_pool_sku_tier" {
  description = "Tier do SKU do Elastic Pool"
  type        = string
  default     = "Basic"
}

variable "elastic_pool_sku_capacity" {
  description = "Capacidade do SKU do Elastic Pool"
  type        = number
  default     = 50
}

variable "elastic_pool_sku" {
  description = "Configuração completa do SKU"
  type        = map(string)
  default     = {}
}

variable "elastic_pool_min_capacity" {
  description = "Capacidade mínima por database no Elastic Pool"
  type        = number
  default     = 0
}

variable "elastic_pool_max_capacity" {
  description = "Capacidade máxima por database no Elastic Pool"
  type        = number
  default     = 5
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
  description = "Categorias de logs para enviar ao Log Analytics"
  type        = list(string)
  default = [
    "SQLInsights",
    "AutomaticTuning",
    "QueryStoreRuntimeStatistics",
    "QueryStoreWaitStatistics",
    "Errors",
    "DatabaseWaitStatistics",
    "Timeouts",
    "Blocks",
    "Deadlocks"
  ]
}

variable "diagnostic_metrics" {
  description = "Métricas para enviar ao Log Analytics"
  type        = list(string)
  default = [
    "Basic",
    "InstanceAndAppAdvanced",
    "WorkloadManagement"
  ]
}

# Tags
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}