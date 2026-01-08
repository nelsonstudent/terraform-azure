output "id" {
  description = "ID do PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "name" {
  description = "Nome do PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "fqdn" {
  description = "FQDN do PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "public_network_access_enabled" {
  description = "Indica se o acesso público está habilitado"
  value       = azurerm_postgresql_flexible_server.main.public_network_access_enabled
}

output "administrator_login" {
  description = "Nome do usuário administrador"
  value       = var.administrator_login
}

output "administrator_password" {
  description = "Senha do administrador"
  value       = var.administrator_password
  sensitive   = true
}

output "version" {
  description = "Versão do PostgreSQL"
  value       = azurerm_postgresql_flexible_server.main.version
}

output "sku_name" {
  description = "SKU do servidor"
  value       = azurerm_postgresql_flexible_server.main.sku_name
}

output "storage_mb" {
  description = "Armazenamento em MB"
  value       = azurerm_postgresql_flexible_server.main.storage_mb
}

output "backup_retention_days" {
  description = "Dias de retenção de backup"
  value       = azurerm_postgresql_flexible_server.main.backup_retention_days
}

output "geo_redundant_backup_enabled" {
  description = "Indica se backup geo-redundante está habilitado"
  value       = azurerm_postgresql_flexible_server.main.geo_redundant_backup_enabled
}

output "zone" {
  description = "Zona de disponibilidade"
  value       = azurerm_postgresql_flexible_server.main.zone
}

output "high_availability" {
  description = "Configuração de alta disponibilidade"
  value = var.high_availability != null ? {
    mode                      = azurerm_postgresql_flexible_server.main.high_availability[0].mode
    standby_availability_zone = azurerm_postgresql_flexible_server.main.high_availability[0].standby_availability_zone
  } : null
}

output "identity" {
  description = "Identidade gerenciada do servidor"
  value = var.identity_type != null ? {
    type         = azurerm_postgresql_flexible_server.main.identity[0].type
    principal_id = azurerm_postgresql_flexible_server.main.identity[0].principal_id
    tenant_id    = azurerm_postgresql_flexible_server.main.identity[0].tenant_id
  } : null
}

output "databases" {
  description = "Informações dos databases criados"
  value = {
    for k, v in azurerm_postgresql_flexible_server_database.databases : k => {
      id        = v.id
      name      = v.name
      charset   = v.charset
      collation = v.collation
    }
  }
}

output "firewall_rules" {
  description = "Regras de firewall configuradas"
  value = {
    for k, v in azurerm_postgresql_flexible_server_firewall_rule.rules : k => {
      id       = v.id
      name     = v.name
      start_ip = v.start_ip_address
      end_ip   = v.end_ip_address
    }
  }
}

output "configurations" {
  description = "Configurações do PostgreSQL aplicadas"
  value = {
    for k, v in azurerm_postgresql_flexible_server_configuration.config : k => {
      id    = v.id
      name  = v.name
      value = v.value
    }
  }
}

# Connection Strings
output "connection_string" {
  description = "Connection string básica do PostgreSQL"
  value       = "host=${azurerm_postgresql_flexible_server.main.fqdn} port=5432 dbname=postgres user=${var.administrator_login} password=${var.administrator_password} sslmode=require"
  sensitive   = true
}

output "connection_strings" {
  description = "Connection strings formatadas para diferentes bibliotecas/frameworks"
  value = {
    # psql CLI
    psql = "postgresql://${var.administrator_login}:${var.administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/postgres?sslmode=require"
    
    # ADO.NET (C#)
    ado_net = "Host=${azurerm_postgresql_flexible_server.main.fqdn};Port=5432;Database=postgres;Username=${var.administrator_login};Password=${var.administrator_password};SSL Mode=Require;Trust Server Certificate=true"
    
    # JDBC (Java)
    jdbc = "jdbc:postgresql://${azurerm_postgresql_flexible_server.main.fqdn}:5432/postgres?user=${var.administrator_login}&password=${var.administrator_password}&sslmode=require"
    
    # Node.js (pg)
    nodejs = "postgresql://${var.administrator_login}:${var.administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/postgres?sslmode=require"
    
    # Python (psycopg2)
    python = "host='${azurerm_postgresql_flexible_server.main.fqdn}' port=5432 dbname='postgres' user='${var.administrator_login}' password='${var.administrator_password}' sslmode='require'"
    
    # PHP (PDO)
    php = "pgsql:host=${azurerm_postgresql_flexible_server.main.fqdn};port=5432;dbname=postgres;user=${var.administrator_login};password=${var.administrator_password};sslmode=require"
    
    # Ruby (pg)
    ruby = "postgres://${var.administrator_login}:${var.administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/postgres?sslmode=require"
    
    # Go (pq)
    go = "host=${azurerm_postgresql_flexible_server.main.fqdn} port=5432 user=${var.administrator_login} password=${var.administrator_password} dbname=postgres sslmode=require"
  }
  sensitive = true
}

output "endpoint_info" {
  description = "Informações de endpoint para conexão"
  value = {
    host                 = azurerm_postgresql_flexible_server.main.fqdn
    port                 = 5432
    default_database     = "postgres"
    ssl_required         = true
    is_vnet_integrated   = var.delegated_subnet_id != null
    public_access_enabled = var.public_network_access_enabled
  }
}

output "server_info" {
  description = "Informações gerais do servidor"
  value = {
    id                           = azurerm_postgresql_flexible_server.main.id
    name                         = azurerm_postgresql_flexible_server.main.name
    fqdn                         = azurerm_postgresql_flexible_server.main.fqdn
    location                     = azurerm_postgresql_flexible_server.main.location
    resource_group_name          = azurerm_postgresql_flexible_server.main.resource_group_name
    version                      = azurerm_postgresql_flexible_server.main.version
    sku_name                     = azurerm_postgresql_flexible_server.main.sku_name
    storage_mb                   = azurerm_postgresql_flexible_server.main.storage_mb
    storage_tier                 = azurerm_postgresql_flexible_server.main.storage_tier
    zone                         = azurerm_postgresql_flexible_server.main.zone
    backup_retention_days        = azurerm_postgresql_flexible_server.main.backup_retention_days
    geo_redundant_backup_enabled = azurerm_postgresql_flexible_server.main.geo_redundant_backup_enabled
    auto_grow_enabled            = azurerm_postgresql_flexible_server.main.auto_grow_enabled
  }
}

output "ha_info" {
  description = "Informações de alta disponibilidade"
  value = var.high_availability != null ? {
    enabled                   = true
    mode                      = azurerm_postgresql_flexible_server.main.high_availability[0].mode
    standby_availability_zone = azurerm_postgresql_flexible_server.main.high_availability[0].standby_availability_zone
  } : {
    enabled = false
  }
}

output "database_list" {
  description = "Lista de nomes dos databases criados"
  value       = [for db in azurerm_postgresql_flexible_server_database.databases : db.name]
}

output "maintenance_window" {
  description = "Janela de manutenção configurada"
  value       = var.maintenance_window
}

output "is_replica" {
  description = "Indica se o servidor é uma réplica"
  value       = var.replication_role == "Secondary"
}

output "replication_role" {
  description = "Papel de replicação do servidor"
  value       = var.replication_role
}
