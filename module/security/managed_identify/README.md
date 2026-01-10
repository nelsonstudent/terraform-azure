# Módulo Terraform - Azure Managed Identity

Este módulo Terraform provisiona uma User-Assigned Managed Identity no Azure com configurações de role assignments, federated identity credentials e acesso simplificado a diversos serviços Azure.

## Características

- Provisionamento de User-Assigned Managed Identity
- Role assignments RBAC automatizados
- Federated Identity Credentials para Workload Identity
- Configuração simplificada de acesso a serviços Azure:
  - Key Vault
  - Storage Account
  - SQL Database
  - Container Registry (ACR)
  - AKS (Kubernetes)
  - App Configuration
  - Event Hub
  - Service Bus
  - Cognitive Services
- Output otimizado para integração com outros recursos

## Uso Básico

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-app-prod"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Role Assignments

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-app-prod"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  role_assignments = [
    {
      scope                = data.azurerm_subscription.current.id
      role_definition_name = "Reader"
      description          = "Read access to subscription"
    },
    {
      scope                = azurerm_resource_group.app.id
      role_definition_name = "Contributor"
      description          = "Contributor access to app resource group"
    }
  ]

  tags = {
    Environment = "Production"
    Application = "MyApp"
  }
}
```

## Exemplo com Acesso a Key Vault

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-app-prod"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  # Usando RBAC (recomendado)
  role_assignments = [
    {
      scope                = module.key_vault.id
      role_definition_name = "Key Vault Secrets User"
      description          = "Read secrets from Key Vault"
    }
  ]

  # OU usando Access Policies (legado)
  key_vault_access = {
    enabled      = true
    key_vault_id = module.key_vault.id
    secret_permissions = [
      "Get",
      "List"
    ]
    key_permissions = [
      "Get",
      "List",
      "Decrypt",
      "Encrypt"
    ]
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Storage Account

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-app-prod"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  storage_account_access = [
    {
      storage_account_id   = module.storage_account.id
      role_definition_name = "Storage Blob Data Contributor"
    },
    {
      storage_account_id   = module.storage_logs.id
      role_definition_name = "Storage Blob Data Reader"
    }
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Container Registry

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-aks-prod"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  container_registry_access = [
    {
      registry_id          = module.container_registry.id
      role_definition_name = "AcrPull"
    }
  ]

  aks_access = [
    {
      cluster_id           = module.aks.id
      role_definition_name = "Azure Kubernetes Service Cluster User Role"
    }
  ]

  tags = {
    Environment = "Production"
    Component   = "AKS"
  }
}
```

## Exemplo com Workload Identity (AKS)

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-aks-workload"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  # Federated Identity para Kubernetes Service Account
  federated_identity_credentials = [
    {
      name      = "aks-workload-identity"
      issuer    = module.aks.oidc_issuer_url
      subject   = "system:serviceaccount:default:my-app-sa"
      audiences = ["api://AzureADTokenExchange"]
    }
  ]

  # Acesso aos recursos necessários
  storage_account_access = [
    {
      storage_account_id   = module.storage.id
      role_definition_name = "Storage Blob Data Contributor"
    }
  ]

  key_vault_access = {
    enabled      = true
    key_vault_id = module.key_vault.id
    secret_permissions = ["Get", "List"]
  }

  tags = {
    Environment = "Production"
    Workload    = "AKS"
  }
}
```

## Exemplo com GitHub Actions (OIDC)

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-github-actions"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  # Federated Identity para GitHub Actions
  federated_identity_credentials = [
    {
      name      = "github-actions-main"
      issuer    = "https://token.actions.githubusercontent.com"
      subject   = "repo:myorg/myrepo:ref:refs/heads/main"
      audiences = ["api://AzureADTokenExchange"]
    },
    {
      name      = "github-actions-pr"
      issuer    = "https://token.actions.githubusercontent.com"
      subject   = "repo:myorg/myrepo:pull_request"
      audiences = ["api://AzureADTokenExchange"]
    }
  ]

  role_assignments = [
    {
      scope                = data.azurerm_subscription.current.id
      role_definition_name = "Contributor"
      description          = "Deploy resources via GitHub Actions"
    }
  ]

  tags = {
    Environment = "Production"
    Purpose     = "CI/CD"
  }
}
```

## Exemplo com SQL Database

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-app-prod"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  sql_database_access = [
    {
      sql_server_name     = "sql-prod-server"
      database_name       = "myappdb"
      resource_group_name = "rg-database-prod"
    }
  ]

  tags = {
    Environment = "Production"
  }
}

# Configurar no SQL Server
# CREATE USER [mi-app-prod] FROM EXTERNAL PROVIDER;
# ALTER ROLE db_datareader ADD MEMBER [mi-app-prod];
# ALTER ROLE db_datawriter ADD MEMBER [mi-app-prod];
```

## Exemplo Completo Multi-Serviço

```hcl
module "app_managed_identity" {
  source = "./modules/managed_identity"

  name                = "mi-webapp-prod"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  # Role assignments gerais
  role_assignments = [
    {
      scope                = azurerm_resource_group.app.id
      role_definition_name = "Reader"
      description          = "Read app resources"
    }
  ]

  # Key Vault
  key_vault_access = {
    enabled      = true
    key_vault_id = module.key_vault.id
    secret_permissions = ["Get", "List"]
    certificate_permissions = ["Get", "List"]
  }

  # Storage Accounts
  storage_account_access = [
    {
      storage_account_id   = module.storage_data.id
      role_definition_name = "Storage Blob Data Contributor"
    },
    {
      storage_account_id   = module.storage_logs.id
      role_definition_name = "Storage Blob Data Reader"
    }
  ]

  # Container Registry
  container_registry_access = [
    {
      registry_id          = module.acr.id
      role_definition_name = "AcrPull"
    }
  ]

  # App Configuration
  app_configuration_access = [
    {
      app_config_id        = module.app_config.id
      role_definition_name = "App Configuration Data Reader"
    }
  ]

  # Event Hub
  event_hub_access = [
    {
      event_hub_id         = module.event_hub.id
      role_definition_name = "Azure Event Hubs Data Sender"
    }
  ]

  # Service Bus
  service_bus_access = [
    {
      service_bus_id       = module.service_bus.id
      role_definition_name = "Azure Service Bus Data Sender"
    }
  ]

  # Cognitive Services
  cognitive_services_access = [
    {
      cognitive_account_id = module.cognitive.id
      role_definition_name = "Cognitive Services User"
    }
  ]

  # SQL Database
  sql_database_access = [
    {
      sql_server_name = "sql-prod-server"
      database_name   = "appdb"
    }
  ]

  tags = {
    Environment = "Production"
    Application = "WebApp"
    CostCenter  = "Engineering"
    ManagedBy   = "Terraform"
  }
}

# Usar a identity em um App Service
resource "azurerm_linux_web_app" "main" {
  name                = "app-prod"
  location            = "eastus"
  resource_group_name = "rg-app-prod"
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type         = "UserAssigned"
    identity_ids = [module.app_managed_identity.id]
  }

  app_settings = {
    "AZURE_CLIENT_ID" = module.app_managed_identity.client_id
  }
}
```

## Uso com AKS Workload Identity

### 1. Criar Managed Identity e Federated Credential

```hcl
module "workload_identity" {
  source = "./modules/managed_identity"

  name                = "mi-aks-app"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  federated_identity_credentials = [
    {
      name      = "aks-app-identity"
      issuer    = module.aks.oidc_issuer_url
      subject   = "system:serviceaccount:production:my-app"
      audiences = ["api://AzureADTokenExchange"]
    }
  ]

  storage_account_access = [
    {
      storage_account_id   = module.storage.id
      role_definition_name = "Storage Blob Data Contributor"
    }
  ]
}
```

### 2. Configurar ServiceAccount no Kubernetes

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: production
  annotations:
    azure.workload.identity/client-id: "${module.workload_identity.client_id}"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: my-app
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: AZURE_CLIENT_ID
          value: "${module.workload_identity.client_id}"
```

## Uso com GitHub Actions (OIDC)

### 1. Criar Managed Identity

```hcl
module "github_identity" {
  source = "./modules/managed_identity"

  name                = "mi-github-deploy"
  location            = "eastus"
  resource_group_name = "rg-identity-prod"

  federated_identity_credentials = [
    {
      name      = "github-main-branch"
      issuer    = "https://token.actions.githubusercontent.com"
      subject   = "repo:myorg/myrepo:ref:refs/heads/main"
      audiences = ["api://AzureADTokenExchange"]
    }
  ]

  role_assignments = [
    {
      scope                = data.azurerm_subscription.current.id
      role_definition_name = "Contributor"
    }
  ]
}
```

### 2. Usar no GitHub Actions Workflow

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy
        run: |
          az deployment group create \
            --resource-group rg-app-prod \
            --template-file main.bicep
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| name | Nome da Managed Identity | `string` | n/a | sim |
| location | Localização do recurso | `string` | n/a | sim |
| resource_group_name | Nome do Resource Group | `string` | n/a | sim |
| tags | Tags do recurso | `map(string)` | `{}` | não |
| role_assignments | Role assignments RBAC | `list(object)` | `[]` | não |
| federated_identity_credentials | Federated credentials | `list(object)` | `[]` | não |
| key_vault_access | Acesso ao Key Vault | `object` | ver abaixo | não |
| storage_account_access | Acesso a Storage Accounts | `list(object)` | `[]` | não |
| sql_database_access | Acesso a SQL Databases | `list(object)` | `[]` | não |
| container_registry_access | Acesso a Container Registries | `list(object)` | `[]` | não |
| aks_access | Acesso a clusters AKS | `list(object)` | `[]` | não |
| app_configuration_access | Acesso a App Configuration | `list(object)` | `[]` | não |
| event_hub_access | Acesso a Event Hubs | `list(object)` | `[]` | não |
| service_bus_access | Acesso a Service Bus | `list(object)` | `[]` | não |
| cognitive_services_access | Acesso a Cognitive Services | `list(object)` | `[]` | não |

### Key Vault Access Padrão

```hcl
{
  enabled = false
}
```

## Outputs

| Nome | Descrição |
|------|-----------|
| id | ID da Managed Identity |
| name | Nome da Managed Identity |
| principal_id | Principal ID (Object ID) |
| client_id | Client ID (Application ID) |
| tenant_id | Tenant ID |
| location | Localização |
| resource_group_name | Resource Group |
| role_assignment_ids | IDs dos role assignments |
| federated_identity_credentials | Federated credentials criados |
| key_vault_access_policy_id | ID do Key Vault access policy |
| storage_role_assignments | Role assignments de Storage |
| sql_role_assignments | Role assignments de SQL |
| acr_role_assignments | Role assignments de ACR |
| aks_role_assignments | Role assignments de AKS |
| app_config_role_assignments | Role assignments de App Config |
| event_hub_role_assignments | Role assignments de Event Hub |
| service_bus_role_assignments | Role assignments de Service Bus |
| cognitive_role_assignments | Role assignments de Cognitive |
| identity_block | Bloco para usar em recursos |
| resource | Objeto completo |

## User-Assigned vs System-Assigned Identity

### User-Assigned (Este Módulo)
✅ Pode ser compartilhada entre recursos  
✅ Ciclo de vida independente do recurso  
✅ Ideal para múltiplos recursos com mesmas permissões  
✅ Melhor para CI/CD e automação  

### System-Assigned
✅ Automaticamente vinculada ao recurso  
✅ Excluída quando o recurso é excluído  
✅ Mais simples para recursos únicos  
❌ Não pode ser compartilhada  

## Roles RBAC Comuns

### Storage
- **Storage Blob Data Reader** - Ler blobs
- **Storage Blob Data Contributor** - Ler/escrever blobs
- **Storage Blob Data Owner** - Controle total
- **Storage Queue Data Contributor** - Filas
- **Storage Table Data Contributor** - Tabelas

### Key Vault
- **Key Vault Administrator** - Controle total
- **Key Vault Secrets User** - Ler secrets
- **Key Vault Secrets Officer** - Gerenciar secrets
- **Key Vault Crypto User** - Usar keys para crypto
- **Key Vault Certificates Officer** - Gerenciar certificados

### Container Registry
- **AcrPull** - Pull de imagens
- **AcrPush** - Push de imagens
- **AcrDelete** - Deletar imagens

### SQL Database
- **SQL DB Contributor** - Gerenciar databases
- **SQL Security Manager** - Gerenciar segurança

### AKS
- **Azure Kubernetes Service Cluster User Role** - Acesso ao cluster
- **Azure Kubernetes Service RBAC Cluster Admin** - Admin RBAC

### Cognitive Services
- **Cognitive Services User** - Usar APIs
- **Cognitive Services Contributor** - Gerenciar recursos

### Subscription/Resource Group
- **Reader** - Ler recursos
- **Contributor** - Gerenciar recursos (exceto permissões)
- **Owner** - Controle total

## Integração com Aplicações

### .NET / C#

```csharp
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Security.KeyVault.Secrets;

// Configurar DefaultAzureCredential
var credential = new DefaultAzureCredential(
    new DefaultAzureCredentialOptions
    {
        ManagedIdentityClientId = "<CLIENT_ID>"
    }
);

// Storage Blob
var blobClient = new BlobServiceClient(
    new Uri("https://mystorageaccount.blob.core.windows.net"),
    credential
);

// Key Vault
var secretClient = new SecretClient(
    new Uri("https://mykeyvault.vault.azure.net"),
    credential
);

KeyVaultSecret secret = await secretClient.GetSecretAsync("my-secret");
```

### Python

```python
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient
from azure.keyvault.secrets import SecretClient

# Usar Managed Identity específica
credential = ManagedIdentityCredential(client_id="<CLIENT_ID>")

# Ou usar DefaultAzureCredential
credential = DefaultAzureCredential()

# Storage
blob_service = BlobServiceClient(
    account_url="https://mystorageaccount.blob.core.windows.net",
    credential=credential
)

# Key Vault
secret_client = SecretClient(
    vault_url="https://mykeyvault.vault.azure.net",
    credential=credential
)

secret = secret_client.get_secret("my-secret")
```

### Node.js

```javascript
const { DefaultAzureCredential, ManagedIdentityCredential } = require("@azure/identity");
const { BlobServiceClient } = require("@azure/storage-blob");
const { SecretClient } = require("@azure/keyvault-secrets");

// Usar Managed Identity específica
const credential = new ManagedIdentityCredential("<CLIENT_ID>");

// Storage
const blobServiceClient = new BlobServiceClient(
  "https://mystorageaccount.blob.core.windows.net",
  credential
);

// Key Vault
const secretClient = new SecretClient(
  "https://mykeyvault.vault.azure.net",
  credential
);

const secret = await secretClient.getSecret("my-secret");
```

### Go

```go
import (
    "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
    "github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
    "github.com/Azure/azure-sdk-for-go/sdk/keyvault/azsecrets"
)

// Managed Identity específica
cred, err := azidentity.NewManagedIdentityCredential(&azidentity.ManagedIdentityCredentialOptions{
    ID: azidentity.ClientID("<CLIENT_ID>"),
})

// Storage
client, err := azblob.NewClient(
    "https://mystorageaccount.blob.core.windows.net",
    cred,
    nil,
)

// Key Vault
secretClient, err := azsecrets.NewClient(
    "https://mykeyvault.vault.azure.net",
    cred,
    nil,
)
```

## Configuração em Recursos Azure

### App Service / Function App

```hcl
resource "azurerm_linux_web_app" "main" {
  # ...
  
  identity {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.id]
  }

  app_settings = {
    AZURE_CLIENT_ID = module.managed_identity.client_id
  }
}
```

### Container Apps

```hcl
resource "azurerm_container_app" "main" {
  # ...
  
  identity {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.id]
  }
}
```

### Virtual Machine

```hcl
resource "azurerm_linux_virtual_machine" "main" {
  # ...
  
  identity {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.id]
  }
}
```

### AKS

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  # ...
  
  kubelet_identity {
    client_id                 = module.managed_identity.client_id
    object_id                 = module.managed_identity.principal_id
    user_assigned_identity_id = module.managed_identity.id
  }
}
```

## Workload Identity - Fluxo de Autenticação

1. **Pod solicita token** ao Azure AD
2. **Azure AD verifica** o ServiceAccount e Federated Credential
3. **Token é emitido** se a configuração estiver correta
4. **Aplicação usa token** para acessar recursos Azure

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  Pod (AKS)  │ ──1──>  │  Azure AD    │ <──2──  │  Managed    │
│             │ <──3──  │              │         │  Identity   │
└─────────────┘         └──────────────┘         └─────────────┘
       │                                                 │
       └────────────────────4───────────────────────────┘
                    (Acessa recursos Azure)
```

## SQL Database com Managed Identity

### 1. Configurar no Terraform

```hcl
module "managed_identity" {
  source = "./modules/managed_identity"
  
  sql_database_access = [
    {
      sql_server_name = "sql-prod-server"
      database_name   = "myappdb"
    }
  ]
}
```

### 2. Configurar no SQL Server

```sql
-- Conectar como admin do SQL Server
CREATE USER [mi-app-prod] FROM EXTERNAL PROVIDER;

-- Conceder permissões
ALTER ROLE db_datareader ADD MEMBER [mi-app-prod];
ALTER ROLE db_datawriter ADD MEMBER [mi-app-prod];
ALTER ROLE db_ddladmin ADD MEMBER [mi-app-prod];
```

### 3. Connection String na Aplicação

```
Server=sql-prod-server.database.windows.net;
Database=myappdb;
Authentication=Active Directory Managed Identity;
User Id=<CLIENT_ID>;
```

## Troubleshooting

### Erro: "Failed to acquire token"
- Verifique se a Managed Identity está atribuída ao recurso
- Confirme que o CLIENT_ID está correto
- Verifique se as permissões RBAC foram aplicadas

### Erro: "Authorization failed"
- Verifique os role assignments
- Aguarde alguns minutos para propagação de permissões
- Use `az role assignment list` para verificar

### Erro: "Invalid issuer" (Federated Identity)
- Verifique se o OIDC issuer está correto
- Confirme que o subject está no formato correto
- Para AKS, certifique-se que Workload Identity está habilitado

### Verificar Permissões

```bash
# Listar role assignments
az role assignment list \
  --assignee <PRINCIPAL_ID> \
  --all

# Testar acesso
az login --identity --username <CLIENT_ID>
az storage blob list --account-name mystorageaccount --container-name mycontainer
```

## Best Practices

1. ✅ **Use User-Assigned Identity** para recursos que compartilham permissões
2. ✅ **Aplique princípio de menor privilégio** nas permissões
3. ✅ **Use Federated Identity** para CI/CD sem secrets
4. ✅ **Documente os acessos** via tags e descriptions
5. ✅ **Monitore uso** via Azure Monitor e diagnostic logs
6. ✅ **Separe identities por ambiente** (dev, staging, prod)
7. ✅ **Use conditions** em role assignments quando possível
8. ✅ **Revise permissões regularmente** 

## Segurança

- Managed Identities eliminam necessidade de credentials em código
- Tokens são gerenciados automaticamente pelo Azure AD
- Rotação automática sem intervenção
- Auditoria completa via Azure AD logs
- Sem risco de credentials vazadas

## Limitações

- Máximo de 1000 User-Assigned Identities por subscription
- Federated Credentials limitados a 20 por identity
- Role assignments podem levar alguns minutos para propagar
- Workload Identity requer AKS 1.23+

## Recursos Criados

- `azurerm_user_assigned_identity` - Identity principal
- `azurerm_role_assignment` - RBAC assignments
- `azurerm_federated_identity_credential` - Federated credentials
- `azurerm_key_vault_access_policy` - Key Vault access (opcional)

## Dependências

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Azure AD tenant
- RBAC habilitado nos recursos de destino

## Referências

- [Managed Identities Documentation](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Workload Identity](https://azure.github.io/azure-workload-identity/)
- [Azure RBAC](https://docs.microsoft.com/azure/role-based-access-control/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity)