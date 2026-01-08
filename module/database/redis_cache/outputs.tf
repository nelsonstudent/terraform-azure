output "id" {
  description = "ID do Azure Redis Cache"
  value       = azurerm_redis_cache.main.id
}

output "name" {
  description = "Nome do Redis Cache"
  value       = azurerm_redis_cache.main.name
}

output "hostname" {
  description = "Hostname do Redis Cache"
  value       = azurerm_redis_cache.main.hostname
}

output "ssl_port" {
  description = "Porta SSL do Redis Cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "port" {
  description = "Porta não-SSL do Redis Cache"
  value       = azurerm_redis_cache.main.port
}

output "primary_access_key" {
  description = "Chave de acesso primária"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Chave de acesso secundária"
  value       = azurerm_redis_cache.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Connection string primária (formato: hostname:port,password=primary_key,ssl=true)"
  value       = azurerm_redis_cache.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Connection string secundária (formato: hostname:port,password=secondary_key,ssl=true)"
  value       = azurerm_redis_cache.main.secondary_connection_string
  sensitive   = true
}

output "redis_version" {
  description = "Versão do Redis"
  value       = azurerm_redis_cache.main.redis_version
}

output "sku_name" {
  description = "SKU do Redis Cache"
  value       = azurerm_redis_cache.main.sku_name
}

output "family" {
  description = "Família do SKU"
  value       = azurerm_redis_cache.main.family
}

output "capacity" {
  description = "Capacidade do Redis Cache"
  value       = azurerm_redis_cache.main.capacity
}

output "location" {
  description = "Localização do Redis Cache"
  value       = azurerm_redis_cache.main.location
}

output "private_static_ip_address" {
  description = "Endereço IP privado estático (se configurado)"
  value       = azurerm_redis_cache.main.private_static_ip_address
}

output "enable_non_ssl_port" {
  description = "Indica se a porta não-SSL está habilitada"
  value       = azurerm_redis_cache.main.non_ssl_port_enabled
}

output "minimum_tls_version" {
  description = "Versão mínima do TLS"
  value       = azurerm_redis_cache.main.minimum_tls_version
}

output "identity" {
  description = "Identidade gerenciada do Redis Cache"
  value = var.identity_type != null ? {
    type         = azurerm_redis_cache.main.identity[0].type
    principal_id = azurerm_redis_cache.main.identity[0].principal_id
    tenant_id    = azurerm_redis_cache.main.identity[0].tenant_id
  } : null
}

output "redis_configuration" {
  description = "Configurações do Redis"
  value = {
    maxmemory_policy       = azurerm_redis_cache.main.redis_configuration[0].maxmemory_policy
    maxmemory_reserved     = azurerm_redis_cache.main.redis_configuration[0].maxmemory_reserved
    maxmemory_delta        = azurerm_redis_cache.main.redis_configuration[0].maxmemory_delta
    authentication_enabled  = azurerm_redis_cache.main.redis_configuration[0].authentication_enabled
    rdb_backup_enabled     = azurerm_redis_cache.main.redis_configuration[0].rdb_backup_enabled
    rdb_backup_frequency   = azurerm_redis_cache.main.redis_configuration[0].rdb_backup_frequency
    aof_backup_enabled     = azurerm_redis_cache.main.redis_configuration[0].aof_backup_enabled
  }
}

output "firewall_rules" {
  description = "Regras de firewall configuradas"
  value = {
    for k, v in azurerm_redis_firewall_rule.rules : k => {
      name      = v.name
      start_ip  = v.start_ip
      end_ip    = v.end_ip
    }
  }
}

output "private_endpoint_id" {
  description = "ID do Private Endpoint (se habilitado)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].id : null
}

output "private_endpoint_ip" {
  description = "Endereço IP privado do Private Endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

output "patch_schedule" {
  description = "Janela de manutenção configurada"
  value       = length(var.patch_schedule) > 0 ? var.patch_schedule : null
}

# Connection strings formatadas para uso em aplicações
output "connection_strings" {
  description = "Connection strings formatadas para diferentes cenários"
  value = {
    # StackExchange.Redis format
    stackexchange_redis = "${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port},password=${azurerm_redis_cache.main.primary_access_key},ssl=True,abortConnect=False"
    
    # ServiceStack.Redis format
    servicestack_redis = "${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}?ssl=true"
    
    # node-redis format
    node_redis = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}"
  }
  sensitive = true
}

# Informações úteis para aplicações
output "endpoint_info" {
  description = "Informações de endpoint para conexão"
  value = {
    host     = azurerm_redis_cache.main.hostname
    ssl_port = azurerm_redis_cache.main.ssl_port
    port     = azurerm_redis_cache.main.port
    ssl_enabled = !var.enable_non_ssl_port
  }
}

# Capacidade e performance
output "performance_info" {
  description = "Informações de capacidade e performance"
  value = {
    sku_name         = azurerm_redis_cache.main.sku_name
    capacity         = azurerm_redis_cache.main.capacity
    family           = azurerm_redis_cache.main.family
    shard_count      = var.shard_count
    replicas_per_primary = var.replicas_per_primary
  }
}