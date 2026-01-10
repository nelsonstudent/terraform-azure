# Módulo Terraform - Azure Key Vault

Este módulo Terraform provisiona um Azure Key Vault com suporte completo para secrets, keys, certificados, RBAC, Private Endpoints e configurações de diagnóstico.

## Características

- Provisionamento de Key Vault com SKU Standard ou Premium
- Suporte a RBAC e Access Policies
- Criação automática de secrets, keys e certificados
- Private Endpoint para acesso privado
- Network ACLs para controle de acesso
- Soft Delete e Purge Protection
- Diagnostic Settings integrados
- Gestão de contatos para alertas de certificados

## Uso Básico

```hcl
module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-app-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Secrets

```hcl
module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-app-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  enable_rbac_authorization = true
  
  secrets = {
    "database-connection-string" = {
      value        = "Server=myserver.database.windows.net;Database=mydb;User Id=admin;Password=P@ssw0rd!"
      content_type = "connection-string"
      tags = {
        Component = "Database"
      }
    }
    "api-key" = {
      value        = "sk-1234567890abcdef"
      content_type = "api-key"
    }
    "storage-account-key" = {
      value = azurerm_storage_account.main.primary_access_key
    }
  }

  tags = {
    Environment = "Production"
    Project     = "MyApp"
  }
}
```

## Exemplo com Access Policies (Legado)

```hcl
data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-app-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  enable_rbac_authorization = false
  
  access_policies = [
    {
      object_id = data.azurerm_client_config.current.object_id
      key_permissions = [
        "Get", "List", "Create", "Delete", "Update", "Recover", "Backup", "Restore"
      ]
      secret_permissions = [
        "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
      ]
      certificate_permissions = [
        "Get", "List", "Create", "Delete", "Update", "Import"
      ]
    },
    {
      object_id = azurerm_app_service.main.identity[0].principal_id
      secret_permissions = [
        "Get", "List"
      ]
    }
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Private Endpoint

```hcl
module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-app-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  public_network_access_enabled = false
  
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [
      azurerm_subnet.app.id
    ]
  }
  
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = azurerm_subnet.private_endpoints.id
  private_dns_zone_ids = [
    azurerm_private_dns_zone.key_vault.id
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Keys Criptográficas

```hcl
module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-app-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name                  = "premium"
  enable_rbac_authorization = true
  
  keys = {
    "storage-encryption-key" = {
      key_type = "RSA"
      key_size = 2048
      key_opts = ["encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"]
    }
    "app-signing-key" = {
      key_type = "EC"
      curve    = "P-256"
      key_opts = ["sign", "verify"]
    }
    "database-key" = {
      key_type        = "RSA"
      key_size        = 4096
      key_opts        = ["encrypt", "decrypt"]
      expiration_date = "2025-12-31T23:59:59Z"
    }
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Certificados

```hcl
module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-app-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  contact_email = "security@company.com"
  
  certificates = {
    "app-certificate" = {
      policy = {
        issuer_parameters = {
          name = "Self"
        }
        key_properties = {
          exportable = true
          key_size   = 2048
          key_type   = "RSA"
          reuse_key  = true
        }
        secret_properties = {
          content_type = "application/x-pkcs12"
        }
        x509_certificate_properties = {
          key_usage = [
            "cRLSign",
            "dataEncipherment",
            "digitalSignature",
            "keyAgreement",
            "keyCertSign",
            "keyEncipherment"
          ]
          subject            = "CN=app.company.com"
          validity_in_months = 12
          subject_alternative_names = {
            dns_names = ["app.company.com", "www.app.company.com"]
          }
        }
        lifetime_action = [
          {
            action = {
              action_type = "AutoRenew"
            }
            trigger = {
              days_before_expiry = 30
            }
          }
        ]
      }
    }
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Diagnostic Settings

```hcl
module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-app-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  diagnostic_settings = {
    enabled                    = true
    log_analytics_workspace_id = module.log_analytics.id
    
    logs = [
      {
        category = "AuditEvent"
        enabled  = true
      },
      {
        category = "AzurePolicyEvaluationDetails"
        enabled  = true
      }
    ]
    
    metrics = [
      {
        category = "AllMetrics"
        enabled  = true
      }
    ]
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo Completo

```hcl
data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-prod-myapp-001"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  # SKU Premium para HSM
  sku_name = "premium"
  
  # Segurança
  enable_rbac_authorization       = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90
  public_network_access_enabled   = false
  
  # Habilitar para deployments
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  
  # Network ACLs
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules = [
      "203.0.113.0/24",
      "198.51.100.0/24"
    ]
    virtual_network_subnet_ids = [
      azurerm_subnet.app.id,
      azurerm_subnet.devops.id
    ]
  }
  
  # Private Endpoint
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = azurerm_subnet.private_endpoints.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.key_vault.id]
  
  # Secrets
  secrets = {
    "sql-connection-string" = {
      value        = module.sql_database.connection_string
      content_type = "connection-string"
    }
    "storage-key" = {
      value = module.storage_account.primary_key
    }
    "app-insights-key" = {
      value = module.application_insights.instrumentation_key
    }
  }
  
  # Keys
  keys = {
    "storage-encryption" = {
      key_type = "RSA"
      key_size = 4096
      key_opts = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]
    }
  }
  
  # Diagnostic Settings
  diagnostic_settings = {
    enabled                    = true
    log_analytics_workspace_id = module.log_analytics.id
    logs = [
      { category = "AuditEvent", enabled = true },
      { category = "AzurePolicyEvaluationDetails", enabled = true }
    ]
    metrics = [
      { category = "AllMetrics", enabled = true }
    ]
  }
  
  contact_email = "security-team@company.com"

  tags = {
    Environment = "Production"
    Project     = "MyApp"
    CostCenter  = "Security"
    Compliance  = "PCI-DSS"
    ManagedBy   = "Terraform"
  }
}

# Exemplo de uso dos outputs
output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "database_secret_id" {
  value     = module.key_vault.secret_ids["sql-connection-string"]
  sensitive = true
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| name | Nome do Key Vault (3-24 caracteres) | `string` | n/a | sim |
| location | Localização do recurso Azure | `string` | n/a | sim |
| resource_group_name | Nome do Resource Group | `string` | n/a | sim |
| tenant_id | Azure AD Tenant ID | `string` | n/a | sim |
| sku_name | SKU (standard/premium) | `string` | `"standard"` | não |
| enable_rbac_authorization | Usar RBAC | `bool` | `true` | não |
| purge_protection_enabled | Proteção contra purge | `bool` | `true` | não |
| soft_delete_retention_days | Dias de retenção (7-90) | `number` | `90` | não |
| enabled_for_deployment | Habilitar para VMs | `bool` | `false` | não |
| enabled_for_disk_encryption | Habilitar para discos | `bool` | `false` | não |
| enabled_for_template_deployment | Habilitar para ARM | `bool` | `false` | não |
| public_network_access_enabled | Acesso público | `bool` | `true` | não |
| network_acls | Network ACLs | `object` | ver abaixo | não |
| access_policies | Access policies (legado) | `list(object)` | `[]` | não |
| secrets | Secrets para criar | `map(object)` | `{}` | não |
| keys | Keys para criar | `map(object)` | `{}` | não |
| certificates | Certificados para criar | `map(object)` | `{}` | não |
| private_endpoint_enabled | Habilitar Private Endpoint | `bool` | `false` | não |
| private_endpoint_subnet_id | Subnet ID para PE | `string` | `null` | não |
| private_dns_zone_ids | DNS Zone IDs | `list(string)` | `[]` | não |
| diagnostic_settings | Configurações de diagnóstico | `object` | ver abaixo | não |
| contact_email | Email para certificados | `string` | `null` | não |
| tags | Tags do recurso | `map(string)` | `{}` | não |

### Network ACLs Padrão

```hcl
{
  bypass         = "AzureServices"
  default_action = "Deny"
  ip_rules       = []
  virtual_network_subnet_ids = []
}
```

### Diagnostic Settings Padrão

```hcl
{
  enabled = false
}
```

## Outputs

| Nome | Descrição | Sensível |
|------|-----------|----------|
| id | ID do Key Vault | não |
| name | Nome do Key Vault | não |
| vault_uri | URI do Key Vault | não |
| location | Localização | não |
| resource_group_name | Resource Group | não |
| tenant_id | Tenant ID | não |
| sku_name | SKU configurado | não |
| purge_protection_enabled | Status purge protection | não |
| soft_delete_retention_days | Dias de retenção | não |
| enable_rbac_authorization | Status RBAC | não |
| secrets | Map de secrets | não |
| secret_ids | IDs dos secrets | não |
| secret_versions | Versões dos secrets | não |
| keys | Map de keys | não |
| key_ids | IDs das keys | não |
| certificates | Map de certificados | não |
| certificate_ids | IDs dos certificados | não |
| certificate_thumbprints | Thumbprints | não |
| private_endpoint_id | ID do Private Endpoint | não |
| private_endpoint_ip | IP privado | não |
| diagnostic_setting_id | ID do diagnostic setting | não |
| network_acls | Network ACLs | não |
| resource | Objeto completo | sim |

## SKU - Standard vs Premium

### Standard
- Armazenamento baseado em software
- Adequado para maioria dos casos
- Menor custo

### Premium
- Suporte a HSM (Hardware Security Module)
- Requerido para chaves protegidas por HSM
- Compliance avançado (FIPS 140-2 Level 2)
- Maior custo

## RBAC vs Access Policies

### RBAC (Recomendado)
```hcl
enable_rbac_authorization = true

# Atribuir role via Azure CLI ou portal
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee <principal-id> \
  --scope <key-vault-id>
```

**Roles comuns:**
- Key Vault Administrator
- Key Vault Secrets Officer
- Key Vault Secrets User
- Key Vault Crypto Officer
- Key Vault Crypto User
- Key Vault Certificates Officer
- Key Vault Reader

### Access Policies (Legado)
```hcl
enable_rbac_authorization = false

access_policies = [
  {
    object_id = "..."
    secret_permissions = ["Get", "List"]
  }
]
```

## Tipos de Keys

### RSA
```hcl
key_type = "RSA"
key_size = 2048  # ou 3072, 4096
key_opts = ["encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"]
```

### EC (Elliptic Curve)
```hcl
key_type = "EC"
curve    = "P-256"  # P-256, P-384, P-521, P-256K
key_opts = ["sign", "verify"]
```

### RSA-HSM / EC-HSM
```hcl
key_type = "RSA-HSM"  # Requer SKU Premium
key_size = 2048
```

## Integração com Aplicações

### Azure CLI
```bash
# Obter secret
az keyvault secret show \
  --vault-name kv-prod-app-001 \
  --name database-connection-string \
  --query value -o tsv

# Definir secret
az keyvault secret set \
  --vault-name kv-prod-app-001 \
  --name api-key \
  --value "my-secret-value"
```

### .NET
```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var client = new SecretClient(
    new Uri("https://kv-prod-app-001.vault.azure.net/"),
    new DefaultAzureCredential()
);

KeyVaultSecret secret = await client.GetSecretAsync("database-connection-string");
string connectionString = secret.Value;
```

### Python
```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(
    vault_url="https://kv-prod-app-001.vault.azure.net/",
    credential=credential
)

secret = client.get_secret("database-connection-string")
connection_string = secret.value
```

### Node.js
```javascript
const { SecretClient } = require("@azure/keyvault-secrets");
const { DefaultAzureCredential } = require("@azure/identity");

const credential = new DefaultAzureCredential();
const client = new SecretClient(
  "https://kv-prod-app-001.vault.azure.net/",
  credential
);

const secret = await client.getSecret("database-connection-string");
const connectionString = secret.value;
```

## Soft Delete e Purge Protection

### Soft Delete
- Ativado por padrão
- Retenção configurável (7-90 dias)
- Permite recuperação acidental

```bash
# Recuperar Key Vault deletado
az keyvault recover --name kv-prod-app-001
```

### Purge Protection
- Previne exclusão permanente durante o período de retenção
- Recomendado para produção
- **Não pode ser desabilitado após ativado**

## Monitoramento e Auditoria

### Logs Disponíveis
- **AuditEvent**: Todas operações no Key Vault
- **AzurePolicyEvaluationDetails**: Avaliações de políticas

### Métricas
- Disponibilidade da API
- Latência da API
- Total de hits da API
- Erros da API

### Alertas Recomendados
```hcl
# Via Azure Monitor
- Falhas de autenticação
- Acesso a secrets específicos
- Modificações em keys
- Certificados próximos ao vencimento
```

## Segurança e Compliance

### Best Practices

1. **Sempre use RBAC** ao invés de Access Policies
2. **Habilite Purge Protection** em produção
3. **Configure Network ACLs** para restringir acesso
4. **Use Private Endpoints** sempre que possível
5. **Habilite Diagnostic Logs** para auditoria
6. **Rotacione secrets regularmente**
7. **Use Managed Identities** para autenticação
8. **Configure alertas** para operações sensíveis

### Compliance
- **GDPR**: IP masking, audit logs
- **PCI-DSS**: Key encryption, access control
- **HIPAA**: Encryption at rest, audit trails
- **SOC 2**: Access policies, monitoring

## Limitações

- Nome do Key Vault deve ser único globalmente
- Máximo 25 tags por recurso
- Soft delete não pode ser desabilitado
- Purge protection não pode ser desabilitado após ativado
- Limite de 5000 operações por 10 segundos por vault

## Troubleshooting

### Erro: "Forbidden"
- Verifique RBAC ou Access Policies
- Confirme que o principal tem as permissões necessárias

### Erro: "VaultNotFound"
- Verifique se o nome está correto
- Confirme que o Key Vault não está em soft-delete

### Erro: "Network rule violation"
- Verifique Network ACLs
- Adicione seu IP às regras permitidas

### Recuperar Key Vault deletado
```bash
az keyvault list-deleted
az keyvault recover --name <vault-name> --resource-group <rg-name>
```

## Custo Estimado

### Standard
- ~$0.03 por 10.000 transações
- Secrets: incluído
- Keys: incluído
- Certificados: $3/mês por certificado renovado

### Premium
- ~$0.03 por 10.000 transações
- HSM protected keys: ~$5/mês por key
- Tudo mais igual ao Standard

## Recursos Relacionados

- `azurerm_private_dns_zone` para Private Link
- `azurerm_log_analytics_workspace` para logs
- `azurerm_monitor_action_group` para alertas
- `azurerm_role_assignment` para RBAC

## Referências

- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)
- [Key Vault Best Practices](https://docs.microsoft.com/azure/key-vault/general/best-practices)