# Módulo Terraform - Log Analytics Workspace

Este módulo Terraform gerencia completamente um Azure Log Analytics Workspace, incluindo solutions, saved searches, data export rules, linked services, custom tables e data collection endpoints.

## Recursos Criados

- **Log Analytics Workspace** - Workspace central para logs e métricas
- **Solutions** - Solutions pré-configuradas (Security, Updates, etc)
- **Saved Searches** - Queries KQL salvas
- **Data Export Rules** - Exportação contínua de dados
- **Linked Services** - Serviços vinculados (Automation, etc)
- **Linked Storage Accounts** - Storage para diferentes tipos de dados
- **Custom Tables** - Tabelas customizadas para logs
- **Data Collection Endpoint** - Endpoint para ingestão de dados
- **Diagnostic Settings** - Monitoramento do próprio workspace

## Características

✅ Todos os SKUs suportados  
✅ Commitment tiers (capacity reservation)  
✅ Solutions gerenciadas automaticamente  
✅ Custom tables e schemas  
✅ Data export rules  
✅ Saved searches (queries KQL)  
✅ Linked services  
✅ Data Collection Endpoints  
✅ Customer Managed Keys  
✅ Managed Identity  
✅ Private Link support  
✅ Diagnostic settings  

## Uso Básico

```hcl
module "log_analytics" {
  source = "./modules/log_analytics_workspace"

  name                = "myapp-law"
  resource_group_name = "my-resource-group"
  location            = "eastus"
  
  sku               = "PerGB2018"
  retention_in_days = 30

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Solutions Comuns

```hcl
module "log_analytics_with_solutions" {
  source = "./modules/log_analytics_workspace"

  name                = "myapp-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku               = "PerGB2018"
  retention_in_days = 90
  daily_quota_gb    = 5

  # Habilitar solutions comuns automaticamente
  enable_common_solutions = {
    security_center       = true
    update_management     = true
    change_tracking       = true
    sql_assessment        = true
    container_insights    = true
    vm_insights          = true
    service_map          = true
    activity_log_analytics = true
  }

  tags = {
    Environment = "Production"
    Monitoring  = "Full"
  }
}
```

## Exemplo com Saved Searches

```hcl
module "log_analytics_queries" {
  source = "./modules/log_analytics_workspace"

  name                = "myapp-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku               = "PerGB2018"
  retention_in_days = 30

  # Saved Searches (Queries KQL)
  saved_searches = [
    {
      name         = "failed-requests"
      display_name = "Failed Requests Last Hour"
      category     = "Application"
      query        = <<-QUERY
        requests
        | where timestamp > ago(1h)
        | where success == false
        | summarize count() by resultCode, name
        | order by count_ desc
      QUERY
    },
    {
      name         = "high-cpu-vms"
      display_name = "VMs with High CPU"
      category     = "Infrastructure"
      query        = <<-QUERY
        Perf
        | where ObjectName == "Processor" and CounterName == "% Processor Time"
        | where CounterValue > 80
        | summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
      QUERY
    },
    {
      name         = "security-events"
      display_name = "Recent Security Events"
      category     = "Security"
      query        = <<-QUERY
        SecurityEvent
        | where TimeGenerated > ago(24h)
        | where EventID in (4624, 4625, 4720, 4726)
        | summarize count() by EventID, Account
      QUERY
    }
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Data Export

```hcl
# Storage Account para exportação
resource "azurerm_storage_account" "export" {
  name                     = "logexportstorage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Event Hub para exportação
resource "azurerm_eventhub_namespace" "export" {
  name                = "log-export-eh"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
}

module "log_analytics_export" {
  source = "./modules/log_analytics_workspace"

  name                = "myapp-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku               = "PerGB2018"
  retention_in_days = 30

  # Data Export Rules
  data_export_rules = [
    {
      name                    = "export-to-storage"
      destination_resource_id = azurerm_storage_account.export.id
      table_names             = ["SecurityEvent", "Syslog"]
      enabled                 = true
    },
    {
      name                    = "export-to-eventhub"
      destination_resource_id = azurerm_eventhub_namespace.export.id
      table_names             = ["AzureActivity", "AzureDiagnostics"]
      enabled                 = true
    }
  ]

  tags = {
    Environment = "Production"
    Export      = "Enabled"
  }
}
```

## Exemplo com Commitment Tier

```hcl
module "log_analytics_commitment" {
  source = "./modules/log_analytics_workspace"

  name                = "enterprise-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku                                = "CapacityReservation"
  reservation_capacity_in_gb_per_day = 100  # 100 GB/day commitment
  retention_in_days                  = 90

  enable_common_solutions = {
    security_center       = true
    update_management     = true
    change_tracking       = true
    container_insights    = true
    vm_insights          = true
  }

  tags = {
    Environment = "Production"
    Tier        = "Commitment"
  }
}
```

## Exemplo com Custom Tables

```hcl
module "log_analytics_custom" {
  source = "./modules/log_analytics_workspace"

  name                = "myapp-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku               = "PerGB2018"
  retention_in_days = 30

  # Custom Tables
  custom_tables = [
    {
      name           = "CustomApp_CL"
      retention_days = 90
      plan           = "Analytics"
      
      schema = {
        columns = [
          {
            name = "TimeGenerated"
            type = "datetime"
          },
          {
            name = "ApplicationName"
            type = "string"
          },
          {
            name = "EventLevel"
            type = "string"
          },
          {
            name = "Message"
            type = "string"
          },
          {
            name = "UserId"
            type = "string"
          }
        ]
      }
    }
  ]

  tags = {
    Environment = "Production"
    CustomLogs  = "Enabled"
  }
}
```

## Exemplo com Linked Services (Automation)

```hcl
# Automation Account
resource "azurerm_automation_account" "main" {
  name                = "automation-account"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Basic"
}

module "log_analytics_linked" {
  source = "./modules/log_analytics_workspace"

  name                = "myapp-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku               = "PerGB2018"
  retention_in_days = 30

  # Linked Services
  linked_services = [
    {
      name        = "automation"
      resource_id = azurerm_automation_account.main.id
    }
  ]

  # Solutions que requerem Automation
  enable_common_solutions = {
    update_management = true
    change_tracking   = true
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Data Collection Endpoint

```hcl
module "log_analytics_dce" {
  source = "./modules/log_analytics_workspace"

  name                = "myapp-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  sku               = "PerGB2018"
  retention_in_days = 30

  # Data Collection Endpoint
  create_data_collection_endpoint                    = true
  data_collection_endpoint_name                      = "myapp-dce"
  data_collection_endpoint_public_network_access_enabled = false

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo Completo - Enterprise

```hcl
module "log_analytics_enterprise" {
  source = "./modules/log_analytics_workspace"

  name                = "enterprise-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  # SKU e Retenção
  sku                                = "PerGB2018"
  retention_in_days                  = 90
  daily_quota_gb                     = 10

  # Network
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  # Managed Identity
  identity_type = "SystemAssigned"

  # Solutions
  enable_common_solutions = {
    security_center            = true
    update_management          = true
    change_tracking            = true
    sql_assessment             = true
    container_insights         = true
    vm_insights               = true
    service_map               = true
    azure_automation          = true
    activity_log_analytics    = true
    key_vault_analytics       = true
    network_performance_monitor = true
  }

  # Saved Searches
  saved_searches = [
    {
      name         = "critical-errors"
      display_name = "Critical Errors - Last 24h"
      category     = "Troubleshooting"
      query        = <<-QUERY
        AzureDiagnostics
        | where TimeGenerated > ago(24h)
        | where Level == "Critical" or Level == "Error"
        | summarize count() by Resource, Category
        | order by count_ desc
      QUERY
    },
    {
      name         = "security-alerts"
      display_name = "Security Alerts"
      category     = "Security"
      query        = <<-QUERY
        SecurityAlert
        | where TimeGenerated > ago(7d)
        | summarize count() by AlertSeverity, DisplayName
        | order by count_ desc
      QUERY
    }
  ]

  # Data Export (para compliance/archive)
  data_export_rules = [
    {
      name                    = "compliance-export"
      destination_resource_id = azurerm_storage_account.compliance.id
      table_names = [
        "SecurityEvent",
        "AzureActivity",
        "AuditLogs",
        "SigninLogs"
      ]
      enabled = true
    }
  ]

  # Linked Storage Accounts
  linked_storage_accounts = {
    custom_logs = [azurerm_storage_account.custom_logs.id]
    query       = [azurerm_storage_account.query_storage.id]
    alerts      = [azurerm_storage_account.alerts.id]
  }

  # Data Collection Endpoint
  create_data_collection_endpoint = true

  tags = {
    Environment = "Production"
    Compliance  = "Required"
    Tier        = "Enterprise"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome do workspace | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `sku` | SKU do workspace | `string` | `"PerGB2018"` | Não |
| `retention_in_days` | Dias de retenção | `number` | `30` | Não |
| `daily_quota_gb` | Quota diária em GB | `number` | `-1` | Não |
| `enable_common_solutions` | Solutions comuns | `object` | `{}` | Não |
| `saved_searches` | Queries salvas | `list(object)` | `[]` | Não |
| `data_export_rules` | Regras de exportação | `list(object)` | `[]` | Não |
| `custom_tables` | Tabelas customizadas | `list(object)` | `[]` | Não |
| `tags` | Tags para recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | Resource ID do workspace |
| `workspace_id` | Workspace ID (GUID) |
| `primary_shared_key` | Primary key (sensível) |
| `secondary_shared_key` | Secondary key (sensível) |
| `solution_names` | Lista de solutions instaladas |
| `connection_info` | Informações de conexão |
| `workspace_summary` | Resumo completo |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## SKUs Disponíveis

### Free
- 500 MB/dia
- 7 dias retenção
- Sem SLA
- Ideal para testes

### PerGB2018
- Pay-per-GB
- 30-730 dias retenção
- Sem commitment
- Mais comum

### CapacityReservation
- Commitment tiers (100-5000 GB/dia)
- Desconto sobre PerGB2018
- 30-730 dias retenção
- Para alto volume

### Legacy (não recomendado)
- PerNode
- Premium
- Standalone
- Unlimited

## Solutions Disponíveis

### Security & Compliance
- **Security** (Microsoft Defender for Cloud)
- **SecurityInsights** (Microsoft Sentinel)
- **AzureSecurityCenter**

### IT Operations
- **Updates** (Update Management)
- **ChangeTracking** (Change Tracking)
- **ServiceMap** (Service Map)

### Infrastructure
- **VMInsights** (VM Insights)
- **ContainerInsights** (Container Insights)
- **NetworkMonitoring** (Network Performance Monitor)

### Applications
- **ApplicationInsights** (Application Insights)
- **SQLAssessment** (SQL Health Check)
- **AzureAutomation**

### Activity & Logs
- **AzureActivity** (Activity Log Analytics)
- **KeyVaultAnalytics** (Key Vault Analytics)
- **LogManagement**

## Data Retention

### Standard Retention
- 30-730 dias (PerGB2018, CapacityReservation)
- 7 dias (Free)
- Custo incluído no ingestion pricing

### Archive (Log Analytics Restore)
- Dados mais antigos movidos para archive
- Custo reduzido
- Restore sob demanda
- Até 7 anos

## Data Export Destinations

### Suportados
- **Azure Storage Account** - Arquivamento
- **Azure Event Hub** - Stream processing
- **Azure Event Grid** - Event-driven

### Casos de Uso
- Compliance e auditoria
- Long-term storage
- SIEM integration
- Data lake integration

## Common KQL Queries

### Failed Requests
```kql
requests
| where success == false
| where timestamp > ago(1h)
| summarize count() by resultCode, name
| order by count_ desc
```

### High CPU VMs
```kql
Perf
| where ObjectName == "Processor"
| where CounterName == "% Processor Time"
| where CounterValue > 80
| summarize avg(CounterValue) by Computer
```

### Security Events
```kql
SecurityEvent
| where TimeGenerated > ago(24h)
| where EventID in (4624, 4625)
| summarize LoginAttempts = count() by Account, EventID
```

### Container Logs
```kql
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error"
| project TimeGenerated, Computer, LogEntry
```

### Failed Logins
```kql
SigninLogs
| where TimeGenerated > ago(7d)
| where ResultType != 0
| summarize FailedLogins = count() by UserPrincipalName, ResultType
```

## Melhores Práticas

### Workspace Design
1. **One per environment** - Dev, Test, Prod separados
2. **Consider scale** - Workspace por região para alto volume
3. **RBAC carefully** - Controle de acesso granular
4. **Plan retention** - Balance custo vs compliance
5. **Use commitment tiers** - Para >100GB/dia

### Cost Optimization
1. **Set daily caps** - Evite surpresas
2. **Filter at source** - Agent-side filtering
3. **Use basic logs** - Para logs de baixa importância
4. **Archive old data** - Move para storage
5. **Monitor ingestion** - Workbook de custos

### Performance
1. **Optimize queries** - Use summarize, where
2. **Limit time ranges** - Não query tudo
3. **Use functions** - Reusable KQL
4. **Index properly** - Custom tables
5. **Partition large queries** - Chunk by time

### Security
1. **Use Managed Identity** - Evite shared keys
2. **Enable Private Link** - Para ambientes sensíveis
3. **Disable public access** - Quando possível
4. **RBAC not shared keys** - Azure AD auth
5. **Audit access** - Monitor queries

### Operations
1. **Document queries** - Saved searches com descriptions
2. **Version control** - Workspace config in Git
3. **Alert on quota** - 80% threshold
4. **Test data export** - Antes de prod
5. **Regular cleanup** - Remove unused solutions

## Troubleshooting

### Dados Não Chegam
- Verifique diagnostic settings
- Confirme agent instalado/configurado
- Valide network connectivity
- Check daily quota

### Queries Lentas
- Adicione time range específico
- Use summarize adequadamente
- Verifique índices (custom tables)
- Considere materialized views

### High Costs
- Review ingestion por table
- Check diagnostic settings verbosos
- Valide retention necessária
- Considere basic logs tier

### Export Não Funciona
- Verifique permissions no destino
- Confirme table names corretos
- Valide destination health
- Check export rule enabled

## Limitações

### Free Tier
- 500 MB/dia
- 7 dias retenção
- Sem alert rules
- Sem export

### PerGB2018
- Sem limite de ingestão
- Até 730 dias retenção
- Custos variáveis

### Workspace
- Máximo 1000 tables
- Query timeout: 10 minutos
- Concurrent queries: 5
- Results: 500,000 rows

## Pricing (Referência)

### PerGB2018
- ~$2.30/GB ingested
- First 5GB/dia free
- Retention: $0.12/GB/month (após 90 dias)

### Capacity Reservation
- 100GB: ~$196/dia (15% desconto)
- 200GB: ~$368/dia (25% desconto)
- 500GB+: ~35-50% desconto

### Export
- Storage: custos normais do destino
- Event Hub: custos normais
- Sem custo adicional do workspace

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure
- Contributor ou equivalent