# Azure Container Apps Terraform Module

Módulo Terraform para provisionar e gerenciar Azure Container Apps (serverless containers). Suporta múltiplos containers, auto-scaling baseado em KEDA, Dapr para microsserviços, VNet integration e deployment sem downtime.

## Funcionalidades

- ✅ Serverless containers com scaling automático (0 a N réplicas)
- ✅ Múltiplos containers por app
- ✅ Init containers
- ✅ Health probes (liveness, readiness, startup)
- ✅ KEDA-based scaling (HTTP, TCP, Queue, custom)
- ✅ Dapr integration (service invocation, pub/sub, state management)
- ✅ Blue-green e canary deployments
- ✅ VNet integration e internal load balancer
- ✅ Custom domains e SSL
- ✅ Managed Identity
- ✅ Persistent volumes (Azure Files)
- ✅ Zone redundancy

## Pré-requisitos

- Terraform >= 1.0
- Provider `hashicorp/azurerm` >= 3.0
- Resource Group existente
- Log Analytics Workspace (criado automaticamente ou existente)

## Planos de Workload

### Consumption (Padrão)
- **CPU**: 0.25 a 4 vCPUs
- **Memória**: 0.5Gi a 8Gi
- **Custo**: Pay-per-use (vCPU-second e GiB-second)
- **Scale**: 0 a 30 réplicas por app
- **Uso**: Workloads com tráfego variável

### Dedicated (D4, D8, D16, D32)
- **D4**: 4 vCPUs, 16 GiB RAM
- **D8**: 8 vCPUs, 32 GiB RAM
- **D16**: 16 vCPUs, 64 GiB RAM
- **D32**: 32 vCPUs, 128 GiB RAM
- **Custo**: Por hora de node
- **Uso**: Workloads intensivos em CPU

### Dedicated (E4, E8, E16, E32)
- **Foco**: Alta memória
- **Uso**: Workloads intensivos em memória

## Uso Básico

### Container App Simples (HTTP)

```hcl
module "container_app" {
  source = "../../modules/compute/container_apps"

  resource_group_name = "rg-containers-prod"
  location            = "Brazil South"
  
  # Environment
  environment_name                = "cae-prod"
  create_log_analytics_workspace  = true
  log_analytics_workspace_name    = "log-containerapp-prod"
  
  # Container App
  container_app_name = "ca-api-prod"
  revision_mode      = "Single"
  
  # Scaling
  min_replicas = 0
  max_replicas = 10
  
  # Container
  containers = [
    {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
      env = [
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
    }
  ]
  
  # Ingress
  ingress_enabled          = true
  ingress_external_enabled = true
  ingress_target_port      = 80
  ingress_transport        = "auto"
  
  tags = {
    Environment = "production"
  }
}
```

### Container App com Azure Container Registry

```hcl
module "container_app" {
  source = "../../modules/compute/container_apps"

  resource_group_name = "rg-containers-prod"
  location            = "East US"
  
  environment_name = "cae-prod"
  container_app_name = "ca-webapp-prod"
  
  min_replicas = 1
  max_replicas = 20
  
  containers = [
    {
      name   = "webapp"
      image  = "myregistry.azurecr.io/webapp:latest"
      cpu    = 1.0
      memory = "2Gi"
      env = [
        {
          name        = "DATABASE_PASSWORD"
          secret_name = "db-password"
        }
      ]
    }
  ]
  
  # Secrets
  secrets = [
    {
      name  = "db-password"
      value = var.database_password
    },
    {
      name  = "acr-password"
      value = var.acr_password
    }
  ]
  
  # Registry Authentication
  registries = [
    {
      server               = "myregistry.azurecr.io"
      username             = "myregistry"
      password_secret_name = "acr-password"
    }
  ]
  
  # Ingress
  ingress_enabled          = true
  ingress_external_enabled = true
  ingress_target_port      = 8080
  
  # Managed Identity (recomendado para ACR)
  identity_type = "SystemAssigned"
  
  tags = {
    Environment = "production"
  }
}
```

### Container App com Health Probes

```hcl
module "container_app" {
  source = "../../modules/compute/container_apps"

  resource_group_name = "rg-containers-prod"
  location            = "Brazil South"
  
  environment_name   = "cae-prod"
  container_app_name = "ca-api-health"
  
  min_replicas = 2
  max_replicas = 15
  
  containers = [
    {
      name   = "api"
      image  = "myregistry.azurecr.io/api:v1.0.0"
      cpu    = 0.5
      memory = "1Gi"
      
      # Liveness Probe
      liveness_probe = {
        transport                = "HTTP"
        port                     = 8080
        path                     = "/health/live"
        initial_delay            = 5
        interval_seconds         = 30
        timeout                  = 5
        failure_count_threshold  = 3
      }
      
      # Readiness Probe
      readiness_probe = {
        transport                = "HTTP"
        port                     = 8080
        path                     = "/health/ready"
        initial_delay            = 3
        interval_seconds         = 10
        timeout                  = 3
        failure_count_threshold  = 3
        success_count_threshold  = 1
      }
      
      # Startup Probe
      startup_probe = {
        transport                = "HTTP"
        port                     = 8080
        path                     = "/health/startup"
        initial_delay            = 0
        interval_seconds         = 5
        timeout                  = 3
        failure_count_threshold  = 30
      }
    }
  ]
  
  ingress_enabled          = true
  ingress_external_enabled = true
  ingress_target_port      = 8080
  
  tags = {
    Environment = "production"
  }
}
```

## Exemplo Completo (Production-Ready)

```hcl
module "container_app" {
  source = "../../modules/compute/container_apps"

  # Resource Group
  resource_group_name = "rg-containers-prod"
  location            = "Brazil South"
  
  # Log Analytics
  create_log_analytics_workspace = true
  log_analytics_workspace_name   = "log-containerapp-prod"
  log_analytics_retention_days   = 90
  
  # Environment
  environment_name               = "cae-prod-eastus"
  zone_redundancy_enabled        = true
  infrastructure_subnet_id       = azurerm_subnet.container_apps.id
  internal_load_balancer_enabled = false
  
  # Workload Profiles (Dedicated nodes)
  workload_profiles = [
    {
      name                  = "compute-optimized"
      workload_profile_type = "D8"
      minimum_count         = 2
      maximum_count         = 10
    }
  ]
  
  # Container App
  container_app_name        = "ca-api-prod"
  revision_mode             = "Multiple"  # Para blue-green deployment
  workload_profile_name     = "compute-optimized"
  
  # Scaling
  min_replicas = 2
  max_replicas = 30
  
  # Containers
  containers = [
    {
      name   = "api"
      image  = "myregistry.azurecr.io/api:v2.1.0"
      cpu    = 2.0
      memory = "4Gi"
      
      env = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "8080"
        },
        {
          name        = "DATABASE_URL"
          secret_name = "database-url"
        },
        {
          name        = "API_KEY"
          secret_name = "api-key"
        }
      ]
      
      liveness_probe = {
        transport                = "HTTP"
        port                     = 8080
        path                     = "/health/live"
        initial_delay            = 10
        interval_seconds         = 30
        timeout                  = 5
        failure_count_threshold  = 3
      }
      
      readiness_probe = {
        transport                = "HTTP"
        port                     = 8080
        path                     = "/health/ready"
        initial_delay            = 5
        interval_seconds         = 10
        timeout                  = 3
        failure_count_threshold  = 3
      }
      
      volume_mounts = [
        {
          name = "data"
          path = "/app/data"
        }
      ]
    },
    {
      name   = "sidecar-logger"
      image  = "fluent/fluent-bit:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      
      volume_mounts = [
        {
          name = "data"
          path = "/logs"
        }
      ]
    }
  ]
  
  # Init Container
  init_containers = [
    {
      name   = "db-migration"
      image  = "myregistry.azurecr.io/migrations:latest"
      cpu    = 0.5
      memory = "1Gi"
      env = [
        {
          name        = "DATABASE_URL"
          secret_name = "database-url"
        }
      ]
    }
  ]
  
  # Volumes
  volumes = [
    {
      name         = "data"
      storage_type = "AzureFile"
      storage_name = "shared-storage"
    }
  ]
  
  # Secrets
  secrets = [
    {
      name  = "database-url"
      value = "@Microsoft.KeyVault(SecretUri=${module.key_vault.vault_uri}secrets/database-url/)"
    },
    {
      name  = "api-key"
      value = var.api_key
    },
    {
      name  = "acr-password"
      value = var.acr_password
    }
  ]
  
  # Container Registry
  registries = [
    {
      server               = "myregistry.azurecr.io"
      identity             = azurerm_user_assigned_identity.acr.id
    }
  ]
  
  # Ingress
  ingress_enabled                = true
  ingress_external_enabled       = true
  ingress_target_port            = 8080
  ingress_transport              = "http2"
  ingress_allow_insecure_connections = false
  
  # Traffic Splitting (Blue-Green)
  ingress_traffic_weights = [
    {
      percentage      = 90
      revision_suffix = "blue"
      label           = "production"
    },
    {
      percentage      = 10
      revision_suffix = "green"
      label           = "canary"
    }
  ]
  
  # Custom Domain
  custom_domains = [
    {
      name                     = "api.example.com"
      certificate_binding_type = "SniEnabled"
      certificate_id           = azurerm_container_app_environment_certificate.main["api-cert"].id
    }
  ]
  
  # IP Restrictions
  ip_security_restrictions = [
    {
      name             = "allow-office"
      ip_address_range = "203.0.113.0/24"
      action           = "Allow"
      description      = "Allow office network"
    },
    {
      name             = "allow-api-gateway"
      ip_address_range = "${azurerm_public_ip.apim.ip_address}/32"
      action           = "Allow"
    }
  ]
  
  # HTTP Scale Rule
  http_scale_rules = [
    {
      name                = "http-scale"
      concurrent_requests = 50
    }
  ]
  
  # Queue Scale Rule
  azure_queue_scale_rules = [
    {
      name         = "queue-scale"
      queue_name   = "orders"
      queue_length = 10
      authentication = {
        secret_name       = "storage-connection"
        trigger_parameter = "connection"
      }
    }
  ]
  
  # Dapr
  dapr_enabled     = true
  dapr_app_id      = "api-service"
  dapr_app_port    = 8080
  dapr_app_protocol = "http"
  
  # Managed Identity
  identity_type = "SystemAssigned, UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.acr.id]
  
  tags = {
    Environment = "production"
    Project     = "ecommerce"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Environment Storage para volumes persistentes
module "container_app" {
  # ... configurações acima ...
  
  environment_storages = {
    "shared-storage" = {
      account_name = module.storage.name
      access_key   = module.storage.primary_access_key
      share_name   = "app-data"
      access_mode  = "ReadWrite"
    }
  }
}

# Dapr Components
module "container_app" {
  # ... configurações acima ...
  
  dapr_components = {
    "statestore" = {
      component_type = "state.azure.cosmosdb"
      version        = "v1"
      metadata = [
        {
          name  = "url"
          value = module.cosmos_db.endpoint
        },
        {
          name        = "masterKey"
          secret_name = "cosmos-key"
        },
        {
          name  = "database"
          value = "statedb"
        },
        {
          name  = "collection"
          value = "state"
        }
      ]
      secrets = [
        {
          name  = "cosmos-key"
          value = module.cosmos_db.primary_key
        }
      ]
    },
    "pubsub" = {
      component_type = "pubsub.azure.servicebus"
      version        = "v1"
      metadata = [
        {
          name        = "connectionString"
          secret_name = "servicebus-connection"
        }
      ]
      secrets = [
        {
          name  = "servicebus-connection"
          value = module.service_bus.primary_connection_string
        }
      ]
    }
  }
}
```

## Scaling Avançado

### HTTP-based Scaling
```hcl
http_scale_rules = [
  {
    name                = "http-requests"
    concurrent_requests = 100  # Scale quando > 100 requests/replica
  }
]
```

### Queue-based Scaling (Azure Storage Queue)
```hcl
azure_queue_scale_rules = [
  {
    name         = "orders-queue"
    queue_name   = "orders"
    queue_length = 5  # Scale quando > 5 mensagens/replica
    authentication = {
      secret_name       = "storage-connection"
      trigger_parameter = "connection"
    }
  }
]
```

### Custom KEDA Scaler (Service Bus)
```hcl
custom_scale_rules = [
  {
    name             = "servicebus-scale"
    custom_rule_type = "azure-servicebus"
    metadata = {
      queueName       = "orders"
      messageCount    = "10"
      namespace       = "myservicebus"
    }
    authentication = [
      {
        secret_name       = "servicebus-connection"
        trigger_parameter = "connection"
      }
    ]
  }
]
```

### Custom KEDA Scaler (Redis)
```hcl
custom_scale_rules = [
  {
    name             = "redis-list-scale"
    custom_rule_type = "redis"
    metadata = {
      address         = "redis.example.com:6379"
      listName        = "jobs"
      listLength      = "5"
      enableTLS       = "true"
    }
    authentication = [
      {
        secret_name       = "redis-password"
        trigger_parameter = "password"
      }
    ]
  }
]
```

## Dapr (Distributed Application Runtime)

### Service-to-Service Invocation
```javascript
// Chamar outro Container App via Dapr
const response = await fetch('http://localhost:3500/v1.0/invoke/order-service/method/create-order', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(order)
});
```

### Pub/Sub Messaging
```javascript
// Publicar mensagem
await fetch('http://localhost:3500/v1.0/publish/pubsub/orders', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ orderId: '123' })
});

// Subscrever (via endpoint da app)
app.post('/orders', (req, res) => {
  const order = req.body.data;
  console.log('Received order:', order);
  res.status(200).send();
});
```

### State Management
```javascript
// Salvar estado
await fetch('http://localhost:3500/v1.0/state/statestore', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify([{
    key: 'order-123',
    value: orderData
  }])
});

// Recuperar estado
const state = await fetch('http://localhost:3500/v1.0/state/statestore/order-123');
const data = await state.json();
```

## Blue-Green e Canary Deployments

### Traffic Splitting
```hcl
revision_mode = "Multiple"

ingress_traffic_weights = [
  {
    percentage      = 80
    revision_suffix = "stable"
    label           = "production"
  },
  {
    percentage      = 20
    revision_suffix = "canary"
    label           = "preview"
  }
]
```

**Testar canary:**
```bash
# Acesso via label
curl https://preview.ca-api-prod.nicegrass-123.brazilsouth.azurecontainerapps.io
```

**Promover canary para produção:**
```hcl
ingress_traffic_weights = [
  {
    percentage      = 100
    revision_suffix = "canary"
    label           = "production"
  }
]
```

## VNet Integration

```hcl
module "container_app" {
  source = "../../modules/compute/container_apps"
  
  # ... outras configurações ...
  
  # VNet Integration
  infrastructure_subnet_id       = azurerm_subnet.container_apps.id
  internal_load_balancer_enabled = true  # Load balancer interno
  
  # Ingress interno apenas
  ingress_enabled          = true
  ingress_external_enabled = false  # Apenas acessível via VNet
}
```

**Requisitos da Subnet:**
- CIDR mínimo: /23 (512 IPs)
- Delegação: `Microsoft.App/environments`
- Sem NSG ou Route Table associados

## Managed Identity com ACR

```hcl
# User Assigned Identity
resource "azurerm_user_assigned_identity" "acr" {
  name                = "id-containerapp-acr"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# ACR Role Assignment
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr.principal_id
}

# Container App com Managed Identity
module "container_app" {
  source = "../../modules/compute/container_apps"
  
  # ... outras configurações ...
  
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.acr.id]
  
  registries = [
    {
      server   = "myregistry.azurecr.io"
      identity = azurerm_user_assigned_identity.acr.id
    }
  ]
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| resource_group_name | Nome do Resource Group | `string` | - | Sim |
| location | Localização Azure | `string` | - | Sim |
| environment_name | Nome do Container Apps Environment | `string` | - | Sim |
| container_app_name | Nome do Container App | `string` | - | Sim |
| containers | Lista de containers | `list(object)` | - | Sim |
| min_replicas | Réplicas mínimas | `number` | `0` | Não |
| max_replicas | Réplicas máximas | `number` | `10` | Não |
| ingress_enabled | Habilitar ingress | `bool` | `true` | Não |
| ingress_target_port | Porta do container | `number` | `80` | Não |
| identity_type | Tipo de Managed Identity | `string` | `null` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| container_app_id | ID do Container App |
| container_app_fqdn | FQDN (URL) do app |
| container_app_url | URL completa HTTPS |
| container_app_identity_principal_id | Principal ID da Managed Identity |
| environment_id | ID do Environment |

## Boas Práticas

### 1. **Segurança**
- ✅ Use Managed Identity para ACR
- ✅ Armazene secrets no Key Vault com referências
- ✅ Configure `ingress_allow_insecure_connections = false`
- ✅ Use IP restrictions para limitar acesso
- ✅ VNet integration para comunicação privada

### 2. **Performance**
- ✅ Configure health probes apropriados
- ✅ Use init containers para tarefas de setup
- ✅ Configure `min_replicas >= 1` para evitar cold start
- ✅ Use Dedicated workload profiles para workloads intensivos
- ✅ Implemente circuit breakers e retries

### 3. **Escalabilidade**
- ✅ Configure scale rules baseadas em métricas reais
- ✅ Use Queue-based scaling para processamento assíncrono
- ✅ Configure `max_replicas` apropriadamente
- ✅ Monitore CPU e memória para ajustar requests

### 4. **Deployment**
- ✅ Use `revision_mode = "Multiple"` para blue-green
- ✅ Teste canary deployments antes de 100%
- ✅ Implemente rollback strategy
- ✅ Use tags/labels para organizar revisões

## Troubleshooting

### Container não inicia
- Verificar logs: `az containerapp logs show`
- Confirmar que a imagem existe no registry
- Validar secrets e variáveis de ambiente

### Scaling não funciona
- Verificar regras de scale configuradas
- Confirmar que métricas estão sendo coletadas
- Checar limites de `max_replicas`

### Erro de autenticação no ACR
- Confirmar Managed Identity configurada
- Verificar AcrPull role assignment
- Testar pull manual da imagem

### VNet integration falha
- Confirmar subnet com /23 ou maior
- Verificar delegação `Microsoft.App/environments`
- Remover NSG/Route Table da subnet

## Referências

- [Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [KEDA Scalers](https://keda.sh/docs/scalers/)
- [Dapr Documentation](https://docs.dapr.io/)
- [Container Apps Pricing](https://azure.microsoft.com/pricing/details/container-apps/)
