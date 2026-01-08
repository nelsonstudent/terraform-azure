# Módulo Terraform - Azure PostgreSQL Flexible Server

Este módulo Terraform cria e gerencia um Azure PostgreSQL Flexible Server com todas as suas funcionalidades, incluindo alta disponibilidade, backups geo-redundantes, VNet integration e monitoramento.

## Recursos Criados

- **PostgreSQL Flexible Server** - Servidor PostgreSQL gerenciado
- **Databases** - Bancos de dados no servidor (opcional)
- **Firewall Rules** - Regras de firewall para controle de acesso (opcional)
- **Server Configurations** - Configurações customizadas do PostgreSQL (opcional)
- **Active Directory Administrator** - Administrador Azure AD (opcional)
- **Diagnostic Settings** - Configurações de monitoramento e logs (opcional)

## Características

✅ Suporte a todas as versões do PostgreSQL (11, 12, 13, 14, 15, 16)  
✅ SKUs Burstable, General Purpose e Memory Optimized  
✅ Alta disponibilidade (Zone Redundant e Same Zone)  
✅ VNet integration com Private DNS  
✅ Backup automatizado (7-35 dias)  
✅ Backup geo-redundante  
✅ Point-in-time restore  
✅ Read replicas  
✅ Autenticação Azure AD  
✅ Customer Managed Keys (CMK)  
✅ Auto-grow storage  
✅ Extensões PostgreSQL  
✅ Diagnósticos e monitoramento  

## Uso Básico

```hcl
module "postgresql" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql"
  resource_group_name = "my-resource-group"
  location            = "eastus"
  
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  version    = "15"

  backup_retention_days = 7

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo General Purpose com Alta Disponibilidade

```hcl
module "postgresql_ha" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql-ha"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  administrator_login    = "psqladmin"
  administrator_password = var.db_password
  
  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 131072  # 128 GB
  version    = "15"
  zone       = "1"

  auto_grow_enabled = true

  # Alta Disponibilidade Zone Redundant
  high_availability = {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  # Backup
  backup_retention_days        = 14
  geo_redundant_backup_enabled = true

  # Bancos de dados
  databases = [
    {
      name      = "app_production"
      charset   = "UTF8"
      collation = "en_US.utf8"
    },
    {
      name      = "app_staging"
      charset   = "UTF8"
      collation = "en_US.utf8"
    }
  ]

  # Configurações PostgreSQL
  postgresql_configurations = {
    "max_connections"           = "200"
    "shared_buffers"            = "262144"  # 2GB
    "effective_cache_size"      = "786432"  # 6GB
    "maintenance_work_mem"      = "131072"  # 128MB
    "checkpoint_completion_target" = "0.9"
    "wal_buffers"               = "16384"   # 16MB
    "default_statistics_target" = "100"
    "random_page_cost"          = "1.1"
    "work_mem"                  = "5242"    # 5MB
  }

  # Janela de Manutenção
  maintenance_window = {
    day_of_week  = 0  # Domingo
    start_hour   = 3
    start_minute = 0
  }

  tags = {
    Environment = "Production"
    Tier        = "GeneralPurpose"
    HA          = "Enabled"
  }
}
```

## Exemplo com VNet Integration e Private DNS

```hcl
module "postgresql_private" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql-private"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  administrator_login    = "psqladmin"
  administrator_password = var.db_password
  
  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 65536
  version    = "15"

  # VNet Integration
  delegated_subnet_id           = azurerm_subnet.postgresql.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false

  backup_retention_days = 14

  databases = [
    {
      name = "application_db"
    }
  ]

  tags = {
    Environment = "Production"
    Network     = "Private"
  }
}

# Subnet para PostgreSQL (precisa ser delegada)
resource "azurerm_subnet" "postgresql" {
  name                 = "postgresql-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "postgresql-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
```

## Exemplo com Acesso Público e Firewall Rules

```hcl
module "postgresql_public" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql-public"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  administrator_login    = "psqladmin"
  administrator_password = var.db_password
  
  sku_name   = "B_Standard_B2s"
  storage_mb = 32768
  version    = "15"

  public_network_access_enabled = true

  # Regras de Firewall
  firewall_rules = [
    {
      name             = "office-network"
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    },
    {
      name             = "azure-services"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  ]

  databases = [
    {
      name = "myapp_db"
    }
  ]

  tags = {
    Environment = "Development"
    Access      = "Public"
  }
}
```

## Exemplo Memory Optimized com Monitoramento

```hcl
module "postgresql_memory" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql-memory"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  administrator_login    = "psqladmin"
  administrator_password = var.db_password
  
  # Memory Optimized
  sku_name   = "MO_Standard_E4s_v3"
  storage_mb = 262144  # 256 GB
  version    = "15"
  zone       = "1"

  high_availability = {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  backup_retention_days        = 35  # Máximo
  geo_redundant_backup_enabled = true

  # Managed Identity
  identity_type = "SystemAssigned"

  # Diagnósticos
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  diagnostic_logs = [
    "PostgreSQLLogs"
  ]
  
  diagnostic_metrics = [
    "AllMetrics"
  ]

  databases = [
    {
      name = "analytics_db"
    }
  ]

  postgresql_configurations = {
    "max_connections"      = "500"
    "shared_buffers"       = "1048576"  # 8GB
    "effective_cache_size" = "3145728"  # 24GB
    "work_mem"             = "10485"    # 10MB
  }

  tags = {
    Environment = "Production"
    Tier        = "MemoryOptimized"
    Workload    = "Analytics"
  }
}
```

## Exemplo com Azure AD Authentication

```hcl
module "postgresql_aad" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql-aad"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  administrator_login    = "psqladmin"
  administrator_password = var.db_password
  
  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 65536
  version    = "15"

  # Managed Identity
  identity_type = "SystemAssigned"

  # Azure AD Authentication
  authentication = {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  databases = [
    {
      name = "secure_app_db"
    }
  ]

  tags = {
    Environment = "Production"
    Auth        = "AzureAD"
  }
}
```

## Exemplo de Read Replica

```hcl
# Servidor Primary
module "postgresql_primary" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql-primary"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  
  administrator_login    = "psqladmin"
  administrator_password = var.db_password
  
  sku_name   = "GP_Standard_D4s_v3"
  storage_mb = 131072
  version    = "15"

  replication_role = "Primary"

  backup_retention_days        = 14
  geo_redundant_backup_enabled = true

  databases = [
    {
      name = "production_db"
    }
  ]

  tags = {
    Environment = "Production"
    Role        = "Primary"
  }
}

# Read Replica
module "postgresql_replica" {
  source = "./modules/postgresql_flexible"

  name                = "myapp-postgresql-replica"
  resource_group_name = azurerm_resource_group.main.name
  location            = "westus"  # Região diferente
  
  sku_name   = "GP_Standard_D4s_v3"
  storage_mb = 131072
  version    = "15"

  create_mode      = "Replica"
  source_server_id = module.postgresql_primary.id
  replication_role = "Secondary"

  tags = {
    Environment = "Production"
    Role        = "Replica"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome do PostgreSQL Flexible Server | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `administrator_login` | Nome do usuário administrador | `string` | - | Sim |
| `administrator_password` | Senha do administrador | `string` | - | Sim |
| `sku_name` | SKU do servidor | `string` | `"B_Standard_B1ms"` | Não |
| `storage_mb` | Armazenamento em MB (32768-16777216) | `number` | `32768` | Não |
| `version` | Versão do PostgreSQL (11-16) | `string` | `"15"` | Não |
| `zone` | Zona de disponibilidade | `string` | `null` | Não |
| `high_availability` | Configuração de HA | `object` | `null` | Não |
| `backup_retention_days` | Dias de retenção (7-35) | `number` | `7` | Não |
| `geo_redundant_backup_enabled` | Backup geo-redundante | `bool` | `false` | Não |
| `delegated_subnet_id` | ID da subnet para VNet integration | `string` | `null` | Não |
| `private_dns_zone_id` | ID da Private DNS Zone | `string` | `null` | Não |
| `databases` | Lista de databases a criar | `list(object)` | `[]` | Não |
| `firewall_rules` | Lista de regras de firewall | `list(object)` | `[]` | Não |
| `postgresql_configurations` | Configurações do PostgreSQL | `map(string)` | `{}` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID do PostgreSQL Flexible Server |
| `name` | Nome do servidor |
| `fqdn` | FQDN para conexão |
| `connection_string` | Connection string básica (sensível) |
| `connection_strings` | Connection strings formatadas para diferentes linguagens |
| `endpoint_info` | Informações de endpoint |
| `server_info` | Informações completas do servidor |
| `ha_info` | Informações de alta disponibilidade |
| `databases` | Informações dos databases criados |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## SKUs Disponíveis

### Burstable (B) - Desenvolvimento/Teste
- **B_Standard_B1ms**: 1 vCore, 2 GB RAM
- **B_Standard_B2s**: 2 vCores, 4 GB RAM
- **B_Standard_B2ms**: 2 vCores, 8 GB RAM
- **B_Standard_B4ms**: 4 vCores, 16 GB RAM

### General Purpose (GP) - Produção Balanceada
- **GP_Standard_D2s_v3**: 2 vCores, 8 GB RAM
- **GP_Standard_D4s_v3**: 4 vCores, 16 GB RAM
- **GP_Standard_D8s_v3**: 8 vCores, 32 GB RAM
- **GP_Standard_D16s_v3**: 16 vCores, 64 GB RAM
- **GP_Standard_D32s_v3**: 32 vCores, 128 GB RAM
- **GP_Standard_D48s_v3**: 48 vCores, 192 GB RAM
- **GP_Standard_D64s_v3**: 64 vCores, 256 GB RAM

### Memory Optimized (MO) - Workloads Intensivos
- **MO_Standard_E2s_v3**: 2 vCores, 16 GB RAM
- **MO_Standard_E4s_v3**: 4 vCores, 32 GB RAM
- **MO_Standard_E8s_v3**: 8 vCores, 64 GB RAM
- **MO_Standard_E16s_v3**: 16 vCores, 128 GB RAM
- **MO_Standard_E32s_v3**: 32 vCores, 256 GB RAM
- **MO_Standard_E48s_v3**: 48 vCores, 384 GB RAM
- **MO_Standard_E64s_v3**: 64 vCores, 432 GB RAM

## Versões do PostgreSQL

- **PostgreSQL 11**: Suporte até novembro 2023 (EOL)
- **PostgreSQL 12**: Suporte até novembro 2024
- **PostgreSQL 13**: Suporte até novembro 2025
- **PostgreSQL 14**: Suporte até novembro 2026
- **PostgreSQL 15**: Suporte até novembro 2027
- **PostgreSQL 16**: Versão mais recente

## Alta Disponibilidade

### Zone Redundant
- Primary e standby em zonas diferentes
- Failover automático em ~60-120 segundos
- Proteção contra falhas de zona inteira
- Requer regiões com múltiplas zonas

### Same Zone
- Primary e standby na mesma zona
- Failover automático em ~60-120 segundos
- Proteção contra falhas de hardware
- Disponível em todas as regiões

## Backup e Restore

### Backup Automático
- Frequência: Contínua (WAL)
- Retenção: 7-35 dias
- Snapshots: Diários
- Geo-redundante: Opcional (paired region)

### Point-in-Time Restore
- Restauração para qualquer momento dentro do período de retenção
- Precisão de segundos
- Cria novo servidor

### Geo-Restore
- Restauração em região diferente
- Usa backup geo-redundante
- RPO: ~1 hora

## Connection Strings

O módulo fornece connection strings formatadas:

### psql (CLI)
```bash
psql "postgresql://user:password@server.postgres.database.azure.com:5432/dbname?sslmode=require"
```

### Python (psycopg2)
```python
import psycopg2

conn = psycopg2.connect(
    host='server.postgres.database.azure.com',
    port=5432,
    dbname='mydb',
    user='psqladmin',
    password='password',
    sslmode='require'
)
```

### Node.js (pg)
```javascript
const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://user:password@server.postgres.database.azure.com:5432/dbname?sslmode=require'
});
```

### .NET (Npgsql)
```csharp
var connString = "Host=server.postgres.database.azure.com;Port=5432;Database=mydb;Username=psqladmin;Password=password;SSL Mode=Require;Trust Server Certificate=true";
```

## Extensões PostgreSQL

Extensões comuns que podem ser habilitadas:

- **pg_stat_statements**: Estatísticas de queries
- **pgcrypto**: Funções criptográficas
- **uuid-ossp**: Geração de UUIDs
- **postgis**: Dados geoespaciais
- **pg_trgm**: Similaridade de texto
- **hstore**: Key-value store
- **ltree**: Hierarchical tree structures
- **btree_gin**: Índices GIN para tipos básicos
- **timescaledb**: Time-series data

## Segurança

### Melhores Práticas
- ✅ Use VNet integration em produção
- ✅ Desabilite acesso público quando possível
- ✅ Use Azure AD authentication
- ✅ Habilite geo-redundant backup
- ✅ Configure firewall rules específicas
- ✅ Use SSL/TLS obrigatório
- ✅ Implemente RBAC
- ✅ Habilite diagnósticos
- ✅ Use Customer Managed Keys para dados em repouso
- ✅ Rotacione passwords regularmente

### Auditoria e Compliance
- Diagnósticos para Log Analytics
- Threat Detection (Advanced Threat Protection)
- Audit logs
- Compliance: ISO, SOC, PCI DSS, HIPAA

## Monitoramento

### Métricas Importantes
- **CPU Percent**: < 80% recomendado
- **Memory Percent**: < 80% recomendado
- **Storage Percent**: < 80% recomendado
- **Active Connections**: Monitorar tendências
- **Failed Connections**: Investigar picos
- **Network In/Out**: Verificar bandwidth
- **Replication Lag**: < 10 segundos (HA)

### Alertas Recomendados
- CPU > 80% por 10 minutos
- Memória > 80% por 10 minutos
- Storage > 80%
- Conexões falhadas > 10 em 5 minutos
- Replication lag > 60 segundos

## Otimização de Performance

### Configurações Recomendadas

Para workloads OLTP:
```hcl
postgresql_configurations = {
  "max_connections"              = "200"
  "shared_buffers"               = "262144"   # 25% da RAM
  "effective_cache_size"         = "786432"   # 75% da RAM
  "maintenance_work_mem"         = "65536"    # 64MB
  "checkpoint_completion_target" = "0.9"
  "wal_buffers"                  = "16384"    # 16MB
  "default_statistics_target"    = "100"
  "random_page_cost"             = "1.1"      # Para SSD
  "work_mem"                     = "2621"     # 2.5MB
  "min_wal_size"                 = "1024"     # 1GB
  "max_wal_size"                 = "4096"     # 4GB
}
```

Para workloads Analytics:
```hcl
postgresql_configurations = {
  "max_connections"          = "100"
  "shared_buffers"           = "524288"   # 50% da RAM
  "effective_cache_size"     = "786432"   # 75% da RAM
  "work_mem"                 = "52428"    # 50MB
  "maintenance_work_mem"     = "131072"   # 128MB
  "random_page_cost"         = "1.1"
  "effective_io_concurrency" = "200"
  "max_worker_processes"     = "8"
  "max_parallel_workers"     = "8"
}
```

## Troubleshooting

### Erro: "Connection timeout"
- Verifique firewall rules
- Confirme VNet/subnet configuration
- Valide DNS resolution

### Erro: "Too many connections"
- Aumente max_connections
- Implemente connection pooling (PgBouncer)
- Revise application connection management

### Performance Lenta
- Analise queries com pg_stat_statements
- Verifique índices
- Revise configurações de memória
- Considere upgrade de SKU

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure com permissões adequadas
