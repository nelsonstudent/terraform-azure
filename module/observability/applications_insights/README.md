# Módulo Terraform - Azure Application Insights

Este módulo Terraform provisiona um Azure Application Insights com configurações de monitoramento, telemetria e detecção inteligente de anomalias.

## Características

- Provisionamento de Application Insights com configurações customizáveis
- Integração com Log Analytics Workspace
- Regras de Smart Detection pré-configuradas
- Controle de retenção de dados e limites de ingestão
- Configurações de segurança e acesso
- Suporte a sampling para controle de custos

## Uso Básico

```hcl
module "application_insights" {
  source = "./modules/application_insight"

  name                = "app-insights-prod"
  location            = "eastus"
  resource_group_name = "rg-monitoring-prod"
  application_type    = "web"
  
  workspace_id      = module.log_analytics.id
  retention_in_days = 90

  tags = {
    Environment = "Production"
    Project     = "MyApp"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo Avançado

```hcl
module "application_insights" {
  source = "./modules/application_insight"

  name                = "app-insights-prod"
  location            = "eastus"
  resource_group_name = "rg-monitoring-prod"
  application_type    = "web"
  
  # Integração com Log Analytics
  workspace_id = module.log_analytics.id
  
  # Configurações de retenção e limites
  retention_in_days                     = 180
  daily_data_cap_in_gb                  = 10
  daily_data_cap_notifications_disabled = false
  
  # Sampling para controle de custos
  sampling_percentage = 50
  
  # Configurações de segurança
  disable_ip_masking            = false
  local_authentication_disabled = true
  internet_ingestion_enabled    = true
  internet_query_enabled        = false
  
  # Smart Detection
  enable_smart_detection = true
  action_group_ids = [
    azurerm_monitor_action_group.alerts.id
  ]

  tags = {
    Environment = "Production"
    Project     = "MyApp"
    CostCenter  = "Engineering"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Múltiplas Aplicações

```hcl
# Application Insights para Frontend
module "app_insights_frontend" {
  source = "./modules/application_insight"

  name                = "app-insights-frontend-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = module.log_analytics.id
  retention_in_days   = 90
  
  tags = merge(var.common_tags, {
    Component = "Frontend"
  })
}

# Application Insights para Backend API
module "app_insights_backend" {
  source = "./modules/application_insight"

  name                = "app-insights-backend-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "other"
  workspace_id        = module.log_analytics.id
  retention_in_days   = 180
  
  sampling_percentage = 70
  
  tags = merge(var.common_tags, {
    Component = "Backend"
  })
}

# Application Insights para Mobile App
module "app_insights_mobile" {
  source = "./modules/application_insight"

  name                = "app-insights-mobile-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "ios"
  workspace_id        = module.log_analytics.id
  
  tags = merge(var.common_tags, {
    Component = "Mobile"
  })
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| name | Nome do Application Insights | `string` | n/a | sim |
| location | Localização do recurso Azure | `string` | n/a | sim |
| resource_group_name | Nome do Resource Group | `string` | n/a | sim |
| application_type | Tipo de aplicação | `string` | `"web"` | não |
| workspace_id | ID do Log Analytics Workspace | `string` | `null` | não |
| retention_in_days | Período de retenção dos dados (dias) | `number` | `90` | não |
| daily_data_cap_in_gb | Limite diário de ingestão (GB) | `number` | `null` | não |
| daily_data_cap_notifications_disabled | Desabilitar notificações de limite | `bool` | `false` | não |
| sampling_percentage | Percentual de sampling (0-100) | `number` | `100` | não |
| disable_ip_masking | Desabilitar mascaramento de IP | `bool` | `false` | não |
| local_authentication_disabled | Desabilitar autenticação local | `bool` | `false` | não |
| internet_ingestion_enabled | Habilitar ingestão via internet | `bool` | `true` | não |
| internet_query_enabled | Habilitar queries via internet | `bool` | `true` | não |
| enable_smart_detection | Habilitar detecção inteligente | `bool` | `true` | não |
| action_group_ids | IDs dos Action Groups para alertas | `list(string)` | `[]` | não |
| tags | Tags para aplicar ao recurso | `map(string)` | `{}` | não |

## Outputs

| Nome | Descrição | Sensível |
|------|-----------|----------|
| id | ID do Application Insights | não |
| name | Nome do Application Insights | não |
| instrumentation_key | Chave de instrumentação | sim |
| connection_string | Connection string | sim |
| app_id | Application ID | não |
| workspace_id | ID do Log Analytics Workspace | não |
| application_type | Tipo de aplicação | não |
| retention_in_days | Período de retenção | não |
| sampling_percentage | Percentual de sampling | não |
| smart_detection_rules | IDs das regras de detecção | não |
| resource | Objeto completo do recurso | sim |

## Tipos de Aplicação Suportados

- `web` - Aplicações web (padrão)
- `ios` - Aplicações iOS
- `java` - Aplicações Java
- `MobileCenter` - Mobile Center
- `Node.JS` - Aplicações Node.js
- `other` - Outros tipos
- `phone` - Aplicações Windows Phone
- `store` - Windows Store apps

## Smart Detection Rules

O módulo configura automaticamente as seguintes regras de detecção inteligente quando `enable_smart_detection = true`:

1. **Failure Anomalies** - Detecta anomalias em falhas
2. **Slow Page Load Time** - Detecta páginas com carregamento lento
3. **Slow Server Response Time** - Detecta respostas lentas do servidor
4. **Degradation in Server Response Time** - Detecta degradação no tempo de resposta
5. **Potential Memory Leak** - Detecta possíveis vazamentos de memória
6. **Abnormal Rise in Exception Volume** - Detecta aumento anormal em exceções
7. **Potential Security Issue** - Detecta possíveis problemas de segurança

## Períodos de Retenção Válidos

- 30, 60, 90, 120, 180, 270, 365, 550, 730 dias

## Sampling

O sampling permite reduzir custos limitando a quantidade de telemetria enviada:

- `100` - Sem sampling (todos os dados)
- `50` - 50% dos dados
- `25` - 25% dos dados
- etc.

## Integração com Aplicações

### .NET Core

```csharp
services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = "InstrumentationKey=...;IngestionEndpoint=...";
});
```

### Node.js

```javascript
const appInsights = require('applicationinsights');
appInsights.setup('<CONNECTION_STRING>').start();
```

### Python

```python
from applicationinsights import TelemetryClient
tc = TelemetryClient('<INSTRUMENTATION_KEY>')
```

## Acesso aos Dados

### Via Portal Azure
Acesse o Application Insights no portal e use as ferramentas de análise integradas.

### Via API REST
```bash
curl -H "x-api-key: <API_KEY>" \
  "https://api.applicationinsights.io/v1/apps/<APP_ID>/metrics/requests/count"
```

### Via Kusto Query
```kql
requests
| where timestamp > ago(1h)
| summarize count() by resultCode
```

## Considerações de Segurança

1. **API Keys**: Use `local_authentication_disabled = true` e prefira Azure AD
2. **IP Masking**: Mantenha habilitado para compliance com GDPR
3. **Internet Access**: Restrinja se possível usando Private Link
4. **Connection Strings**: Armazene em Key Vault, não em código

## Otimização de Custos

1. **Sampling**: Reduza o percentual para diminuir volume de dados
2. **Daily Cap**: Configure limite diário para evitar surpresas
3. **Retention**: Use períodos menores se não precisar de histórico longo
4. **Log Analytics**: Integre para análise centralizada e melhor custo-benefício

## Dependências

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Log Analytics Workspace (recomendado)
- Action Groups (opcional, para alertas)

## Recursos Criados

- `azurerm_application_insights` - Recurso principal
- `azurerm_application_insights_smart_detection_rule` - 7 regras (se habilitado)

## Referências

- [Azure Application Insights Documentation](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights)
- [Application Insights API](https://dev.applicationinsights.io/)