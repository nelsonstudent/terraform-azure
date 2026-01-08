# Azure App Service Terraform Module

Módulo Terraform para provisionar e gerenciar Azure App Service (PaaS para hospedar aplicações web). Suporta tanto Linux quanto Windows, com configurações avançadas de segurança, scaling, networking e monitoramento.

## Funcionalidades

- ✅ Suporte para Linux e Windows
- ✅ Múltiplos runtimes (Node.js, .NET, Python, PHP, Java, Ruby, Go)
- ✅ Docker/Container support
- ✅ Managed Identity (System e User Assigned)
- ✅ VNet Integration
- ✅ Custom domains e SSL
- ✅ Deployment slots (staging, blue-green)
- ✅ Auto-scaling
- ✅ Health checks
- ✅ Backup automático
- ✅ IP restrictions e firewall
- ✅ CORS configuration
- ✅ Logs e diagnósticos

## Pré-requisitos

- Terraform >= 1.0
- Provider `hashicorp/azurerm` >= 3.0
- Resource Group existente
- Azure Subscription ativa

## SKUs Disponíveis

### Free Tier
- **F1**: Free, 1 GB RAM, 60 min/dia

### Shared Tier
- **D1**: Shared, 1 GB RAM

### Basic Tier (Produção básica)
- **B1**: 1 core, 1.75 GB RAM, 10 GB storage
- **B2**: 2 cores, 3.5 GB RAM, 10 GB storage
- **B3**: 4 cores, 7 GB RAM, 10 GB storage

### Standard Tier (Produção)
- **S1**: 1 core, 1.75 GB RAM, 50 GB storage, 5 slots
- **S2**: 2 cores, 3.5 GB RAM, 50 GB storage, 5 slots
- **S3**: 4 cores, 7 GB RAM, 50 GB storage, 5 slots

### Premium Tier (Alta performance)
- **P1v2/P1v3**: 1 core, 3.5/8 GB RAM, 250 GB storage, 20 slots
- **P2v2/P2v3**: 2 cores, 7/16 GB RAM, 250 GB storage, 20 slots
- **P3v2/P3v3**: 4 cores, 14/32 GB RAM, 250 GB storage, 20 slots

## Uso Básico

### Node.js Application (Linux)

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"

  resource_group_name = "rg-production"
  location            = "Brazil South"
  
  # Service Plan
  service_plan_name = "asp-myapp-prod"
  os_type           = "Linux"
  sku_name          = "B1"
  
  # App Service
  app_service_name = "app-myapp-prod"
  
  # Runtime Stack
  application_stack = {
    node_version = "20-lts"
  }
  
  # App Settings
  app_settings = {
    "NODE_ENV" = "production"
    "PORT"     = "8080"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### .NET Core Application (Linux)

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"

  resource_group_name = "rg-production"
  location            = "East US"
  
  service_plan_name = "asp-dotnet-prod"
  os_type           = "Linux"
  sku_name          = "S1"
  
  app_service_name = "app-dotnet-prod"
  
  application_stack = {
    dotnet_version = "8.0"
  }
  
  app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Production"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Docker Container Application

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"

  resource_group_name = "rg-production"
  location            = "Brazil South"
  
  service_plan_name = "asp-container-prod"
  os_type           = "Linux"
  sku_name          = "B2"
  
  app_service_name = "app-container-prod"
  
  # Docker Configuration
  application_stack = {
    docker_image_name        = "myapp:latest"
    docker_registry_url      = "https://myregistry.azurecr.io"
    docker_registry_username = var.acr_username
    docker_registry_password = var.acr_password
  }
  
  # Use Managed Identity para ACR
  container_registry_use_managed_identity = true
  identity_type                           = "SystemAssigned"
  
  tags = {
    Environment = "production"
  }
}
```

## Exemplo Completo com Todos os Recursos

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"

  # Resource Group
  resource_group_name = "rg-webapp-prod"
  location            = "Brazil South"
  
  # Service Plan
  service_plan_name            = "asp-webapp-prod"
  os_type                      = "Linux"
  sku_name                     = "P1v3"
  worker_count                 = 2
  zone_balancing_enabled       = true
  per_site_scaling_enabled     = false
  maximum_elastic_worker_count = 10
  
  # App Service
  app_service_name              = "app-webapp-prod-unique"
  https_only                    = true
  client_affinity_enabled       = false
  public_network_access_enabled = true
  
  # Runtime
  application_stack = {
    node_version = "20-lts"
  }
  
  # Site Config
  always_on                 = true
  ftps_state                = "Disabled"
  http2_enabled             = true
  minimum_tls_version       = "1.2"
  websockets_enabled        = true
  vnet_route_all_enabled    = true
  health_check_path         = "/health"
  health_check_eviction_time = 5
  
  # Managed Identity
  identity_type = "SystemAssigned"
  
  # App Settings
  app_settings = {
    "NODE_ENV"                        = "production"
    "WEBSITE_NODE_DEFAULT_VERSION"    = "20-lts"
    "PORT"                            = "8080"
    "DATABASE_HOST"                   = module.postgresql.server_fqdn
    "APPINSIGHTS_INSTRUMENTATIONKEY"  = module.app_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.app_insights.connection_string
  }
  
  # Connection Strings
  connection_strings = [
    {
      name  = "DefaultConnection"
      type  = "PostgreSQL"
      value = "Host=${module.postgresql.server_fqdn};Database=mydb;Username=admin;Password=${var.db_password}"
    }
  ]
  
  # CORS
  cors_settings = {
    allowed_origins = [
      "https://myapp.com",
      "https://www.myapp.com"
    ]
    support_credentials = true
  }
  
  # IP Restrictions (Whitelist)
  ip_restrictions = [
    {
      name       = "Allow Office"
      ip_address = "203.0.113.0/24"
      action     = "Allow"
      priority   = 100
    },
    {
      name                      = "Allow VNet"
      virtual_network_subnet_id = module.vnet.subnet_ids["backend"]
      action                    = "Allow"
      priority                  = 200
    }
  ]
  
  # Custom Domains
  custom_domains = {
    "primary" = {
      hostname  = "www.myapp.com"
      ssl_state = "SniEnabled"
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
  
  # VNet Integration
  vnet_integration_subnet_id = module.vnet.subnet_ids["app-integration"]
  
  # Backup
  backup_settings = {
    name                = "daily-backup"
    storage_account_url = "${module.storage.primary_blob_endpoint}${module.storage.container_name}${data.azurerm_storage_account_sas.backup.sas}"
    enabled             = true
    schedule = {
      frequency_interval       = 1
      frequency_unit           = "Day"
      keep_at_least_one_backup = true
      retention_period_days    = 30
    }
  }
  
  # Logs
  enable_logs              = true
  detailed_error_messages  = true
  failed_request_tracing   = true
  
  application_logs = {
    file_system_level = "Information"
    azure_blob_storage = {
      level             = "Information"
      sas_url           = module.storage.blob_sas_url
      retention_in_days = 30
    }
  }
  
  http_logs = {
    file_system = {
      retention_in_days = 7
      retention_in_mb   = 35
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "webapp"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

## Configuração de Runtimes

### Node.js (Linux)
```hcl
application_stack = {
  node_version = "20-lts"  # Opções: 16-lts, 18-lts, 20-lts
}
```

### Python (Linux)
```hcl
application_stack = {
  python_version = "3.11"  # Opções: 3.8, 3.9, 3.10, 3.11, 3.12
}
```

### PHP (Linux)
```hcl
application_stack = {
  php_version = "8.2"  # Opções: 8.0, 8.1, 8.2
}
```

### .NET (Linux)
```hcl
application_stack = {
  dotnet_version = "8.0"  # Opções: 6.0, 7.0, 8.0
}
```

### Java (Linux)
```hcl
application_stack = {
  java_server         = "TOMCAT"  # ou JAVA (embedded)
  java_server_version = "10.1"
  java_version        = "17"      # Opções: 11, 17, 21
}
```

### .NET (Windows)
```hcl
os_type = "Windows"

application_stack = {
  current_stack  = "dotnet"
  dotnet_version = "v8.0"
}
```

## VNet Integration

Para integração privada com recursos do Azure:

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"
  
  # ... outras configurações ...
  
  # VNet Integration
  vnet_integration_subnet_id = azurerm_subnet.app_integration.id
  vnet_route_all_enabled     = true
  
  # Desabilitar acesso público (opcional)
  public_network_access_enabled = false
  
  # IP Restrictions para permitir apenas VNet
  ip_restrictions = [
    {
      name                      = "Allow-VNet-Only"
      virtual_network_subnet_id = azurerm_subnet.gateway.id
      action                    = "Allow"
      priority                  = 100
    }
  ]
}
```

## Deployment Slots (Blue-Green Deployment)

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"
  
  # ... outras configurações ...
  
  deployment_slots = {
    "staging" = {
      app_settings = {
        "ENVIRONMENT" = "staging"
        "DEBUG"       = "true"
      }
    }
    "canary" = {
      app_settings = {
        "ENVIRONMENT" = "canary"
        "FEATURE_X"   = "enabled"
      }
    }
  }
}
```

**Swap de slots via Azure CLI:**
```bash
az webapp deployment slot swap \
  -g rg-production \
  -n app-myapp-prod \
  --slot staging \
  --target-slot production
```

## Health Checks

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"
  
  # ... outras configurações ...
  
  health_check_path         = "/api/health"
  health_check_eviction_time = 5  # minutos
  always_on                 = true
}
```

**Exemplo de endpoint /api/health:**
```javascript
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});
```

## Custom Domains e SSL

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"
  
  # ... outras configurações ...
  
  custom_domains = {
    "www" = {
      hostname  = "www.example.com"
      ssl_state = "SniEnabled"
    }
    "api" = {
      hostname  = "api.example.com"
      ssl_state = "SniEnabled"
    }
  }
}
```

**Passos adicionais:**
1. Configure DNS CNAME apontando para `app-name.azurewebsites.net`
2. Faça upload do certificado SSL ou use App Service Managed Certificate
3. Bind o certificado ao custom domain

## Managed Identity para Acessar Recursos

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"
  
  # ... outras configurações ...
  
  identity_type = "SystemAssigned"
}

# Dar permissão ao Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = module.app_service.app_service_identity_tenant_id
  object_id    = module.app_service.app_service_identity_principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}
```

**Acessar secrets no código (Node.js):**
```javascript
const { DefaultAzureCredential } = require("@azure/identity");
const { SecretClient } = require("@azure/keyvault-secrets");

const credential = new DefaultAzureCredential();
const client = new SecretClient("https://my-vault.vault.azure.net/", credential);

const secret = await client.getSecret("my-secret");
console.log(secret.value);
```

## Backup e Recovery

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"
  
  # ... outras configurações ...
  
  backup_settings = {
    name                = "daily-backup"
    storage_account_url = "https://storage.blob.core.windows.net/backups?sp=..."
    enabled             = true
    schedule = {
      frequency_interval       = 1
      frequency_unit           = "Day"  # ou "Hour"
      keep_at_least_one_backup = true
      retention_period_days    = 30
    }
  }
}
```

**Restore via Azure CLI:**
```bash
az webapp config backup restore \
  -g rg-production \
  -n app-myapp-prod \
  --backup-name daily-backup-20250114 \
  --container-url "https://storage.blob.core.windows.net/backups?sp=..."
```

## Logs e Diagnósticos

```hcl
module "app_service" {
  source = "../../modules/compute/app_service"
  
  # ... outras configurações ...
  
  enable_logs             = true
  detailed_error_messages = true
  failed_request_tracing  = true
  
  application_logs = {
    file_system_level = "Information"  # Error, Warning, Information, Verbose
  }
  
  http_logs = {
    file_system = {
      retention_in_days = 7
      retention_in_mb   = 35
    }
  }
}
```

**Ver logs em tempo real:**
```bash
az webapp log tail -g rg-production -n app-myapp-prod
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| resource_group_name | Nome do Resource Group | `string` | - | Sim |
| location | Localização Azure | `string` | - | Sim |
| service_plan_name | Nome do App Service Plan | `string` | - | Sim |
| os_type | Sistema operacional (Linux/Windows) | `string` | - | Sim |
| sku_name | SKU do plano | `string` | `"B1"` | Não |
| app_service_name | Nome do App Service | `string` | - | Sim |
| application_stack | Configuração de runtime | `any` | `null` | Não |
| app_settings | Variáveis de ambiente | `map(string)` | `{}` | Não |
| identity_type | Tipo de Managed Identity | `string` | `null` | Não |
| vnet_integration_subnet_id | Subnet para VNet integration | `string` | `null` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| app_service_id | ID do App Service |
| app_service_name | Nome do App Service |
| app_service_default_hostname | Hostname padrão (*.azurewebsites.net) |
| app_service_url | URL completa HTTPS |
| app_service_identity_principal_id | Principal ID da Managed Identity |
| app_service_outbound_ip_addresses | IPs de saída |

## Boas Práticas

### 1. **Segurança**
- ✅ Sempre use `https_only = true`
- ✅ Configure `minimum_tls_version = "1.2"`
- ✅ Use Managed Identity em vez de connection strings
- ✅ Armazene secrets no Azure Key Vault
- ✅ Configure IP restrictions para ambientes sensíveis
- ✅ Desabilite FTP: `ftps_state = "Disabled"`

### 2. **Performance**
- ✅ Use `always_on = true` em produção (B1+)
- ✅ Habilite HTTP/2: `http2_enabled = true`
- ✅ Configure health checks
- ✅ Use Premium tiers para workloads críticos
- ✅ Configure `zone_balancing_enabled = true` para HA

### 3. **Deployment**
- ✅ Use deployment slots para staging
- ✅ Configure build validation no pipeline
- ✅ Implemente blue-green deployments
- ✅ Use VNet integration para comunicação privada
- ✅ Configure backups automáticos

### 4. **Monitoramento**
- ✅ Integre com Application Insights
- ✅ Configure logs de diagnóstico
- ✅ Use health check paths
- ✅ Configure alertas para CPU/Memory/Response Time

### 5. **Custo**
- ✅ Use Basic tier para dev/test
- ✅ Standard/Premium apenas para produção
- ✅ Configure auto-scaling baseado em métricas
- ✅ Use Reserved Instances para economia
- ✅ Desligue ambientes de dev/test fora do horário

## Troubleshooting

### Erro: "The app service plan does not support zone redundancy"
- Zone balancing só está disponível em Premium tiers (P1v2+)

### Erro: "Always On is not supported for the current site mode"
- Always On não está disponível no Free tier (F1)

### App não inicia após deployment
- Verifique logs: `az webapp log tail`
- Confirme que `PORT` está correto nos app_settings
- Verifique se o runtime está correto

### Connection timeout para banco de dados
- Configure VNet Integration
- Adicione IPs de saída do App Service no firewall do banco

## Referências

- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [App Service Pricing](https://azure.microsoft.com/pricing/details/app-service/linux/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app)
- [App Service Best Practices](https://learn.microsoft.com/azure/app-service/app-service-best-practices)
