# Módulo Terraform - Azure Policy

Este módulo Terraform provisiona e gerencia Azure Policies incluindo policy definitions, policy set definitions (initiatives), policy assignments, policy exemptions e remediation tasks.

## Características

- Criação de Custom Policy Definitions
- Policy Set Definitions (Initiatives)
- Policy Assignments com enforcement configurável
- Policy Exemptions com expiração
- Remediation Tasks automáticas
- Suporte a Managed Identity para policies
- Non-compliance messages customizadas
- Resource Selectors e Overrides
- Suporte para subscription e management group scope

## Tipos de Recursos Suportados

- **Policy Definition** - Define uma política customizada
- **Policy Set Definition** - Agrupa múltiplas policies (initiative)
- **Policy Assignment** - Atribui policy a um escopo
- **Policy Exemption** - Cria exceção para uma policy
- **Remediation Task** - Remedia recursos não conformes

## Uso Básico - Policy Definition

```hcl
module "policy_require_tag" {
  source = "./modules/azure_policy"

  policy_type  = "definition"
  name         = "require-environment-tag"
  display_name = "Require Environment Tag"
  description  = "Ensures all resources have an Environment tag"
  mode         = "Indexed"

  policy_rule = jsonencode({
    if = {
      field  = "tags['Environment']"
      exists = "false"
    }
    then = {
      effect = "deny"
    }
  })
}
```

## Exemplo - Policy com Parâmetros

```hcl
module "policy_allowed_locations" {
  source = "./modules/azure_policy"

  policy_type  = "definition"
  name         = "allowed-locations-custom"
  display_name = "Allowed Locations"
  description  = "Restrict resource deployment to specific locations"
  mode         = "Indexed"

  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed locations"
        description = "The list of allowed locations for resources"
        strongType  = "location"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('allowedLocations')]"
      }
    }
    then = {
      effect = "deny"
    }
  })
}
```

## Exemplo - Policy Set Definition (Initiative)

```hcl
module "initiative_security_baseline" {
  source = "./modules/azure_policy"

  policy_type  = "set_definition"
  name         = "security-baseline"
  display_name = "Security Baseline Initiative"
  description  = "Comprehensive security baseline for production environments"

  policy_definitions = [
    {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
      reference_id         = "RequireHTTPSStorage"
    },
    {
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b0f33259-77d7-4c9e-aac6-3aabcfae693c"
      reference_id         = "RequireStorageEncryption"
    },
    {
      policy_definition_id = module.policy_require_tag.policy_definition_id
      reference_id         = "RequireEnvironmentTag"
    }
  ]

  policy_definition_groups = [
    {
      name         = "Encryption"
      display_name = "Encryption Controls"
      category     = "Security"
    },
    {
      name         = "Tagging"
      display_name = "Tagging Standards"
      category     = "Governance"
    }
  ]
}
```

## Exemplo - Policy Assignment

```hcl
module "assign_require_tags" {
  source = "./modules/azure_policy"

  policy_type          = "assignment"
  name                 = "assign-require-tags"
  display_name         = "Assign Require Tags Policy"
  description          = "Enforces required tags on all resources"
  policy_definition_id = module.policy_require_tag.policy_definition_id
  scope                = data.azurerm_subscription.current.id
  enforce              = true

  non_compliance_messages = [
    {
      message = "Resources must have an Environment tag with valid values: Dev, Staging, or Production"
    }
  ]
}
```

## Exemplo - Assignment com Managed Identity

```hcl
module "assign_with_identity" {
  source = "./modules/azure_policy"

  policy_type          = "assignment"
  name                 = "assign-deploy-monitoring"
  display_name         = "Deploy Monitoring Agent"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/xxx"
  scope                = azurerm_resource_group.main.id
  enforce              = true
  
  # Managed Identity para deployIfNotExists/modify effects
  identity_type = "SystemAssigned"
  location      = "eastus"

  parameters = jsonencode({
    logAnalyticsWorkspace = {
      value = module.log_analytics.id
    }
  })
}

# Atribuir permissões à Managed Identity
resource "azurerm_role_assignment" "policy_identity" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = module.assign_with_identity.assignment_identity.principal_id
}
```

## Exemplo - Policy Exemption

```hcl
module "exemption_legacy_app" {
  source = "./modules/azure_policy"

  policy_type          = "exemption"
  name                 = "exemption-legacy-app"
  display_name         = "Legacy Application Exemption"
  description          = "Temporary exemption for legacy app migration"
  scope                = azurerm_resource_group.legacy.id
  policy_assignment_id = module.assign_require_tags.policy_assignment_id
  exemption_category   = "Mitigated"
  expires_on           = "2025-12-31T23:59:59Z"
}
```

## Exemplo - Assignment com Remediation

```hcl
module "assign_with_remediation" {
  source = "./modules/azure_policy"

  policy_type          = "assignment"
  name                 = "assign-tag-resources"
  display_name         = "Tag Resources Automatically"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/xxx"
  scope                = data.azurerm_subscription.current.id
  enforce              = true
  
  identity_type = "SystemAssigned"
  location      = "eastus"

  # Habilitar remediation automática
  create_remediation_task  = true
  resource_discovery_mode  = "ExistingNonCompliant"
  failure_percentage       = 10
  parallel_deployments     = 5
  resource_count           = 100

  parameters = jsonencode({
    tagName = {
      value = "CostCenter"
    }
    tagValue = {
      value = "Engineering"
    }
  })
}
```

## Exemplo - Policy com Resource Selectors

```hcl
module "assign_selective" {
  source = "./modules/azure_policy"

  policy_type          = "assignment"
  name                 = "assign-selective-encryption"
  display_name         = "Require Encryption (Selective)"
  policy_definition_id = module.policy_encryption.policy_definition_id
  scope                = data.azurerm_subscription.current.id
  enforce              = true

  # Aplicar apenas a recursos em localizações específicas
  resource_selectors = [
    {
      name = "production-regions"
      selectors = [
        {
          kind = "resourceLocation"
          in   = ["eastus", "westus2", "centralus"]
        }
      ]
    }
  ]

  # Excluir resource groups de desenvolvimento
  not_scopes = [
    "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/rg-dev-*"
  ]
}
```

## Exemplo Completo - Governança de Storage

```hcl
# 1. Policy Definition - Require HTTPS
module "policy_storage_https" {
  source = "./modules/azure_policy"

  policy_type  = "definition"
  name         = "require-storage-https"
  display_name = "Require HTTPS for Storage Accounts"
  mode         = "Indexed"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"
          notEquals = "true"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

# 2. Policy Definition - Require Encryption
module "policy_storage_encryption" {
  source = "./modules/azure_policy"

  policy_type  = "definition"
  name         = "require-storage-encryption"
  display_name = "Require Storage Encryption"
  mode         = "Indexed"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "Microsoft.Storage/storageAccounts/encryption.services.blob.enabled"
          notEquals = "true"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

# 3. Policy Definition - Require Private Endpoints
module "policy_storage_private" {
  source = "./modules/azure_policy"

  policy_type  = "definition"
  name         = "require-storage-private-endpoints"
  display_name = "Require Private Endpoints for Storage"
  mode         = "Indexed"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "Microsoft.Storage/storageAccounts/networkAcls.defaultAction"
          notEquals = "Deny"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}

# 4. Initiative - Storage Security Baseline
module "initiative_storage_security" {
  source = "./modules/azure_policy"

  policy_type  = "set_definition"
  name         = "storage-security-baseline"
  display_name = "Storage Security Baseline"
  description  = "Comprehensive security controls for storage accounts"

  policy_definitions = [
    {
      policy_definition_id = module.policy_storage_https.policy_definition_id
      reference_id         = "RequireHTTPS"
      policy_group_names   = ["Network"]
    },
    {
      policy_definition_id = module.policy_storage_encryption.policy_definition_id
      reference_id         = "RequireEncryption"
      policy_group_names   = ["Encryption"]
    },
    {
      policy_definition_id = module.policy_storage_private.policy_definition_id
      reference_id         = "RequirePrivateEndpoints"
      policy_group_names   = ["Network"]
    }
  ]

  policy_definition_groups = [
    {
      name         = "Network"
      display_name = "Network Security"
      category     = "Security"
    },
    {
      name         = "Encryption"
      display_name = "Encryption Controls"
      category     = "Security"
    }
  ]
}

# 5. Assign Initiative to Production RG
module "assign_storage_security_prod" {
  source = "./modules/azure_policy"

  policy_type          = "assignment"
  name                 = "assign-storage-security-prod"
  display_name         = "Storage Security - Production"
  description          = "Enforce storage security baseline in production"
  policy_definition_id = module.initiative_storage_security.policy_set_definition_id
  scope                = azurerm_resource_group.production.id
  enforce              = true

  non_compliance_messages = [
    {
      message                        = "Storage accounts must use HTTPS only"
      policy_definition_reference_id = "RequireHTTPS"
    },
    {
      message                        = "Storage accounts must have encryption enabled"
      policy_definition_reference_id = "RequireEncryption"
    },
    {
      message                        = "Storage accounts should use private endpoints"
      policy_definition_reference_id = "RequirePrivateEndpoints"
    }
  ]
}

# 6. Exemption for Legacy Storage
module "exemption_legacy_storage" {
  source = "./modules/azure_policy"

  policy_type          = "exemption"
  name                 = "exemption-legacy-storage"
  display_name         = "Legacy Storage Exemption"
  description          = "Temporary exemption during migration"
  scope                = "${azurerm_resource_group.production.id}/providers/Microsoft.Storage/storageAccounts/stlegacy001"
  policy_assignment_id = module.assign_storage_security_prod.policy_assignment_id
  exemption_category   = "Mitigated"
  expires_on           = "2025-06-30T23:59:59Z"
  
  # Exempt apenas a regra de private endpoints
  policy_definition_reference_ids = ["RequirePrivateEndpoints"]
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| policy_type | Tipo de policy | `string` | `"definition"` | não |
| name | Nome do recurso | `string` | n/a | sim |
| display_name | Nome de exibição | `string` | `name` | não |
| description | Descrição | `string` | `null` | não |
| mode | Modo da policy | `string` | `"All"` | não |
| policy_rule | Regra da policy (JSON) | `any` | `null` | condicional |
| parameters | Parâmetros (JSON) | `string` | `null` | não |
| metadata | Metadata (JSON) | `string` | `null` | não |
| management_group_id | ID do Management Group | `string` | `null` | não |
| policy_definitions | Policies na initiative | `list(object)` | `[]` | condicional |
| policy_definition_groups | Grupos da initiative | `list(object)` | `[]` | não |
| scope | Escopo do assignment | `string` | subscription | não |
| policy_definition_id | ID da policy para assign | `string` | `null` | condicional |
| enforce | Enforce ou audit | `bool` | `true` | não |
| location | Localização para identity | `string` | `null` | não |
| identity_type | Tipo de identity | `string` | `null` | não |
| identity_ids | IDs de identities | `list(string)` | `null` | não |
| not_scopes | Escopos excluídos | `list(string)` | `[]` | não |
| non_compliance_messages | Mensagens customizadas | `list(object)` | `[]` | não |
| overrides | Policy overrides | `list(object)` | `[]` | não |
| resource_selectors | Resource selectors | `list(object)` | `[]` | não |
| policy_assignment_id | ID para exemption | `string` | `null` | condicional |
| exemption_category | Categoria de exemption | `string` | `"Waiver"` | não |
| expires_on | Data de expiração | `string` | `null` | não |
| policy_definition_reference_ids | IDs para exemption | `list(string)` | `null` | não |
| create_remediation_task | Criar remediation | `bool` | `false` | não |
| resource_discovery_mode | Modo de descoberta | `string` | `"ExistingNonCompliant"` | não |
| failure_percentage | % de falha aceitável | `number` | `null` | não |
| parallel_deployments | Deployments paralelos | `number` | `null` | não |
| resource_count | Max recursos | `number` | `null` | não |
| tags | Tags | `map(string)` | `{}` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| id | ID do recurso criado |
| name | Nome do recurso |
| display_name | Nome de exibição |
| type | Tipo de recurso |
| policy_definition_id | ID da policy definition |
| policy_definition | Objeto da policy definition |
| policy_set_definition_id | ID da initiative |
| policy_set_definition | Objeto da initiative |
| policy_definition_count | Número de policies na initiative |
| policy_assignment_id | ID do assignment |
| policy_assignment | Objeto do assignment |
| assignment_scope | Escopo do assignment |
| assignment_identity | Managed Identity |
| enforce_mode | Status de enforcement |
| policy_exemption_id | ID da exemption |
| policy_exemption | Objeto da exemption |
| exemption_category | Categoria da exemption |
| exemption_expires_on | Data de expiração |
| remediation_task_id | ID da remediation |
| remediation_task | Objeto da remediation |
| remediation_enabled | Status de remediation |
| policy_summary | Resumo completo |

## Policy Modes

### All (Padrão)
Avalia todos os tipos de recursos e resource groups

### Indexed
Avalia apenas recursos que suportam tags e location (exclui resource groups, subscriptions, etc.)

### Specific Modes
- **Microsoft.KeyVault.Data** - Policies para Key Vault
- **Microsoft.Kubernetes.Data** - Policies para AKS/Kubernetes
- **Microsoft.Network.Data** - Policies para recursos de rede
- **Microsoft.ContainerService.Data** - Policies para containers

## Policy Effects

### Enforcement Effects
- **Deny** - Bloqueia criação/modificação
- **DenyAction** - Bloqueia ações específicas (POST, DELETE)
- **Audit** - Apenas registra não conformidade
- **Disabled** - Policy desabilitada

### Remediation Effects
- **DeployIfNotExists** - Deploy recursos se não existirem
- **Modify** - Modifica propriedades de recursos
- **Append** - Adiciona valores a arrays/objetos

### Other Effects
- **AuditIfNotExists** - Audit se recursos relacionados não existirem
- **Manual** - Requer validação manual

## Policy Rule Examples

### Deny Public IP Creation
```json
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Network/publicIPAddresses"
  },
  "then": {
    "effect": "deny"
  }
}
```

### Require Tag with Specific Values
```json
{
  "if": {
    "not": {
      "field": "tags['Environment']",
      "in": ["Dev", "Staging", "Production"]
    }
  },
  "then": {
    "effect": "deny"
  }
}
```

### Audit VMs without Encryption
```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.encryptionSettings.enabled",
        "notEquals": "true"
      }
    ]
  },
  "then": {
    "effect": "audit"
  }
}
```

### Deploy Diagnostic Settings
```json
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Storage/storageAccounts"
  },
  "then": {
    "effect": "deployIfNotExists",
    "details": {
      "type": "Microsoft.Insights/diagnosticSettings",
      "existenceCondition": {
        "allOf": [
          {
            "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
            "equals": "true"
          }
        ]
      },
      "deployment": {
        "properties": {
          "mode": "incremental",
          "template": {...}
        }
      }
    }
  }
}
```

## Exemption Categories

### Waiver
Recurso está isento da policy permanentemente ou temporariamente
- Uso: Casos onde a policy não se aplica ao recurso
- Exemplo: Sistema legado que não pode ser modificado

### Mitigated
Requisito da policy foi mitigado por outro controle
- Uso: Segurança implementada de forma alternativa
- Exemplo: Firewall externo ao invés de NSG

## Remediation

### Resource Discovery Modes

**ExistingNonCompliant** (Padrão)
- Remedia apenas recursos não conformes existentes
- Não re-avalia recursos conformes

**ReEvaluateCompliance**
- Re-avalia todos os recursos
- Pode identificar novos recursos não conformes

### Remediation Parameters

```hcl
create_remediation_task = true
resource_discovery_mode = "ExistingNonCompliant"
failure_percentage      = 10    # Falha se >10% falharem
parallel_deployments    = 5     # 5 deployments simultâneos
resource_count          = 100   # Máximo 100 recursos
```

## Managed Identity para Policies

Policies com efeitos **deployIfNotExists** ou **modify** requerem Managed Identity:

```hcl
identity_type = "SystemAssigned"
location      = "eastus"  # Obrigatório quando identity_type é definido
```

Após criar assignment, atribua permissões:

```hcl
resource "azurerm_role_assignment" "policy" {
  scope                = var.scope
  role_definition_name = "Contributor"  # Ou role específica
  principal_id         = module.policy.assignment_identity.principal_id
}
```

## Built-in Policies Úteis

### Security
```hcl
# Require HTTPS for Storage
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"

# Require Storage Encryption
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b0f33259-77d7-4c9e-aac6-3aabcfae693c"

# Require SQL TDE
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/17k78e20-9358-41c9-923c-fb736d382a12"
```

### Compliance
```hcl
# Allowed Locations
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

# Require Tag
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"

# Audit VMs without Managed Disks
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
```

## Policy Compliance Check

```bash
# Ver compliance de uma policy
az policy state list \
  --filter "policyAssignmentId eq '/subscriptions/.../assignments/assign-require-tags'" \
  --query "[?complianceState=='NonCompliant']"

# Trigger manual scan
az policy state trigger-scan --no-wait

# Ver summary
az policy state summarize \
  --policy-assignment "assign-require-tags"
```

## Best Practices

1. ✅ **Teste em modo Audit** antes de usar Deny
2. ✅ **Use initiatives** para agrupar policies relacionadas
3. ✅ **Defina non-compliance messages** claras
4. ✅ **Use parâmetros** para policies reutilizáveis
5. ✅ **Aplique no escopo correto** (MG > Subscription > RG)
6. ✅ **Configure exemptions com expiração** quando necessário
7. ✅ **Use remediation tasks** para corrigir não conformidades
8. ✅ **Documente policies** com metadata
9. ✅ **Monitore compliance** regularmente
10. ✅ **Atribua permissões mínimas** a Managed Identities

## Troubleshooting

### Policy não aplicando
- Aguarde 30 minutos para propagação
- Force scan: `az policy state trigger-scan`
- Verifique se está em modo Audit vs Deny
- Confirme escopo correto

### Remediation falhando
- Verifique permissões da Managed Identity
- Confirme que policy suporta remediation (deployIfNotExists/modify)
- Revise logs de deployment

### Exemption não funcionando
- Confirme policy_assignment_id correto
- Verifique se expires_on não passou
- Para initiatives, use policy_definition_reference_ids

### Erro de JSON
- Valide JSON: `echo $JSON | jq .`
- Use jsonencode() para objetos Terraform
- Escape aspas em strings JSON

## Limitações

- Maximum 500 policy definitions por tenant
- Maximum 200 policy assignments por scope
- Policy evaluation pode levar até 30 minutos
- Alguns resource types não suportam todas as policies
- Remediation limitada a 50k recursos por task

## Custo

Azure Policy é **gratuito** para:
- Policy definitions
- Policy assignments
- Compliance evaluation

**Custos aplicam-se a:**
- Remediation deployments (custo do recurso implantado)
- Managed Identity (se usar recursos adicionais)

## Recursos Criados

- `azurerm_policy_definition` - Policy definition
- `azurerm_policy_set_definition` - Initiative
- `azurerm_resource_policy_assignment` - Assignment
- `azurerm_resource_policy_exemption` - Exemption
- `azurerm_subscription_policy_remediation` - Remediation

## Dependências

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Permissões: Owner, Contributor ou Policy Contributor
- Azure AD (para Managed Identities)

## Referências

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Policy Definition Structure](https://docs.microsoft.com/azure/governance/policy/concepts/definition-structure)
- [Policy Effects](https://docs.microsoft.com/azure/governance/policy/concepts/effects)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition)