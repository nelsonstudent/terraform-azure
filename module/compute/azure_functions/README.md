# Azure Functions Terraform Module

Módulo Terraform para provisionar e gerenciar Azure Functions (serverless compute). Suporta Linux e Windows com múltiplos runtimes, triggers variados, scaling automático e integração completa com o ecossistema Azure.

## Funcionalidades

- ✅ Suporte para Linux e Windows
- ✅ Múltiplos runtimes (Node.js, .NET, Python, Java, PowerShell, Custom)
- ✅ Planos: Consumption (pay-per-execution), Elastic Premium, Dedicated
- ✅ Triggers: HTTP, Timer, Queue, Blob, Event Hub, Service Bus, Cosmos DB
- ✅ Storage Account integrada
- ✅ Application Insights automático
- ✅ Managed Identity (System e User Assigned)
- ✅ VNet Integration
- ✅ Deployment slots (staging)
- ✅ CORS e IP restrictions
- ✅ Durable Functions support

## Pré-requisitos

- Terraform >= 1.0
- Provider `hashicorp/azurerm` >= 3.0
- Resource Group existente
- Azure Subscription ativa

## Planos e SKUs

### Consumption Plan (Y1)
- **Características**: Pay-per-execution, scale automático até 200 instâncias
- **Timeout**: 5 minutos (default), até 10 minutos
- **Memória**: 1.5 GB por instância
- **Custo**: Apenas pelo tempo de execução
- **Limitação**: Cold start, sem Always On

### Elastic Premium Plan (EP1, EP2, EP3)
- **EP1**: 1 core, 3.5 GB RAM, 250 GB storage
- **EP2**: 2 cores, 7 GB RAM, 250 GB storage
- **EP3**: 4 cores, 14 GB RAM, 250 GB storage
- **Características**: Pre-warmed instances, VNet integration, sem cold start
- **Timeout**: Ilimitado
- **Custo**: Por instância/hora

### Dedicated Plan (App Service Plan)
- **B1, S1, P1v2, P1v3**: Mesmos SKUs do App Service
- **Características**: Always On, recursos dedicados
- **Uso**: Quando já existe um App Service Plan subutilizado

## Uso Básico

### Node.js HTTP Function (Consumption)

```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"

  resource_group_name = "rg-functions-prod"
  location            = "Brazil South"
  
  # Storage Account (obrigatória)
  storage_account_name = "stfuncprod123"
  
  # Service Plan (Consumption)
  service_plan_name = "asp-func-consumption"
  os_type           = "Linux"
  sku_name          = "Y1"
  
  # Function App
  function_app_name           = "func-api-prod"
  functions_worker_runtime    = "node"
  functions_extension_version = "~4"
  
  # Runtime
  application_stack = {
    node_version = "20"
  }
  
  # App Settings
  app_settings = {
    "NODE_ENV" = "production"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Python Function com Queue Trigger

```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"

  resource_group_name  = "rg-functions-prod"
  location             = "East US"
  storage_account_name = "stfuncpython"
  
  service_plan_name = "asp-python-consumption"
  os_type           = "Linux"
  sku_name          = "Y1"
  
  function_app_name           = "func-processor-prod"
  functions_worker_runtime    = "python"
  functions_extension_version = "~4"
  
  application_stack = {
    python_version = "3.11"
  }
  
  # Storage Queues para triggers
  storage_queues = {
    "orders-queue"    = {}
    "notifications"   = {}
  }
  
  app_settings = {
    "PYTHON_ISOLATE_WORKER_DEPENDENCIES" = "1"
    "AzureWebJobsFeatureFlags"           = "EnableWorkerIndexing"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### .NET Isolated Function (Elastic Premium)

```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"

  resource_group_name  = "rg-functions-prod"
  location             = "Brazil South"
  storage_account_name = "stfuncdotnet"
  
  # Elastic Premium Plan
  service_plan_name            = "asp-premium"
  os_type                      = "Linux"
  sku_name                     = "EP1"
  zone_balancing_enabled       = true
  maximum_elastic_worker_count = 20
  
  function_app_name           = "func-enterprise-prod"
  functions_worker_runtime    = "dotnet-isolated"
  functions_extension_version = "~4"
  
  application_stack = {
    dotnet_version              = "8.0"
    use_dotnet_isolated_runtime = true
  }
  
  # Premium features
  always_on                 = true
  pre_warmed_instance_count = 3
  app_scale_limit           = 100
  
  # VNet Integration
  vnet_integration_subnet_id = azurerm_subnet.functions.id
  vnet_route_all_enabled     = true
  
  # Managed Identity
  identity_type = "SystemAssigned"
  
  app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Production"
  }
  
  tags = {
    Environment = "production"
    Tier        = "premium"
  }
}
```

## Exemplo Completo (Production-Ready)

```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"

  # Resource Group
  resource_group_name = "rg-functions-prod"
  location            = "Brazil South"
  
  # Storage Account
  storage_account_name         = "stfuncprod123"
  storage_account_tier         = "Standard"
  storage_account_replication_type = "GRS"
  
  # Restringir acesso à Storage Account
  storage_default_action = "Deny"
  storage_subnet_ids     = [azurerm_subnet.functions.id]
  
  # Service Plan (Elastic Premium)
  service_plan_name            = "asp-func-premium-prod"
  os_type                      = "Linux"
  sku_name                     = "EP2"
  zone_balancing_enabled       = true
  maximum_elastic_worker_count = 30
  
  # Function App
  function_app_name              = "func-api-prod-unique"
  functions_worker_runtime       = "node"
  functions_extension_version    = "~4"
  https_only                     = true
  builtin_logging_enabled        = true
  public_network_access_enabled  = false  # Apenas VNet
  
  # Runtime Stack
  application_stack = {
    node_version = "20"
  }
  
  # Site Config
  always_on                        = true
  http2_enabled                    = true
  minimum_tls_version              = "1.2"
  runtime_scale_monitoring_enabled = true
  pre_warmed_instance_count        = 5
  app_scale_limit                  = 100
  health_check_path                = "/api/health"
  health_check_eviction_time       = 5
  
  # Managed Identity
  identity_type = "SystemAssigned"
  
  # Application Insights
  create_application_insights              = true
  application_insights_retention_days      = 90
  application_insights_sampling_percentage = 100
  
  # App Settings
  app_settings = {
    "NODE_ENV"                          = "production"
    "WEBSITE_NODE_DEFAULT_VERSION"      = "~20"
    "DATABASE_HOST"                     = module.postgresql.server_fqdn
    "COSMOS_DB_ENDPOINT"                = module.cosmos_db.endpoint
    "KEY_VAULT_URL"                     = module.key_vault.vault_uri
    "SERVICE_BUS_CONNECTION__fullyQualifiedNamespace" = "${module.service_bus.name}.servicebus.windows.net"
    "AzureWebJobsFeatureFlags"          = "EnableWorkerIndexing"
  }
  
  # Connection Strings
  connection_strings = [
    {
      name  = "SqlConnection"
      type  = "SQLAzure"
      value = "@Microsoft.KeyVault(SecretUri=${module.key_vault.vault_uri}secrets/sql-connection-string/)"
    }
  ]
  
  # CORS (para Azure Portal testing)
  cors_settings = {
    allowed_origins = [
      "https://portal.azure.com",
      "https://ms.portal.azure.com"
    ]
    support_credentials = false
  }
  
  # IP Restrictions (Defense in depth)
  ip_restrictions = [
    {
      name                      = "Allow-APIM"
      service_tag               = "ApiManagement"
      action                    = "Allow"
      priority                  = 100
    },
    {
      name                      = "Allow-VNet"
      virtual_network_subnet_id = azurerm_subnet.gateway.id
      action                    = "Allow"
      priority                  = 200
    }
  ]
  
  # VNet Integration
  vnet_integration_subnet_id = azurerm_subnet.functions.id
  vnet_route_all_enabled     = true
  
  # Storage Triggers
  storage_queues = {
    "orders-processing"    = {}
    "email-notifications" = {}
    "image-processing"    = {}
  }
  
  storage_containers = {
    "uploads" = {
      access_type = "private"
    }
    "processed" = {
      access_type = "private"
    }
  }
  
  # Deployment Slots
  deployment_slots = {
    "staging" = {
      app_settings = {
        "NODE_ENV" = "staging"
      }
    }
  }
  
  # Sticky Settings (não swapear entre slots)
  sticky_settings = {
    app_setting_names = [
      "NODE_ENV",
      "DATABASE_HOST"
    ]
  }
  
  # Logs
  app_service_logs = {
    disk_quota_mb         = 35
    retention_period_days = 7
  }
  
  tags = {
    Environment = "production"
    Project     = "api"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Dar permissões à Managed Identity
resource "azurerm_key_vault_access_policy" "function" {
  key_vault_id = module.key_vault.id
  tenant_id    = module.function_app.function_app_identity_tenant_id
  object_id    = module.function_app.function_app_identity_principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_role_assignment" "function_cosmos" {
  scope                = module.cosmos_db.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id         = module.function_app.function_app_identity_principal_id
}
```

## Configuração de Runtimes

### Node.js
```hcl
functions_worker_runtime = "node"
application_stack = {
  node_version = "20"  # 16, 18, 20
}
```

### Python
```hcl
functions_worker_runtime = "python"
application_stack = {
  python_version = "3.11"  # 3.8, 3.9, 3.10, 3.11
}
```

### .NET (Isolated)
```hcl
functions_worker_runtime = "dotnet-isolated"
application_stack = {
  dotnet_version              = "8.0"  # 6.0, 7.0, 8.0
  use_dotnet_isolated_runtime = true
}
```

### Java
```hcl
functions_worker_runtime = "java"
application_stack = {
  java_version = "17"  # 11, 17, 21
}
```

### PowerShell
```hcl
functions_worker_runtime = "powershell"
application_stack = {
  powershell_core_version = "7.2"  # 7.0, 7.2
}
```

### Docker (Custom Container)
```hcl
functions_worker_runtime = "custom"
application_stack = {
  docker = {
    registry_url = "https://myregistry.azurecr.io"
    image_name   = "myfunction"
    image_tag    = "latest"
  }
}
```

## Tipos de Triggers

### HTTP Trigger
```javascript
// function.json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
```

### Timer Trigger (CRON)
```javascript
{
  "bindings": [
    {
      "name": "myTimer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 */5 * * * *"  // A cada 5 minutos
    }
  ]
}
```

### Queue Trigger
```javascript
{
  "bindings": [
    {
      "name": "queueItem",
      "type": "queueTrigger",
      "direction": "in",
      "queueName": "orders-queue",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

### Blob Trigger
```javascript
{
  "bindings": [
    {
      "name": "inputBlob",
      "type": "blobTrigger",
      "direction": "in",
      "path": "uploads/{name}",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

## Managed Identity para Acessar Recursos

### Acessar Key Vault
```javascript
const { DefaultAzureCredential } = require("@azure/identity");
const { SecretClient } = require("@azure/keyvault-secrets");

const credential = new DefaultAzureCredential();
const vaultUrl = process.env.KEY_VAULT_URL;
const client = new SecretClient(vaultUrl, credential);

const secret = await client.getSecret("database-password");
console.log(secret.value);
```

### Acessar Cosmos DB
```javascript
const { CosmosClient } = require("@azure/cosmos");
const { DefaultAzureCredential } = require("@azure/identity");

const credential = new DefaultAzureCredential();
const endpoint = process.env.COSMOS_DB_ENDPOINT;

const client = new CosmosClient({
  endpoint,
  aadCredentials: credential
});
```

### Acessar Service Bus (Connection String-less)
```javascript
const { ServiceBusClient } = require("@azure/service-bus");
const { DefaultAzureCredential } = require("@azure/identity");

const credential = new DefaultAzureCredential();
const fullyQualifiedNamespace = process.env.SERVICE_BUS_CONNECTION__fullyQualifiedNamespace;

const serviceBusClient = new ServiceBusClient(fullyQualifiedNamespace, credential);
```

## VNet Integration

Para comunicação privada com recursos Azure:

```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"
  
  # ... outras configurações ...
  
  # VNet Integration
  vnet_integration_subnet_id = azurerm_subnet.functions.id
  vnet_route_all_enabled     = true
  
  # Desabilitar acesso público
  public_network_access_enabled = false
  
  # Storage Account privada
  storage_default_action = "Deny"
  storage_subnet_ids     = [azurerm_subnet.functions.id]
}
```

**Requisitos da Subnet:**
- Delegação: `Microsoft.Web/serverFarms`
- CIDR mínimo: /26 (64 IPs)
- Service Endpoints para Storage, SQL, etc.

## Deployment

### Via Azure CLI (Zip Deploy)
```bash
# Build e package
npm run build
zip -r function.zip .

# Deploy
az functionapp deployment source config-zip \
  -g rg-functions-prod \
  -n func-api-prod \
  --src function.zip
```

### Via Azure DevOps Pipeline
```yaml
- task: AzureFunctionApp@1
  inputs:
    azureSubscription: 'Azure-Prod'
    appType: 'functionAppLinux'
    appName: 'func-api-prod'
    package: '$(System.DefaultWorkingDirectory)/**/*.zip'
    deploymentMethod: 'zipDeploy'
```

### Via GitHub Actions
```yaml
- name: Deploy to Azure Functions
  uses: Azure/functions-action@v1
  with:
    app-name: func-api-prod
    package: ./output
    publish-profile: ${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
```

### Run From Package (Recomendado)
```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"
  
  # ... outras configurações ...
  
  run_from_package_url = "https://storage.blob.core.windows.net/deployments/function-v1.0.0.zip?sp=..."
}
```

## Durable Functions

Para workflows e orquestrações:

```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"
  
  # ... outras configurações ...
  
  app_settings = {
    "AzureWebJobsStorage"              = azurerm_storage_account.function.primary_connection_string
    "AzureFunctionsJobHost__extensions__durableTask__hubName" = "MyTaskHub"
  }
  
  # Premium ou Dedicated necessário para melhor performance
  sku_name = "EP1"
}
```

**Exemplo de Orchestrator (JavaScript):**
```javascript
const df = require("durable-functions");

module.exports = df.orchestrator(function* (context) {
  const outputs = [];
  
  outputs.push(yield context.df.callActivity("ProcessOrder", order));
  outputs.push(yield context.df.callActivity("SendEmail", customer));
  outputs.push(yield context.df.callActivity("UpdateInventory", items));
  
  return outputs;
});
```

## Monitoramento com Application Insights

```hcl
module "function_app" {
  source = "../../modules/compute/azure_functions"
  
  # ... outras configurações ...
  
  create_application_insights              = true
  application_insights_retention_days      = 90
  application_insights_sampling_percentage = 100
}
```

**Custom Telemetry (Node.js):**
```javascript
const appInsights = require("applicationinsights");
appInsights.setup().start();

const client = appInsights.defaultClient;

module.exports = async function (context, req) {
  client.trackEvent({ name: "OrderProcessed", properties: { orderId: req.body.id } });
  client.trackMetric({ name: "OrderValue", value: req.body.total });
  
  // Sua lógica aqui
};
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| resource_group_name | Nome do Resource Group | `string` | - | Sim |
| location | Localização Azure | `string` | - | Sim |
| storage_account_name | Nome da Storage Account | `string` | - | Sim |
| service_plan_name | Nome do Service Plan | `string` | - | Sim |
| os_type | Sistema operacional (Linux/Windows) | `string` | - | Sim |
| sku_name | SKU do plano (Y1, EP1, etc) | `string` | `"Y1"` | Não |
| function_app_name | Nome da Function App | `string` | - | Sim |
| functions_worker_runtime | Runtime da função | `string` | `"node"` | Não |
| application_stack | Configuração de runtime | `any` | `null` | Não |
| identity_type | Tipo de Managed Identity | `string` | `"SystemAssigned"` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| function_app_id | ID da Function App |
| function_app_name | Nome da Function App |
| function_app_default_hostname | Hostname padrão |
| function_app_url | URL completa HTTPS |
| function_app_identity_principal_id | Principal ID da Managed Identity |
| application_insights_instrumentation_key | Key do Application Insights |
| storage_account_name | Nome da Storage Account |

## Boas Práticas

### 1. **Segurança**
- ✅ Sempre use Managed Identity
- ✅ Armazene secrets no Key Vault
- ✅ Configure `https_only = true`
- ✅ Use `minimum_tls_version = "1.2"`
- ✅ Restrinja acesso com IP restrictions
- ✅ Use VNet integration para recursos privados
- ✅ Desabilite FTP: `ftps_state = "Disabled"`

### 2. **Performance**
- ✅ Use Elastic Premium para evitar cold starts
- ✅ Configure `pre_warmed_instance_count` adequadamente
- ✅ Implemente circuit breakers e retries
- ✅ Use `app_scale_limit` para controlar custos
- ✅ Habilite Application Insights para diagnósticos

### 3. **Custo**
- ✅ Use Consumption plan para workloads intermitentes
- ✅ Premium apenas quando necessário (cold start crítico)
- ✅ Configure timeouts apropriados
- ✅ Monitore execuções e otimize código
- ✅ Use Reserved Instances para Premium

### 4. **Desenvolvimento**
- ✅ Use deployment slots para staging
- ✅ Implemente health check endpoints
- ✅ Versionamento de código
- ✅ CI/CD automatizado
- ✅ Testes unitários e de integração

## Troubleshooting

### Cold Start muito alto
- **Solução**: Migrar para Elastic Premium com pre-warmed instances

### Function timeout
- **Consumption**: Máximo 10 minutos (configurável)
- **Premium/Dedicated**: Ilimitado (configurar timeout adequado)

### Erro: "Storage account not accessible"
- Verificar network rules da Storage Account
- Confirmar que Function App tem acesso (VNet ou public)

### Erro de autenticação ao acessar recursos
- Verificar Managed Identity configurada
- Confirmar RBAC/IAM permissions no recurso de destino
- Checar firewall do recurso de destino

## Referências

- [Azure Functions Documentation](https://learn.microsoft.com/azure/azure-functions/)
- [Functions Pricing](https://azure.microsoft.com/pricing/details/functions/)
- [Durable Functions](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview)
- [Best Practices](https://learn.microsoft.com/azure/azure-functions/functions-best-practices)
