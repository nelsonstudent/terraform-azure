# Azure SQL Database Terraform Module

Módulo Terraform para provisionar e gerenciar Azure SQL Database. Suporta múltiplos tiers (Basic, Standard, Premium, General Purpose, Business Critical, Hyperscale), backup automático, alta disponibilidade, geo-replicação, segurança avançada com Microsoft Defender e Vulnerability Assessment.

## Funcionalidades

- ✅ SQL Server gerenciado
- ✅ Múltiplos tiers (DTU e vCore)
- ✅ Serverless (auto-pause)
- ✅ Elastic Pools
- ✅ Geo-Replication e Failover Groups
- ✅ Private Endpoint
- ✅ Azure AD Authentication
- ✅ Transparent Data Encryption (TDE)
- ✅ Advanced Threat Protection
- ✅ Vulnerability Assessment
- ✅ Automatic Backups (PITR)
- ✅ Long-term Retention
- ✅ Zone Redundancy
- ✅ Read Scale-Out
- ✅ Auditing e Diagnostic Logs

## Pré-requisitos

- Terraform >= 1.0
- Provider `hashicorp/azurerm` >= 3.0
- Resource Group existente
- VNet e Subnet (para Private Endpoint)

## Tiers e Preços

### DTU-Based (Mais Simples)

#### Basic
- **Basic**: 5 DTU, 2 GB (~$5/mês)
- **Uso**: Dev/Test, databases pequenos

#### Standard
- **S0**: 10 DTU, 250 GB (~$15/mês)
- **S1**: 20 DTU, 250 GB (~$30/mês)
- **S2**: 50 DTU, 250 GB (~$75/mês)
- **S3**: 100 DTU, 250 GB (~$150/mês)
- **S4-S12**: Até 3000 DTU
- **Uso**: Produção geral

#### Premium
- **P1**: 125 DTU, 500 GB (~$465/mês)
- **P2**: 250 DTU, 500 GB (~$930/mês)
- **P4**: 500 DTU, 500 GB (~$1,860/mês)
- **P6**: 1000 DTU, 500 GB (~$3,720/mês)
- **Uso**: Alto desempenho, zone redundancy

### vCore-Based (Mais Flexível)

#### General Purpose (Serverless)
- **GP_S_Gen5_1**: 1 vCore, auto-pause (~$150/mês)
- **GP_S_Gen5_2**: 2 vCores, auto-pause (~$300/mês)
- **Uso**: Workloads intermitentes

#### General Purpose (Provisioned)
- **GP_Gen5_2**: 2 vCores, 32 GB storage (~$400/mês)
- **GP_Gen5_4**: 4 vCores, 32 GB storage (~$800/mês)
- **GP_Gen5_8**: 8 vCores, 32 GB storage (~$1,600/mês)

#### Business Critical
- **BC_Gen5_2**: 2 vCores, 32 GB (~$800/mês)
- **BC_Gen5_4**: 4 vCores, 32 GB (~$1,600/mês)
- **Recursos**: Zone redundancy, read replicas, maior IOPS

#### Hyperscale
- **HS_Gen5_2**: 2 vCores, até 100 TB (~$600/mês)
- **Recursos**: Storage ilimitado, múltiplas réplicas

## Uso Básico

### SQL Database Simples (Standard)

```hcl
module "sql_database" {
  source = "../../modules/database/sql_database"

  resource_group_name = "rg-database-prod"
  location            = "Brazil South"
  
  # SQL Server
  sql_server_name             = "sql-prod-brazilsouth"
  administrator_login         = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  # Database
  database_name = "db-application"
  sku_name      = "S1"  # Standard S1
  max_size_gb   = 250
  
  # Security
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  
  tags = {
    Environment = "production"
  }
}
```

### SQL Database com Azure AD e Private Endpoint

```hcl
module "sql_database" {
  source = "../../modules/database/sql_database"

  resource_group_name = "rg-database-prod"
  location            = "East US"
  
  # SQL Server
  sql_server_name             = "sql-prod-eastus"
  administrator_login         = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  # Azure AD Admin
  azuread_administrator = {
    login_username              = "DBA-Group"
    object_id                   = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    azuread_authentication_only = false  # Permite SQL auth também
  }
  
  # Database
  database_name = "db-webapp"
  sku_name      = "GP_Gen5_2"  # General Purpose, 2 vCores
  max_size_gb   = 100
  
  # Security
  public_network_access_enabled = false
  
  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.database.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.database.id]
  
  # Firewall (para acesso inicial via Portal)
  firewall_rules = {
    "allow-azure-services" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Serverless Database (Auto-Pause)

```hcl
module "sql_database_serverless" {
  source = "../../modules/database/sql_database"

  resource_group_name = "rg-database-dev"
  location            = "Brazil South"
  
  sql_server_name             = "sql-dev-serverless"
  administrator_login         = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  # Database Serverless
  database_name = "db-dev"
  sku_name      = "GP_S_Gen5_2"  # Serverless, 2 vCores
  
  # Serverless Settings
  auto_pause_delay_in_minutes = 60   # Auto-pause após 1 hora inativo
  min_capacity                = 0.5  # Mínimo 0.5 vCore
  
  max_size_gb = 32
  
  tags = {
    Environment = "development"
  }
}
```

## Exemplo Completo (Production-Ready)

```hcl
module "sql_database" {
  source = "../../modules/database/sql_database"

  # Resource Group
  resource_group_name = "rg-database-prod"
  location            = "Brazil South"
  
  # SQL Server
  sql_server_name             = "sql-prod-brazilsouth-001"
  sql_server_version          = "12.0"
  administrator_login         = "sqladmin"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version         = "1.2"
  public_network_access_enabled = false
  
  # Managed Identity
  identity_type = "SystemAssigned"
  
  # Azure AD Administrator
  azuread_administrator = {
    login_username              = "SQL-Admins"
    object_id                   = data.azuread_group.sql_admins.object_id
    azuread_authentication_only = false
  }
  
  # Database
  database_name = "db-production"
  collation     = "SQL_Latin1_General_CP1_CI_AS"
  
  # Business Critical tier with zone redundancy
  sku_name       = "BC_Gen5_4"  # 4 vCores Business Critical
  max_size_gb    = 500
  zone_redundant = true
  read_scale     = true  # Read replica para reporting
  
  # License (Azure Hybrid Benefit para economia)
  license_type = "BasePrice"
  
  # Storage
  storage_account_type = "GeoZone"  # Geo + Zone redundant
  
  # Encryption
  transparent_data_encryption_enabled = true
  
  # Backup - Short Term (Point-in-Time Restore)
  short_term_retention_policy = {
    retention_days           = 35  # Máximo 35 dias
    backup_interval_in_hours = 12
  }
  
  # Backup - Long Term Retention
  long_term_retention_policy = {
    weekly_retention  = "P4W"   # 4 semanas
    monthly_retention = "P12M"  # 12 meses
    yearly_retention  = "P5Y"   # 5 anos
    week_of_year      = 1       # Primeira semana do ano
  }
  
  # Geo Backup
  geo_backup_enabled = true
  
  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.database.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.database.id]
  
  # Virtual Network Rules (alternativa ao Private Endpoint)
  virtual_network_rules = {
    "allow-app-subnet" = {
      subnet_id = azurerm_subnet.apps.id
    }
  }
  
  # Auditing
  enable_auditing                    = true
  auditing_storage_endpoint          = azurerm_storage_account.audit.primary_blob_endpoint
  auditing_storage_account_access_key = azurerm_storage_account.audit.primary_access_key
  auditing_retention_days            = 90
  auditing_log_analytics_enabled     = true
  
  # Microsoft Defender for SQL
  enable_threat_detection                    = true
  threat_detection_storage_endpoint          = azurerm_storage_account.security.primary_blob_endpoint
  threat_detection_storage_account_access_key = azurerm_storage_account.security.primary_access_key
  threat_detection_retention_days            = 90
  threat_detection_email_account_admins      = true
  threat_detection_email_addresses = [
    "dba-team@company.com",
    "security@company.com"
  ]
  
  # Vulnerability Assessment
  enable_vulnerability_assessment                 = true
  vulnerability_assessment_storage_container_path = "${azurerm_storage_account.security.primary_blob_endpoint}${azurerm_storage_container.va.name}"
  vulnerability_assessment_storage_account_access_key = azurerm_storage_account.security.primary_access_key
  
  vulnerability_assessment_recurring_scans = {
    enabled                   = true
    email_subscription_admins = true
    emails                    = ["dba-team@company.com"]
  }
  
  # Diagnostic Settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  tags = {
    Environment = "production"
    Application = "webapp"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "database" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = "db-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.database.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
```

## Geo-Replication e Failover Group

```hcl
# Primary SQL Server (Brazil South)
module "sql_primary" {
  source = "../../modules/database/sql_database"

  resource_group_name          = "rg-database-prod"
  location                     = "Brazil South"
  sql_server_name              = "sql-prod-primary"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  database_name = "db-production"
  sku_name      = "S3"
  max_size_gb   = 250
  
  geo_backup_enabled = true
}

# Secondary SQL Server (East US)
module "sql_secondary" {
  source = "../../modules/database/sql_database"

  resource_group_name          = "rg-database-prod"
  location                     = "East US"
  sql_server_name              = "sql-prod-secondary"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  # Secondary database (read-only replica)
  database_name             = "db-production-secondary"
  create_mode               = "Secondary"
  creation_source_database_id = module.sql_primary.database_id
  
  sku_name    = "S3"
  max_size_gb = 250
}

# Failover Group
module "sql_failover" {
  source = "../../modules/database/sql_database"

  # ... configurações do primary ...
  
  create_failover_group            = true
  failover_group_name              = "fg-production"
  failover_group_partner_server_id = module.sql_secondary.sql_server_id
  failover_group_read_write_endpoint_mode = "Automatic"
  failover_group_grace_minutes     = 60
  failover_group_readonly_endpoint_enabled = true
}
```

**Connection String com Failover:**
```
Server=tcp:fg-production.database.windows.net,1433;Database=db-production;
```

## Elastic Pool (Múltiplos Databases)

```hcl
module "sql_elastic_pool" {
  source = "../../modules/database/sql_database"

  resource_group_name          = "rg-database-prod"
  location                     = "Brazil South"
  sql_server_name              = "sql-prod-pool"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  # Elastic Pool
  create_elastic_pool        = true
  elastic_pool_name          = "epool-production"
  elastic_pool_sku_name      = "GP_Gen5"
  elastic_pool_sku_tier      = "GeneralPurpose"
  elastic_pool_sku_capacity  = 4  # 4 vCores
  elastic_pool_max_size_gb   = 500
  elastic_pool_zone_redundant = false
  
  elastic_pool_min_capacity = 0
  elastic_pool_max_capacity = 4
  
  # Database no pool
  database_name   = "db-app1"
  elastic_pool_id = module.sql_elastic_pool.elastic_pool_id
}
```

## Firewall Rules

### Permitir Azure Services
```hcl
firewall_rules = {
  "allow-azure-services" = {
    start_ip_address = "0.0.0.0"
    end_ip_address   = "0.0.0.0"
  }
}
```

### Permitir Office Network
```hcl
firewall_rules = {
  "allow-office" = {
    start_ip_address = "203.0.113.0"
    end_ip_address   = "203.0.113.255"
  }
}
```

### Permitir IP Específico
```hcl
firewall_rules = {
  "allow-jumpbox" = {
    start_ip_address = "198.51.100.10"
    end_ip_address   = "198.51.100.10"
  }
}
```

## Connection Strings

### ADO.NET (C#)
```csharp
string connectionString = "Server=tcp:sql-prod.database.windows.net,1433;Initial Catalog=db-production;Persist Security Info=False;User ID=sqladmin;Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
```

### JDBC (Java)
```java
String connectionString = "jdbc:sqlserver://sql-prod.database.windows.net:1433;database=db-production;user=sqladmin@sql-prod;password={your_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;";
```

### Node.js (mssql)
```javascript
const config = {
  user: 'sqladmin',
  password: '{your_password}',
  server: 'sql-prod.database.windows.net',
  database: 'db-production',
  options: {
    encrypt: true,
    trustServerCertificate: false
  }
};
```

### Python (pyodbc)
```python
connection_string = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER=sql-prod.database.windows.net;DATABASE=db-production;UID=sqladmin;PWD={your_password}'
```

## Managed Identity Authentication

```hcl
identity_type = "SystemAssigned"
```

**Connection String com Managed Identity (C#):**
```csharp
using Azure.Identity;
using Microsoft.Data.SqlClient;

string connectionString = "Server=tcp:sql-prod.database.windows.net,1433;Database=db-production;";
using var connection = new SqlConnection(connectionString);
connection.AccessToken = await new DefaultAzureCredential().GetTokenAsync(
    new TokenRequestContext(new[] { "https://database.windows.net/.default" })).ConfigureAwait(false);
connection.Open();
```

## Point-in-Time Restore

```hcl
# Restore para um ponto específico no tempo
module "sql_restored" {
  source = "../../modules/database/sql_database"

  resource_group_name          = "rg-database-prod"
  location                     = "Brazil South"
  sql_server_name              = "sql-prod"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  database_name               = "db-production-restored"
  create_mode                 = "PointInTimeRestore"
  creation_source_database_id = module.sql_primary.database_id
  restore_point_in_time       = "2025-11-19T10:00:00Z"
  
  sku_name = "S3"
}
```

## Monitoring e Alertas

### Query Performance Insight
```bash
# Visualizar no portal
https://portal.azure.com/#@/resource${database_id}/queryPerformance
```

### Automatic Tuning
Habilita automaticamente no portal ou via T-SQL:
```sql
ALTER DATABASE db-production
SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON, CREATE_INDEX = ON, DROP_INDEX = ON);
```

### Alertas Importantes
```hcl
resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "sql-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [module.sql_database.database_id]
  
  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| resource_group_name | Nome do Resource Group | `string` | - | Sim |
| location | Localização Azure | `string` | - | Sim |
| sql_server_name | Nome do SQL Server | `string` | - | Sim |
| administrator_login | Username admin | `string` | - | Sim |
| administrator_login_password | Password admin | `string` | - | Sim |
| database_name | Nome do database | `string` | - | Sim |
| sku_name | SKU (Basic, S0, P1, GP_Gen5_2, etc) | `string` | `"S0"` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| sql_server_id | ID do SQL Server |
| sql_server_fqdn | FQDN do server |
| database_id | ID do database |
| connection_string | Connection string |
| sql_server_identity_principal_id | Principal ID da Managed Identity |

## Boas Práticas

### 1. **Segurança**
- ✅ Use Private Endpoint para databases de produção
- ✅ Habilite Azure AD Authentication
- ✅ Configure `minimum_tls_version = "1.2"`
- ✅ Habilite Microsoft Defender for SQL
- ✅ Configure Vulnerability Assessment
- ✅ Use Transparent Data Encryption (TDE)
- ✅ Habilite Auditing

### 2. **Alta Disponibilidade**
- ✅ Use Zone Redundancy (Premium/Business Critical)
- ✅ Configure Geo-Replication para DR
- ✅ Use Failover Groups
- ✅ Configure Long-term Retention

### 3. **Performance**
- ✅ Use tier adequado ao workload
- ✅ Habilite Read Scale-Out (Premium/Business Critical)
- ✅ Configure Automatic Tuning
- ✅ Monitore Query Performance Insight
- ✅ Use Elastic Pools para múltiplos databases

### 4. **Custo**
- ✅ Use Serverless para workloads intermitentes
- ✅ Azure Hybrid Benefit (license_type = "BasePrice")
- ✅ Reserved Capacity para economia (1-3 anos)
- ✅ Ajuste tier baseado em utilização real

## Troubleshooting

### Não consegue conectar
```bash
# Testar conectividade
Test-NetConnection sql-prod.database.windows.net -Port 1433

# Verificar firewall rules
az sql server firewall-rule list --server sql-prod --resource-group rg-database
```

### Performance lenta
- Verificar DTU/vCore utilization no portal
- Analisar Query Performance Insight
- Considerar upgrade de tier
- Verificar índices com Database Advisor

### Restore de backup
```bash
# Listar restore points
az sql db list-deleted --server sql-prod --resource-group rg-database

# Restore
az sql db restore --dest-name db-restored --time "2025-11-19T10:00:00Z" --resource-group rg-database --server sql-prod --name db-production
```

## Referências

- [SQL Database Documentation](https://learn.microsoft.com/azure/azure-sql/)
- [SQL Database Pricing](https://azure.microsoft.com/pricing/details/sql-database/)
- [DTU vs vCore](https://learn.microsoft.com/azure/azure-sql/database/purchasing-models)
- [High Availability](https://learn.microsoft.com/azure/azure-sql/database/high-availability-sla)