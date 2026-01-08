# SQL Server Outputs
output "sql_server_id" {
  description = "ID do SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "sql_server_name" {
  description = "Nome do SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "FQDN do SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_server_version" {
  description = "Versão do SQL Server"
  value       = azurerm_mssql_server.main.version
}

output "sql_server_administrator_login" {
  description = "Username do administrador"
  value       = azurerm_mssql_server.main.administrator_login
}

# SQL Server Identity
output "sql_server_identity_principal_id" {
  description = "Principal ID da Managed Identity do SQL Server"
  value       = var.identity_type != null ? azurerm_mssql_server.main.identity[0].principal_id : null
}

output "sql_server_identity_tenant_id" {
  description = "Tenant ID da Managed Identity"
  value       = var.identity_type != null ? azurerm_mssql_server.main.identity[0].tenant_id : null
}

# Database Outputs
output "database_id" {
  description = "ID do banco de dados"
  value       = azurerm_mssql_database.main.id
}

output "database_name" {
  description = "Nome do banco de dados"
  value       = azurerm_mssql_database.main.name
}

output "database_collation" {
  description = "Collation do banco de dados"
  value       = azurerm_mssql_database.main.collation
}

output "database_max_size_gb" {
  description = "Tamanho máximo do banco em GB"
  value       = azurerm_mssql_database.main.max_size_gb
}

output "database_sku_name" {
  description = "SKU do banco de dados"
  value       = azurerm_mssql_database.main.sku_name
}

# Connection Strings
output "connection_string" {
  description = "Connection string do banco de dados"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

output "connection_string_adonet" {
  description = "Connection string ADO.NET"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

output "connection_string_jdbc" {
  description = "Connection string JDBC"
  value       = "jdbc:sqlserver://${azurerm_mssql_server.main.fully_qualified_domain_name}:1433;database=${azurerm_mssql_database.main.name};user=${azurerm_mssql_server.main.administrator_login}@${azurerm_mssql_server.main.name};password={your_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
  sensitive   = true
}

output "connection_string_odbc" {
  description = "Connection string ODBC"
  value       = "Driver={ODBC Driver 17 for SQL Server};Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};Uid=${azurerm_mssql_server.main.administrator_login};Pwd={your_password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  sensitive   = true
}

output "connection_string_php" {
  description = "Connection string PHP PDO"
  value       = "Server: ${azurerm_mssql_server.main.fully_qualified_domain_name},1433 \\r\\nSQL Database: ${azurerm_mssql_database.main.name}\\r\\nUser Name: ${azurerm_mssql_server.main.administrator_login}"
  sensitive   = true
}

# Private Endpoint
output "private_endpoint_id" {
  description = "ID do Private Endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip_address" {
  description = "IP privado do Private Endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

# Firewall Rules
output "firewall_rule_ids" {
  description = "IDs das regras de firewall"
  value       = { for k, v in azurerm_mssql_firewall_rule.main : k => v.id }
}

# Virtual Network Rules
output "virtual_network_rule_ids" {
  description = "IDs das regras de Virtual Network"
  value       = { for k, v in azurerm_mssql_virtual_network_rule.main : k => v.id }
}

# Failover Group
output "failover_group_id" {
  description = "ID do Failover Group"
  value       = var.create_failover_group ? azurerm_mssql_failover_group.main[0].id : null
}

output "failover_group_name" {
  description = "Nome do Failover Group"
  value       = var.create_failover_group ? azurerm_mssql_failover_group.main[0].name : null
}

# Elastic Pool
output "elastic_pool_id" {
  description = "ID do Elastic Pool"
  value       = var.create_elastic_pool ? azurerm_mssql_elasticpool.main[0].id : null
}

output "elastic_pool_name" {
  description = "Nome do Elastic Pool"
  value       = var.create_elastic_pool ? azurerm_mssql_elasticpool.main[0].name : null
}

# Complete SQL Server Info
output "sql_server_info" {
  description = "Informações completas do SQL Server"
  value = {
    id                          = azurerm_mssql_server.main.id
    name                        = azurerm_mssql_server.main.name
    fqdn                        = azurerm_mssql_server.main.fully_qualified_domain_name
    version                     = azurerm_mssql_server.main.version
    location                    = var.location
    resource_group              = var.resource_group_name
    administrator_login         = azurerm_mssql_server.main.administrator_login
    public_network_access       = var.public_network_access_enabled
    minimum_tls_version         = var.minimum_tls_version
    identity_enabled            = var.identity_type != null
    private_endpoint_enabled    = var.enable_private_endpoint
    auditing_enabled            = var.enable_auditing
    threat_detection_enabled    = var.enable_threat_detection
    vulnerability_assessment_enabled = var.enable_vulnerability_assessment
  }
}

# Complete Database Info
output "database_info" {
  description = "Informações completas do banco de dados"
  value = {
    id                    = azurerm_mssql_database.main.id
    name                  = azurerm_mssql_database.main.name
    server_name           = azurerm_mssql_server.main.name
    collation             = azurerm_mssql_database.main.collation
    max_size_gb           = azurerm_mssql_database.main.max_size_gb
    sku_name              = azurerm_mssql_database.main.sku_name
    zone_redundant        = var.zone_redundant
    read_scale            = var.read_scale
    geo_backup_enabled    = var.geo_backup_enabled
    transparent_data_encryption = var.transparent_data_encryption_enabled
    elastic_pool_id       = var.elastic_pool_id
  }
}

# Query Editor URL
output "query_editor_url" {
  description = "URL do Query Editor no Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_mssql_database.main.id}/query"
}

# Connection Info for Applications
output "connection_info" {
  description = "Informações de conexão para aplicações"
  value = {
    server   = azurerm_mssql_server.main.fully_qualified_domain_name
    database = azurerm_mssql_database.main.name
    port     = 1433
    username = azurerm_mssql_server.main.administrator_login
  }
  sensitive = true
}