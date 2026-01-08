output "id" {
  description = "ID da Storage Account"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Nome da Storage Account"
  value       = azurerm_storage_account.main.name
}

output "primary_location" {
  description = "Localização primária da Storage Account"
  value       = azurerm_storage_account.main.primary_location
}

output "secondary_location" {
  description = "Localização secundária da Storage Account (se houver replicação geo)"
  value       = azurerm_storage_account.main.secondary_location
}

output "primary_blob_endpoint" {
  description = "Endpoint primário para Blob Storage"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_queue_endpoint" {
  description = "Endpoint primário para Queue Storage"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "Endpoint primário para Table Storage"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_file_endpoint" {
  description = "Endpoint primário para File Storage"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_dfs_endpoint" {
  description = "Endpoint primário para Data Lake Storage Gen2"
  value       = azurerm_storage_account.main.primary_dfs_endpoint
}

output "primary_web_endpoint" {
  description = "Endpoint primário para Static Website"
  value       = azurerm_storage_account.main.primary_web_endpoint
}

output "primary_access_key" {
  description = "Chave de acesso primária da Storage Account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Chave de acesso secundária da Storage Account"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Connection string primária da Storage Account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Connection string secundária da Storage Account"
  value       = azurerm_storage_account.main.secondary_connection_string
  sensitive   = true
}

output "primary_blob_connection_string" {
  description = "Connection string primária para Blob Storage"
  value       = azurerm_storage_account.main.primary_blob_connection_string
  sensitive   = true
}

output "secondary_blob_connection_string" {
  description = "Connection string secundária para Blob Storage"
  value       = azurerm_storage_account.main.secondary_blob_connection_string
  sensitive   = true
}

output "identity" {
  description = "Identidade gerenciada da Storage Account"
  value = var.identity_type != null ? {
    type         = azurerm_storage_account.main.identity[0].type
    principal_id = azurerm_storage_account.main.identity[0].principal_id
    tenant_id    = azurerm_storage_account.main.identity[0].tenant_id
  } : null
}

output "containers" {
  description = "Informações dos containers criados"
  value = {
    for k, v in azurerm_storage_container.containers : k => {
      id                    = v.id
      name                  = v.name
      has_immutability_policy = v.has_immutability_policy
      has_legal_hold        = v.has_legal_hold
      resource_manager_id   = v.resource_manager_id
    }
  }
}

output "file_shares" {
  description = "Informações dos file shares criados"
  value = {
    for k, v in azurerm_storage_share.file_shares : k => {
      id                   = v.id
      name                 = v.name
      quota                = v.quota
      resource_manager_id  = v.resource_manager_id
      url                  = v.url
    }
  }
}

output "queues" {
  description = "Informações das queues criadas"
  value = {
    for k, v in azurerm_storage_queue.queues : k => {
      id                  = v.id
      name                = v.name
      resource_manager_id = v.resource_manager_id
    }
  }
}

output "tables" {
  description = "Informações das tables criadas"
  value = {
    for k, v in azurerm_storage_table.tables : k => {
      id   = v.id
      name = v.name
    }
  }
}