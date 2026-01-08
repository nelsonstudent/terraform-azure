# Cosmos DB Account Outputs
output "cosmosdb_account_id" {
  description = "ID da conta Cosmos DB"
  value       = azurerm_cosmosdb_account.main.id
}

output "cosmosdb_account_name" {
  description = "Nome da conta Cosmos DB"
  value       = azurerm_cosmosdb_account.main.name
}

output "cosmosdb_account_endpoint" {
  description = "Endpoint da conta Cosmos DB"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_account_primary_key" {
  description = "Primary master key"
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "cosmosdb_account_secondary_key" {
  description = "Secondary master key"
  value       = azurerm_cosmosdb_account.main.secondary_key
  sensitive   = true
}

output "cosmosdb_account_primary_readonly_key" {
  description = "Primary readonly master key"
  value       = azurerm_cosmosdb_account.main.primary_readonly_key
  sensitive   = true
}

output "cosmosdb_account_secondary_readonly_key" {
  description = "Secondary readonly master key"
  value       = azurerm_cosmosdb_account.main.secondary_readonly_key
  sensitive   = true
}

output "cosmosdb_account_secondary_sql_connection_string" {
  description = "Secondary SQL connection string"
  value       = azurerm_cosmosdb_account.main.secondary_sql_connection_string
  sensitive   = true
}

output "cosmosdb_account_primary_readonly_sql_connection_string" {
  description = "Primary readonly SQL connection string"
  value       = azurerm_cosmosdb_account.main.primary_readonly_sql_connection_string
  sensitive   = true
}

output "cosmosdb_account_secondary_readonly_sql_connection_string" {
  description = "Secondary readonly SQL connection string"
  value       = azurerm_cosmosdb_account.main.secondary_readonly_sql_connection_string
  sensitive   = true
}

output "cosmosdb_account_primary_mongodb_connection_string" {
  description = "Primary MongoDB connection string"
  value       = azurerm_cosmosdb_account.main.primary_mongodb_connection_string
  sensitive   = true
}

output "cosmosdb_account_secondary_mongodb_connection_string" {
  description = "Secondary MongoDB connection string"
  value       = azurerm_cosmosdb_account.main.secondary_mongodb_connection_string
  sensitive   = true
}

output "cosmosdb_account_primary_readonly_mongodb_connection_string" {
  description = "Primary readonly MongoDB connection string"
  value       = azurerm_cosmosdb_account.main.primary_readonly_mongodb_connection_string
  sensitive   = true
}

output "cosmosdb_account_secondary_readonly_mongodb_connection_string" {
  description = "Secondary readonly MongoDB connection string"
  value       = azurerm_cosmosdb_account.main.secondary_readonly_mongodb_connection_string
  sensitive   = true
}

# Read Endpoints
output "cosmosdb_account_read_endpoints" {
  description = "Lista de read endpoints"
  value       = azurerm_cosmosdb_account.main.read_endpoints
}

output "cosmosdb_account_write_endpoints" {
  description = "Lista de write endpoints"
  value       = azurerm_cosmosdb_account.main.write_endpoints
}

# Identity
output "cosmosdb_account_identity_principal_id" {
  description = "Principal ID da Managed Identity"
  value       = var.identity_type != null ? azurerm_cosmosdb_account.main.identity[0].principal_id : null
}

output "cosmosdb_account_identity_tenant_id" {
  description = "Tenant ID da Managed Identity"
  value       = var.identity_type != null ? azurerm_cosmosdb_account.main.identity[0].tenant_id : null
}

# SQL Databases
output "sql_database_ids" {
  description = "IDs dos SQL Databases"
  value       = { for k, v in azurerm_cosmosdb_sql_database.main : k => v.id }
}

output "sql_database_names" {
  description = "Nomes dos SQL Databases"
  value       = { for k, v in azurerm_cosmosdb_sql_database.main : k => v.name }
}

# SQL Containers
output "sql_container_ids" {
  description = "IDs dos SQL Containers"
  value       = { for k, v in azurerm_cosmosdb_sql_container.main : k => v.id }
}

output "sql_container_names" {
  description = "Nomes dos SQL Containers"
  value       = { for k, v in azurerm_cosmosdb_sql_container.main : k => v.name }
}

# MongoDB Databases
output "mongo_database_ids" {
  description = "IDs dos MongoDB Databases"
  value       = { for k, v in azurerm_cosmosdb_mongo_database.main : k => v.id }
}

output "mongo_database_names" {
  description = "Nomes dos MongoDB Databases"
  value       = { for k, v in azurerm_cosmosdb_mongo_database.main : k => v.name }
}

# MongoDB Collections
output "mongo_collection_ids" {
  description = "IDs das MongoDB Collections"
  value       = { for k, v in azurerm_cosmosdb_mongo_collection.main : k => v.id }
}

output "mongo_collection_names" {
  description = "Nomes das MongoDB Collections"
  value       = { for k, v in azurerm_cosmosdb_mongo_collection.main : k => v.name }
}

# Cassandra Keyspaces
output "cassandra_keyspace_ids" {
  description = "IDs dos Cassandra Keyspaces"
  value       = { for k, v in azurerm_cosmosdb_cassandra_keyspace.main : k => v.id }
}

output "cassandra_keyspace_names" {
  description = "Nomes dos Cassandra Keyspaces"
  value       = { for k, v in azurerm_cosmosdb_cassandra_keyspace.main : k => v.name }
}

# Cassandra Tables
output "cassandra_table_ids" {
  description = "IDs das Cassandra Tables"
  value       = { for k, v in azurerm_cosmosdb_cassandra_table.main : k => v.id }
}

output "cassandra_table_names" {
  description = "Nomes das Cassandra Tables"
  value       = { for k, v in azurerm_cosmosdb_cassandra_table.main : k => v.name }
}

# Gremlin Databases
output "gremlin_database_ids" {
  description = "IDs dos Gremlin Databases"
  value       = { for k, v in azurerm_cosmosdb_gremlin_database.main : k => v.id }
}

output "gremlin_database_names" {
  description = "Nomes dos Gremlin Databases"
  value       = { for k, v in azurerm_cosmosdb_gremlin_database.main : k => v.name }
}

# Gremlin Graphs
output "gremlin_graph_ids" {
  description = "IDs dos Gremlin Graphs"
  value       = { for k, v in azurerm_cosmosdb_gremlin_graph.main : k => v.id }
}

output "gremlin_graph_names" {
  description = "Nomes dos Gremlin Graphs"
  value       = { for k, v in azurerm_cosmosdb_gremlin_graph.main : k => v.name }
}

# Tables
output "table_ids" {
  description = "IDs das Tables"
  value       = { for k, v in azurerm_cosmosdb_table.main : k => v.id }
}

output "table_names" {
  description = "Nomes das Tables"
  value       = { for k, v in azurerm_cosmosdb_table.main : k => v.name }
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

# Complete Info
output "cosmosdb_account_info" {
  description = "Informações completas da conta Cosmos DB"
  value = {
    id                           = azurerm_cosmosdb_account.main.id
    name                         = azurerm_cosmosdb_account.main.name
    endpoint                     = azurerm_cosmosdb_account.main.endpoint
    location                     = var.location
    resource_group               = var.resource_group_name
    kind                         = var.kind
    consistency_level            = var.consistency_policy.consistency_level
    automatic_failover           = var.enable_automatic_failover
    multiple_write_locations     = var.enable_multiple_write_locations
    free_tier                    = var.enable_free_tier
    analytical_storage_enabled   = var.analytical_storage_enabled
    geo_locations                = [for loc in var.geo_locations : loc.location]
    capabilities                 = var.capabilities
    identity_enabled             = var.identity_type != null
    private_endpoint_enabled     = var.enable_private_endpoint
  }
}

# Data Explorer URL
output "data_explorer_url" {
  description = "URL do Data Explorer no Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_cosmosdb_account.main.id}/dataExplorer"
}

# Connection Info
output "connection_info" {
  description = "Informações de conexão"
  value = {
    endpoint     = azurerm_cosmosdb_account.main.endpoint
    account_name = azurerm_cosmosdb_account.main.name
    kind         = var.kind
  }
  sensitive = true
}
