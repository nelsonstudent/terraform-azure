# Módulo Terraform - Azure Monitor

Este módulo Terraform gerencia todos os aspectos do Azure Monitor, incluindo Log Analytics Workspace, Application Insights, alertas, action groups, autoscaling, workbooks e data collection rules.

## Recursos Criados

- **Log Analytics Workspace** - Workspace central para logs
- **Application Insights** - Monitoramento de aplicações
- **Action Groups** - Notificações e ações de alertas
- **Metric Alerts** - Alertas baseados em métricas
- **Log Analytics Queries** - Alertas baseados em queries
- **Activity Log Alerts** - Alertas de atividades Azure
- **Data Collection Rules** - Regras de coleta de dados
- **Workbooks** - Dashboards customizados
- **Autoscale Settings** - Configurações de autoscaling
- **Diagnostic Settings** - Configurações de diagnóstico

## Características

✅ Log Analytics Workspace completo  
✅ Application Insights para APM  
✅ Metric alerts (static e dynamic)  
✅ Log query alerts (KQL)  
✅ Activity log alerts  
✅ Multiple notification channels  
✅ Action Groups (email, SMS, webhook, etc)  
✅ Autoscaling rules  
✅ Custom workbooks  
✅ Data collection rules  
✅ Smart detection  
✅ Diagnostic settings  

## Uso Básico

```hcl
module "azure_monitor" {
  source = "./modules/azure_monitor"

  resource_group_name = "my-resource-group"
  location            = "eastus"

  # Log Analytics Workspace
  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "myapp-law"
  log_analytics_retention_days   = 30

  # Action Group
  action_groups = [
    {
      name       = "ops-team"
      short_name = "opstm"
      
      email_receiver = [
        {
          name          = "ops-email"
          email_address = "ops@contoso.com"
        }
      ]
    }
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Application Insights

```hcl
module "azure_monitor_appinsights" {
  source = "./modules/azure_monitor"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Log Analytics
  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "myapp-law"
  log_analytics_sku              = "PerGB2018"
  log_analytics_retention_days   = 90

  # Application Insights
  create_application_insights = true
  application_insights = [
    {
      name                = "myapp-web-appinsights"
      application_type    = "web"
      sampling_percentage = 100
    },
    {
      name                = "myapp-api-appinsights"
      application_type    = "other"
      sampling_percentage = 50
    }
  ]

  tags = {
    Environment = "Production"
    Monitoring  = "Enabled"
  }
}
```

## Exemplo com Alertas Completos

```hcl
module "azure_monitor_alerts" {
  source = "./modules/azure_monitor"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "myapp-law"

  # Action Groups
  action_groups = [
    {
      name       = "critical-alerts"
      short_name = "critical"
      
      email_receiver = [
        {
          name                    = "oncall-email"
          email_address           = "oncall@contoso.com"
          use_common_alert_schema = true
        }
      ]
      
      sms_receiver = [
        {
          name         = "oncall-sms"
          country_code = "1"
          phone_number = "5551234567"
        }
      ]
      
      webhook_receiver = [
        {
          name                    = "slack-webhook"
          service_uri             = "https://hooks.slack.com/services/XXX"
          use_common_alert_schema = true
        }
      ]
    },
    {
      name       = "warning-alerts"
      short_name = "warning"
      
      email_receiver = [
        {
          name          = "team-email"
          email_address = "team@contoso.com"
        }
      ]
    }
  ]

  # Metric Alerts
  metric_alerts = [
    {
      name        = "high-cpu-alert"
      description = "Alert when CPU is over 80%"
      severity    = 2
      frequency   = "PT5M"
      window_size = "PT15M"
      scopes      = [azurerm_virtual_machine.vm.id]
      
      criteria = [
        {
          metric_namespace = "Microsoft.Compute/virtualMachines"
          metric_name      = "Percentage CPU"
          aggregation      = "Average"
          operator         = "GreaterThan"
          threshold        = 80
        }
      ]
      
      action_group_ids = [module.azure_monitor_alerts.action_group_ids["critical-alerts"]]
    },
    {
      name        = "high-memory-alert"
      description = "Alert when memory is over 90%"
      severity    = 1
      frequency   = "PT5M"
      window_size = "PT15M"
      scopes      = [azurerm_virtual_machine.vm.id]
      
      criteria = [
        {
          metric_namespace = "Microsoft.Compute/virtualMachines"
          metric_name      = "Available Memory Bytes"
          aggregation      = "Average"
          operator         = "LessThan"
          threshold        = 1073741824  # 1GB
        }
      ]
      
      action_group_ids = [module.azure_monitor_alerts.action_group_ids["critical-alerts"]]
    }
  ]

  # Log Query Alerts
  scheduled_query_rules = [
    {
      name        = "failed-requests-alert"
      description = "Alert on high failed request rate"
      severity    = 2
      frequency   = "PT5M"
      time_window = "PT15M"
      
      query = <<-QUERY
        requests
        | where success == false
        | summarize count() by bin(timestamp, 5m)
        | where count_ > 10
      QUERY
      
      trigger = {
        operator  = "GreaterThan"
        threshold = 0
      }
      
      action_group_ids = [module.azure_monitor_alerts.action_group_ids["critical-alerts"]]
    }
  ]

  # Activity Log Alerts
  activity_log_alerts = [
    {
      name        = "vm-deletion-alert"
      description = "Alert when VMs are deleted"
      scopes      = [azurerm_resource_group.main.id]
      
      criteria = {
        category       = "Administrative"
        operation_name = "Microsoft.Compute/virtualMachines/delete"
      }
      
      action_group_ids = [module.azure_monitor_alerts.action_group_ids["critical-alerts"]]
    }
  ]

  tags = {
    Environment = "Production"
    Alerting    = "Comprehensive"
  }
}
```

## Exemplo com Autoscaling

```hcl
module "azure_monitor_autoscale" {
  source = "./modules/azure_monitor"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "myapp-law"

  # Action Groups para notificações
  action_groups = [
    {
      name       = "scaling-notifications"
      short_name = "scaling"
      
      email_receiver = [
        {
          name          = "ops-team"
          email_address = "ops@contoso.com"
        }
      ]
    }
  ]

  # Autoscale Settings
  autoscale_settings = [
    {
      name               = "vmss-autoscale"
      target_resource_id = azurerm_virtual_machine_scale_set.vmss.id
      enabled            = true
      
      profile = [
        {
          name = "default-profile"
          
          capacity = {
            default = 2
            minimum = 2
            maximum = 10
          }
          
          rule = [
            {
              metric_trigger = {
                metric_name        = "Percentage CPU"
                metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
                time_grain         = "PT1M"
                statistic          = "Average"
                time_window        = "PT5M"
                time_aggregation   = "Average"
                operator           = "GreaterThan"
                threshold          = 75
              }
              
              scale_action = {
                direction = "Increase"
                type      = "ChangeCount"
                value     = "1"
                cooldown  = "PT5M"
              }
            },
            {
              metric_trigger = {
                metric_name        = "Percentage CPU"
                metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
                time_grain         = "PT1M"
                statistic          = "Average"
                time_window        = "PT5M"
                time_aggregation   = "Average"
                operator           = "LessThan"
                threshold          = 25
              }
              
              scale_action = {
                direction = "Decrease"
                type      = "ChangeCount"
                value     = "1"
                cooldown  = "PT5M"
              }
            }
          ]
        },
        {
          name = "business-hours"
          
          capacity = {
            default = 5
            minimum = 3
            maximum = 15
          }
          
          recurrence = {
            timezone = "Pacific Standard Time"
            days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
            hours    = [9]
            minutes  = [0]
          }
        }
      ]
      
      notification = {
        email = {
          send_to_subscription_administrator = false
          custom_emails                      = ["ops@contoso.com"]
        }
      }
    }
  ]

  tags = {
    Environment = "Production"
    Autoscaling = "Enabled"
  }
}
```

## Exemplo com Data Collection Rules

```hcl
module "azure_monitor_dcr" {
  source = "./modules/azure_monitor"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "myapp-law"

  # Data Collection Rules
  data_collection_rules = [
    {
      name        = "windows-vm-collection"
      description = "Collect performance and events from Windows VMs"
      
      destinations = {
        log_analytics = [
          {
            workspace_resource_id = module.azure_monitor_dcr.log_analytics_workspace_id
            name                  = "workspace-destination"
          }
        ]
      }
      
      data_flow = [
        {
          streams      = ["Microsoft-Perf", "Microsoft-Event"]
          destinations = ["workspace-destination"]
        }
      ]
      
      data_sources = {
        performance_counter = [
          {
            name                          = "perfcounter-datasource"
            streams                       = ["Microsoft-Perf"]
            sampling_frequency_in_seconds = 60
            counter_specifiers = [
              "\\Processor(_Total)\\% Processor Time",
              "\\Memory\\Available Bytes",
              "\\LogicalDisk(_Total)\\% Free Space"
            ]
          }
        ]
        
        windows_event_log = [
          {
            name    = "eventlog-datasource"
            streams = ["Microsoft-Event"]
            x_path_queries = [
              "System!*[System[(Level=1 or Level=2 or Level=3)]]",
              "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
            ]
          }
        ]
      }
    }
  ]

  tags = {
    Environment = "Production"
    DataCollection = "Enabled"
  }
}
```

## Exemplo Completo - Monitoramento Enterprise

```hcl
module "azure_monitor_complete" {
  source = "./modules/azure_monitor"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Log Analytics Workspace
  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "enterprise-law"
  log_analytics_sku              = "PerGB2018"
  log_analytics_retention_days   = 90
  log_analytics_daily_quota_gb   = 10

  # Application Insights
  create_application_insights = true
  application_insights = [
    {
      name             = "web-app-insights"
      application_type = "web"
    },
    {
      name             = "api-app-insights"
      application_type = "other"
    }
  ]

  # Action Groups
  action_groups = [
    {
      name       = "critical-24x7"
      short_name = "crit24x7"
      
      email_receiver = [
        {
          name          = "oncall"
          email_address = "oncall@company.com"
        }
      ]
      
      sms_receiver = [
        {
          name         = "oncall-sms"
          country_code = "1"
          phone_number = "5551234567"
        }
      ]
      
      webhook_receiver = [
        {
          name        = "pagerduty"
          service_uri = "https://events.pagerduty.com/integration/xxx/enqueue"
        }
      ]
    },
    {
      name       = "ops-team"
      short_name = "ops"
      
      email_receiver = [
        {
          name          = "ops-dl"
          email_address = "ops@company.com"
        }
      ]
    }
  ]

  # Metric Alerts
  metric_alerts = [
    # Infrastructure Alerts
    {
      name        = "vm-high-cpu"
      severity    = 2
      frequency   = "PT5M"
      window_size = "PT15M"
      scopes      = [azurerm_virtual_machine.web.id]
      
      criteria = [{
        metric_namespace = "Microsoft.Compute/virtualMachines"
        metric_name      = "Percentage CPU"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 85
      }]
      
      action_group_ids = [
        module.azure_monitor_complete.action_group_ids["critical-24x7"]
      ]
    },
    # Application Performance
    {
      name        = "app-high-response-time"
      severity    = 2
      frequency   = "PT5M"
      window_size = "PT15M"
      scopes      = [module.azure_monitor_complete.application_insights_ids["web-app-insights"]]
      
      criteria = [{
        metric_namespace = "Microsoft.Insights/components"
        metric_name      = "requests/duration"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 2000  # 2 seconds
      }]
      
      action_group_ids = [
        module.azure_monitor_complete.action_group_ids["ops-team"]
      ]
    }
  ]

  # Log Alerts
  scheduled_query_rules = [
    {
      name        = "high-error-rate"
      severity    = 1
      frequency   = "PT5M"
      time_window = "PT15M"
      
      query = <<-QUERY
        requests
        | where success == false
        | summarize ErrorCount = count() by bin(timestamp, 5m)
        | where ErrorCount > 50
      QUERY
      
      trigger = {
        operator  = "GreaterThan"
        threshold = 0
      }
      
      action_group_ids = [
        module.azure_monitor_complete.action_group_ids["critical-24x7"]
      ]
    }
  ]

  # Activity Alerts
  activity_log_alerts = [
    {
      name   = "resource-health-alert"
      scopes = [azurerm_subscription.current.id]
      
      criteria = {
        category = "ResourceHealth"
      }
      
      action_group_ids = [
        module.azure_monitor_complete.action_group_ids["ops-team"]
      ]
    }
  ]

  tags = {
    Environment = "Production"
    Monitoring  = "Enterprise"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `create_log_analytics_workspace` | Criar workspace | `bool` | `true` | Não |
| `log_analytics_workspace_name` | Nome do workspace | `string` | - | Condicional |
| `application_insights` | Application Insights | `list(object)` | `[]` | Não |
| `action_groups` | Action Groups | `list(object)` | `[]` | Não |
| `metric_alerts` | Metric alerts | `list(object)` | `[]` | Não |
| `scheduled_query_rules` | Query alerts | `list(object)` | `[]` | Não |
| `autoscale_settings` | Autoscaling | `list(object)` | `[]` | Não |
| `tags` | Tags para recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `log_analytics_workspace_id` | ID do workspace |
| `log_analytics_workspace_workspace_id` | Workspace GUID |
| `application_insights_ids` | IDs dos App Insights |
| `application_insights_instrumentation_keys` | Instrumentation keys |
| `action_group_ids` | IDs dos action groups |
| `metric_alert_ids` | IDs dos metric alerts |
| `summary` | Resumo dos recursos |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## Alert Severities

- **0 - Critical**: Falha crítica do sistema
- **1 - Error**: Erro que requer atenção imediata
- **2 - Warning**: Aviso que pode evoluir para erro
- **3 - Informational**: Informação geral
- **4 - Verbose**: Informação detalhada

## Metric Aggregations

- **Average**: Média dos valores
- **Minimum**: Valor mínimo
- **Maximum**: Valor máximo
- **Total**: Soma dos valores
- **Count**: Contagem de valores

## Common Metrics

### Virtual Machines
- `Percentage CPU`
- `Available Memory Bytes`
- `Network In Total`
- `Network Out Total`
- `Disk Read Bytes`
- `Disk Write Bytes`

### App Service
- `CpuPercentage`
- `MemoryPercentage`
- `Http5xx`
- `ResponseTime`
- `Requests`

### SQL Database
- `cpu_percent`
- `dtu_consumption_percent`
- `storage_percent`
- `connection_successful`
- `connection_failed`

### Storage Account
- `UsedCapacity`
- `Transactions`
- `Availability`
- `SuccessE2ELatency`

## KQL Queries Úteis

### Failed Requests
```kql
requests
| where success == false
| summarize count() by resultCode, bin(timestamp, 5m)
```

### Slow Queries
```kql
requests
| where duration > 2000
| project timestamp, name, duration, resultCode
| order by duration desc
```

### Exceptions
```kql
exceptions
| summarize count() by type, outerMessage
| order by count_ desc
```

### CPU by Computer
```kql
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
```

## Melhores Práticas

### Log Analytics
1. **Configure retention** - Baseado em compliance
2. **Set daily quota** - Controle de custos
3. **Use workspace isolation** - Por ambiente
4. **Enable diagnostic logs** - Todos recursos críticos
5. **Archive old data** - Para compliance

### Alertas
1. **Use appropriate severity** - Priorize corretamente
2. **Avoid alert fatigue** - Tune thresholds
3. **Group related alerts** - Action groups
4. **Test notifications** - Antes de prod
5. **Document runbooks** - Para cada alerta

### Application Insights
1. **Use sampling** - Para alto volume
2. **Track custom events** - Eventos de negócio
3. **Set up availability tests** - Proativo
4. **Configure smart detection** - ML-based
5. **Use dependency tracking** - Troubleshooting

### Autoscaling
1. **Set appropriate min/max** - Capacity planning
2. **Use cooldown periods** - Evite flapping
3. **Test scale operations** - Antes de prod
4. **Monitor costs** - Scaling pode ser caro
5. **Use scheduled scaling** - Padrões conhecidos

### Custos
1. **Monitor ingestion** - Logs são caros
2. **Use retention tiers** - Archive old data
3. **Filter noisy logs** - Agent-side
4. **Review unused alerts** - Cleanup
5. **Use commitment tiers** - Para alto volume

## Troubleshooting

### Alertas Não Disparando
- Verifique query/threshold
- Confirme action group configurado
- Valide permissions no target
- Check frequency vs window size

### App Insights Sem Dados
- Verifique instrumentation key
- Confirme SDK instalado
- Valide firewall rules
- Check sampling configuration

### Workspace Sem Dados
- Verifique diagnostic settings
- Confirme agent instalado
- Valide network connectivity
- Check workspace key

### Autoscaling Não Funciona
- Verifique metric source
- Confirme permissions
- Valide scale rules
- Check cooldown periods

## Limitações

### Log Analytics
- Retenção: 30-730 dias (interactive)
- Daily quota: máximo configurável
- Query timeout: 3 minutos
- Rows per query: 500,000

### Application Insights
- Sampling: 0.1-100%
- Daily cap: Configurável
- Data retention: 90 dias (standard)
- Custom metrics: 10 dimensions

### Alerts
- Rules per subscription: 5000
- Frequency: mínimo 1 minuto
- Evaluation period: mínimo 5 minutos
- Action groups: 2000 per subscription

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure
- Permissions apropriadas