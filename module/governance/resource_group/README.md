# Módulo Terraform - Azure Resource Group

Este módulo Terraform provisiona um Azure Resource Group com recursos avançados de governança, incluindo management locks, role assignments RBAC, policy assignments, diagnostic settings e budgets.

## Características

- Provisionamento de Resource Group
- Management Locks (CanNotDelete ou ReadOnly)
- Role Assignments RBAC
- Azure Policy Assignments
- Diagnostic Settings para Activity Log
- Consumption Budgets com notificações
- Tags management
- Proteção contra deleção acidental

## Uso Básico

```hcl
module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-app-prod"
  location = "eastus"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Lock de Proteção

```hcl
module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-app-prod"
  location = "eastus"

  # Prevenir deleção acidental
  prevent_deletion = true
  lock_notes       = "Production environment - do not delete"

  tags = {
    Environment = "Production"
    Critical    = "Yes"
  }
}
```

## Exemplo com Role Assignments

```hcl
data "azurerm_client_config" "current" {}

module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-app-prod"
  location = "eastus"

  role_assignments = [
    {
      principal_id         = data.azurerm_client_config.current.object_id
      role_definition_name = "Owner"
      description          = "Terraform service principal"
    },
    {
      principal_id         = azuread_group.developers.object_id
      role_definition_name = "Contributor"
      description          = "Developers team"
    },
    {
      principal_id         = azuread_group.readers.object_id
      role_definition_name = "Reader"
      description          = "Read-only access"
    }
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Budget

```hcl
module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-app-prod"
  location = "eastus"

  budget = {
    enabled    = true
    name       = "monthly-budget"
    amount     = 5000
    time_grain = "Monthly"
    
    notifications = [
      {
        enabled        = true
        threshold      = 80
        operator       = "GreaterThanOrEqualTo"
        contact_emails = ["finance@company.com", "manager@company.com"]
        contact_roles  = ["Owner", "Contributor"]
      },
      {
        enabled        = true
        threshold      = 100
        operator       = "GreaterThanOrEqualTo"
        contact_emails = ["finance@company.com", "cto@company.com"]
        contact_roles  = ["Owner"]
      },
      {
        enabled        = true
        threshold      = 120
        operator       = "GreaterThanOrEqualTo"
        contact_emails = ["finance@company.com", "ceo@company.com"]
        contact_roles  = ["Owner"]
      }
    ]
  }

  tags = {
    Environment = "Production"
    CostCenter  = "Engineering"
  }
}
```

## Exemplo com Diagnostic Settings

```hcl
module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-app-prod"
  location = "eastus"

  diagnostic_settings = {
    enabled                    = true
    name                       = "rg-diagnostics"
    log_analytics_workspace_id = module.log_analytics.id
    
    log_categories = [
      "Administrative",
      "Security",
      "ServiceHealth",
      "Alert",
      "Recommendation",
      "Policy",
      "Autoscale",
      "ResourceHealth"
    ]
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Azure Policies

```hcl
module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-app-prod"
  location = "eastus"

  policy_assignments = [
    {
      name                 = "require-tags"
      display_name         = "Require specific tags on resources"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"
      description          = "Enforce tagging standards"
      enforce              = true
      
      parameters = jsonencode({
        tagName = {
          value = "Environment"
        }
      })
      
      non_compliance_messages = [
        {
          message = "Resources must have an Environment tag"
        }
      ]
    },
    {
      name                 = "allowed-locations"
      display_name         = "Allowed locations"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
      enforce              = true
      
      parameters = jsonencode({
        listOfAllowedLocations = {
          value = ["eastus", "eastus2", "westus2"]
        }
      })
    }
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo Completo - Governança Avançada

```hcl
data "azurerm_client_config" "current" {}

module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-app-prod"
  location = "eastus"

  # Proteção contra deleção
  prevent_deletion = true
  lock_notes       = "Production environment - protected by Terraform"

  # RBAC
  role_assignments = [
    {
      principal_id         = data.azurerm_client_config.current.object_id
      role_definition_name = "Owner"
      description          = "Terraform Service Principal"
    },
    {
      principal_id         = azuread_group.platform_team.object_id
      role_definition_name = "Contributor"
      description          = "Platform Engineering Team"
    },
    {
      principal_id         = azuread_group.app_team.object_id
      role_definition_name = "Contributor"
      description          = "Application Development Team"
      condition            = "@Resource[Microsoft.Storage/storageAccounts:name] StringLike 'app*'"
      condition_version    = "2.0"
    },
    {
      principal_id         = azuread_group.security_team.object_id
      role_definition_name = "Security Reader"
      description          = "Security Team - Read Access"
    }
  ]

  # Azure Policies
  policy_assignments = [
    {
      name                 = "enforce-tags"
      display_name         = "Enforce required tags"
      policy_definition_id = data.azurerm_policy_definition.require_tag.id
      enforce              = true
      
      parameters = jsonencode({
        tagName = { value = "Environment" }
      })
      
      non_compliance_messages = [
        {
          message = "All resources must have Environment tag"
        }
      ]
    },
    {
      name                 = "audit-vm-managed-disks"
      display_name         = "Audit VMs without managed disks"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
      enforce              = false
      description          = "Audit mode - identify VMs without managed disks"
    },
    {
      name                 = "require-https-storage"
      display_name         = "Require HTTPS for storage accounts"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
      enforce              = true
    }
  ]

  # Diagnostic Settings
  diagnostic_settings = {
    enabled                    = true
    name                       = "activity-log-diagnostics"
    log_analytics_workspace_id = module.log_analytics.id
    storage_account_id         = module.storage_logs.id
    
    log_categories = [
      "Administrative",
      "Security",
      "ServiceHealth",
      "Alert",
      "Recommendation",
      "Policy",
      "Autoscale",
      "ResourceHealth"
    ]
  }

  # Budget
  budget = {
    enabled    = true
    name       = "monthly-production-budget"
    amount     = 10000
    time_grain = "Monthly"
    
    notifications = [
      {
        enabled        = true
        threshold      = 75
        operator       = "GreaterThanOrEqualTo"
        contact_emails = ["finance@company.com"]
        contact_roles  = ["Owner"]
      },
      {
        enabled        = true
        threshold      = 90
        operator       = "GreaterThanOrEqualTo"
        contact_emails = ["finance@company.com", "engineering-lead@company.com"]
        contact_roles  = ["Owner", "Contributor"]
      },
      {
        enabled        = true
        threshold      = 100
        operator       = "GreaterThanOrEqualTo"
        contact_emails = ["finance@company.com", "cto@company.com", "ceo@company.com"]
        contact_roles  = ["Owner"]
      }
    ]
  }

  tags = {
    Environment  = "Production"
    Project      = "MyApp"
    CostCenter   = "Engineering"
    Owner        = "platform-team@company.com"
    Compliance   = "SOC2,ISO27001"
    ManagedBy    = "Terraform"
    CreatedDate  = "2024-01-15"
  }
}

# Usar outputs
output "rg_id" {
  value = module.resource_group.id
}

output "governance_summary" {
  value = module.resource_group.governance
}
```

## Exemplo Multi-Ambiente

```hcl
locals {
  environments = {
    dev = {
      location         = "eastus2"
      prevent_deletion = false
      budget_amount    = 500
      lock_level       = null
    }
    staging = {
      location         = "eastus"
      prevent_deletion = true
      budget_amount    = 2000
      lock_level       = "CanNotDelete"
    }
    prod = {
      location         = "eastus"
      prevent_deletion = true
      budget_amount    = 10000
      lock_level       = "CanNotDelete"
    }
  }
}

module "resource_groups" {
  source   = "./modules/resource_group"
  for_each = local.environments

  name             = "rg-app-${each.key}"
  location         = each.value.location
  prevent_deletion = each.value.prevent_deletion
  lock_level       = each.value.lock_level

  budget = {
    enabled    = true
    amount     = each.value.budget_amount
    time_grain = "Monthly"
    
    notifications = [
      {
        enabled        = true
        threshold      = 80
        contact_emails = ["finance@company.com"]
      }
    ]
  }

  tags = {
    Environment = title(each.key)
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| name | Nome do Resource Group | `string` | n/a | sim |
| location | Localização do Resource Group | `string` | n/a | sim |
| tags | Tags do Resource Group | `map(string)` | `{}` | não |
| managed_by | ID do recurso gerenciador | `string` | `null` | não |
| lock_level | Nível do lock | `string` | `null` | não |
| lock_notes | Notas sobre o lock | `string` | `"Locked by Terraform"` | não |
| prevent_deletion | Prevenir deleção | `bool` | `false` | não |
| enable_delete_lock | Alias para prevent_deletion | `bool` | `null` | não |
| role_assignments | Role assignments RBAC | `list(object)` | `[]` | não |
| policy_assignments | Policy assignments | `list(object)` | `[]` | não |
| diagnostic_settings | Diagnostic settings | `object` | ver abaixo | não |
| budget | Budget configuration | `object` | ver abaixo | não |
| subscription_id | Subscription ID | `string` | current | não |

### Diagnostic Settings Padrão

```hcl
{
  enabled = false
}
```

### Budget Padrão

```hcl
{
  enabled = false
  amount  = 0
}
```

## Outputs

| Nome | Descrição |
|------|-----------|
| id | ID do Resource Group |
| name | Nome do Resource Group |
| location | Localização |
| tags | Tags aplicadas |
| managed_by | Gerenciador |
| lock_id | ID do lock |
| lock_level | Nível do lock |
| is_locked | Status locked |
| role_assignment_ids | IDs role assignments |
| role_assignments | Detalhes role assignments |
| policy_assignment_ids | IDs policy assignments |
| policy_assignments | Detalhes policy assignments |
| diagnostic_setting_id | ID diagnostic setting |
| budget_id | ID do budget |
| budget_amount | Valor do budget |
| subscription_id | Subscription ID |
| full_resource_id | ARM Resource ID completo |
| resource | Objeto completo |
| governance | Resumo da governança |

## Management Locks

### Tipos de Lock

**CanNotDelete**
- Recursos podem ser lidos e modificados
- ❌ Recursos NÃO podem ser deletados
- ✅ Ideal para ambientes de produção

**ReadOnly**
- Recursos podem ser lidos
- ❌ Recursos NÃO podem ser modificados
- ❌ Recursos NÃO podem ser deletados
- ⚠️ Use com cautela - impede até mesmo Terraform de fazer updates

### Comportamento de Locks

```hcl
# Lock CanNotDelete
module "rg_prod" {
  source = "./modules/resource_group"
  
  name             = "rg-prod"
  location         = "eastus"
  prevent_deletion = true  # Cria lock CanNotDelete
}

# Lock ReadOnly
module "rg_archive" {
  source = "./modules/resource_group"
  
  name       = "rg-archive"
  location   = "eastus"
  lock_level = "ReadOnly"  # Lock explícito ReadOnly
}

# Sem lock
module "rg_dev" {
  source = "./modules/resource_group"
  
  name     = "rg-dev"
  location = "eastus"
  # prevent_deletion = false (padrão)
}
```

### Remover Lock

Para remover um lock via Terraform:

```hcl
# Opção 1: Remover prevent_deletion
module "resource_group" {
  source           = "./modules/resource_group"
  prevent_deletion = false  # Muda de true para false
  # ...
}

# Opção 2: Remover lock_level
module "resource_group" {
  source     = "./modules/resource_group"
  lock_level = null  # Remove o lock
  # ...
}
```

Ou via Azure CLI:
```bash
az lock delete --name rg-prod-lock --resource-group rg-prod
```

## Role Assignments RBAC

### Roles Comuns

**Owner**
- Acesso total ao Resource Group
- Pode gerenciar recursos e permissões
- Pode atribuir roles

**Contributor**
- Pode criar e gerenciar recursos
- ❌ Não pode atribuir roles

**Reader**
- Apenas leitura
- Visualizar recursos e configurações

**Roles Específicas**
- **User Access Administrator** - Gerenciar acesso
- **Network Contributor** - Gerenciar recursos de rede
- **Virtual Machine Contributor** - Gerenciar VMs
- **Storage Account Contributor** - Gerenciar storage
- **SQL DB Contributor** - Gerenciar SQL databases

### RBAC com Conditions

Azure RBAC 2.0 suporta conditions:

```hcl
role_assignments = [
  {
    principal_id         = azuread_group.devs.object_id
    role_definition_name = "Storage Blob Data Contributor"
    description          = "Developers can only access dev containers"
    condition = <<-EOT
      (
        (
          !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'})
        )
        OR
        (
          @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'dev-container'
        )
      )
    EOT
    condition_version = "2.0"
  }
]
```

## Azure Policies

### Policy vs Initiative

**Policy** - Regra única
```hcl
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/xxx"
```

**Initiative** - Conjunto de policies
```hcl
policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/xxx"
```

### Modes: Enforce vs Audit

**Enforce** (Default)
```hcl
enforce = true  # Bloqueia recursos não conformes
```

**Audit**
```hcl
enforce = false  # Apenas reporta não conformidade
```

### Políticas Comuns

```hcl
# Require tags
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"

# Allowed locations
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

# Require HTTPS for storage
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"

# Audit VMs without managed disks
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"

# Require encryption on storage
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6edd7eda-6dd8-40f7-810d-67160c639cd9"
```

### Custom Policies

```hcl
resource "azurerm_policy_definition" "custom" {
  name         = "custom-naming-convention"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce naming convention"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          not = {
            field = "name"
            like  = "st[a-z]*[0-9]*"
          }
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

module "resource_group" {
  source = "./modules/resource_group"
  
  policy_assignments = [
    {
      name                 = "naming-convention"
      policy_definition_id = azurerm_policy_definition.custom.id
      enforce              = true
    }
  ]
}
```

## Budgets e Cost Management

### Budget Time Grains

- **Monthly** - Budget mensal (mais comum)
- **Quarterly** - Budget trimestral
- **Annually** - Budget anual

### Notification Thresholds

Recomendações:
- **75%** - Alerta inicial para finance
- **90%** - Alerta crítico para finance + manager
- **100%** - Alerta urgente para leadership
- **110-120%** - Alerta de overspend para executivos

### Notification Contacts

**contact_emails**
```hcl
contact_emails = ["finance@company.com", "manager@company.com"]
```

**contact_roles**
```hcl
contact_roles = ["Owner", "Contributor"]  # Roles RBAC no RG
```

**contact_groups**
```hcl
contact_groups = [azurerm_monitor_action_group.finance.id]
```

### Budget Best Practices

1. ✅ Configure múltiplos thresholds (75%, 90%, 100%)
2. ✅ Inclua diferentes stakeholders por threshold
3. ✅ Use contact_roles para notificações automáticas
4. ✅ Revise budgets mensalmente
5. ✅ Ajuste budgets baseado em tendências
6. ✅ Configure budgets por environment
7. ✅ Documente justificativas de overruns

## Diagnostic Settings

### Log Categories

**Administrative**
- Create, Update, Delete operations
- Role assignments
- Deployments

**Security**
- Security alerts
- Security assessments
- Access reviews

**ServiceHealth**
- Service issues
- Planned maintenance
- Health advisories

**Alert**
- Fired alerts
- Alert rule changes

**Recommendation**
- Advisor recommendations
- Best practice suggestions

**Policy**
- Policy evaluations
- Compliance state changes

**Autoscale**
- Autoscale operations
- Scale events

**ResourceHealth**
- Resource availability
- Health changes

### Destinations

**Log Analytics Workspace** (Recomendado)
```hcl
log_analytics_workspace_id = module.log_analytics.id
```

**Storage Account** (Arquivamento)
```hcl
storage_account_id = module.storage_logs.id
```

**Event Hub** (Streaming)
```hcl
eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.logs.id
eventhub_name                  = azurerm_eventhub.logs.name
```

### Consultas úteis (Log Analytics)

```kusto
// Todas operações de delete nos últimos 7 dias
AzureActivity
| where TimeGenerated > ago(7d)
| where OperationNameValue endswith "DELETE"
| project TimeGenerated, Caller, ResourceGroup, ResourceId, OperationNameValue

// Falhas de deployment
AzureActivity
| where CategoryValue == "Administrative"
| where ActivityStatusValue == "Failed"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue

// Mudanças de RBAC
AzureActivity
| where OperationNameValue has "roleAssignments"
| project TimeGenerated, Caller, OperationNameValue, Properties
```

## Nomenclatura Recomendada

### Padrão Microsoft

```
<resource-type>-<workload/app>-<environment>-<region>-<instance>
```

Exemplos:
```hcl
# Aplicações
rg-webapp-prod-eastus-001
rg-api-staging-westus2-001
rg-mobile-dev-eastus2-001

# Por função
rg-networking-prod-eastus-001
rg-security-prod-eastus-001
rg-monitoring-prod-eastus-001
rg-identity-prod-eastus-001

# Por projeto
rg-project-alpha-prod-eastus-001
rg-project-beta-dev-westus2-001
```

### Padrão por Ambiente

```hcl
locals {
  rg_prefix = "rg"
  app_name  = "myapp"
  
  rg_names = {
    dev     = "${local.rg_prefix}-${local.app_name}-dev"
    staging = "${local.rg_prefix}-${local.app_name}-staging"
    prod    = "${local.rg_prefix}-${local.app_name}-prod"
  }
}
```

## Tagging Strategy

### Tags Essenciais

```hcl
tags = {
  # Organizacionais
  Environment  = "Production"          # Dev, Staging, Production
  Owner        = "team@company.com"    # Email do time responsável
  CostCenter   = "Engineering"         # Centro de custo
  Project      = "MyApp"               # Nome do projeto
  
  # Técnicas
  ManagedBy    = "Terraform"           # Ferramenta de gestão
  Repository   = "github.com/org/repo" # Repositório do código
  
  # Compliance
  Compliance   = "SOC2,ISO27001"       # Standards aplicáveis
  DataClass    = "Confidential"        # Classificação dos dados
  
  # Operacionais
  SLA          = "99.9"                # SLA esperado
  BusinessUnit = "Digital Products"    # Unidade de negócio
  Criticality  = "High"                # Criticidade (High, Medium, Low)
  
  # Auditoria
  CreatedDate  = "2024-01-15"          # Data de criação
  CreatedBy    = "john.doe"            # Criador
}
```

### Tags Automáticas

```hcl
locals {
  common_tags = {
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Repository   = "github.com/myorg/myrepo"
    CreatedDate  = timestamp()
    TerraformWS  = terraform.workspace
  }
}

module "resource_group" {
  source = "./modules/resource_group"
  
  tags = merge(
    local.common_tags,
    var.additional_tags,
    {
      Name = "rg-app-${var.environment}"
    }
  )
}
```

## Hierarquia de Resource Groups

### Por Ambiente

```
rg-app-dev
rg-app-staging
rg-app-prod
```

### Por Camada (Tier)

```
rg-app-prod-frontend
rg-app-prod-backend
rg-app-prod-database
rg-app-prod-cache
```

### Por Ciclo de Vida

```
rg-app-prod-compute    # Recursos efêmeros
rg-app-prod-data       # Recursos persistentes
rg-app-prod-network    # Recursos compartilhados
```

### Por Workload

```
rg-webapp-prod
rg-api-prod
rg-worker-prod
rg-batch-prod
```

## Troubleshooting

### Erro: "ResourceGroupNotFound"
- Verifique se o nome está correto
- Confirme a subscription
- Verifique permissões

### Erro: "LockedResourceGroup"
- Remova o lock antes de fazer alterações críticas
- Use portal ou CLI para remover lock temporariamente

### Erro: "QuotaExceeded"
- Verifique limite de Resource Groups na subscription (980)
- Consolide Resource Groups se possível

### Erro: "PolicyViolation"
- Revise policies atribuídas
- Ajuste configuração ou solicite exceção

### Budget não enviando notificações
- Verifique emails configurados
- Confirme que roles têm permissão de receber notificações
- Verifique spam/junk folder

## Best Practices

1. ✅ **Use nomenclatura consistente** seguindo padrão da organização
2. ✅ **Aplique tags obrigatórias** em todos Resource Groups
3. ✅ **Habilite locks** em ambientes de produção
4. ✅ **Configure budgets** para controle de custos
5. ✅ **Use RBAC** ao invés de subscription-level permissions
6. ✅ **Implemente policies** para governança automatizada
7. ✅ **Habilite diagnostic settings** para auditoria
8. ✅ **Separe por lifecycle** (compute vs data)
9. ✅ **Documente via tags** ownership e propósito
10. ✅ **Revise regularmente** Resource Groups não utilizados

## Limitações

- Máximo 980 Resource Groups por subscription
- Resource Group não pode ser movido entre subscriptions
- Locks aplicam-se a todos recursos dentro do RG
- Algumas operações ignoram Read-Only locks
- Máximo 50 tags por Resource Group

## Custo

Resource Groups são **gratuitos**, mas considere:
- Custos de recursos dentro do RG
- Custos de Log Analytics (diagnostic settings)
- Custos de armazenamento (se usar storage account para logs)
- Budget é gratuito (apenas notificações)

## Recursos Criados

- `azurerm_resource_group` - Resource Group principal
- `azurerm_management_lock` - Lock (opcional)
- `azurerm_role_assignment` - RBAC assignments (opcional)
- `azurerm_resource_group_policy_assignment` - Policies (opcional)
- `azurerm_monitor_diagnostic_setting` - Diagnostics (opcional)
- `azurerm_consumption_budget_resource_group` - Budget (opcional)

## Dependências

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Azure AD (para role assignments)
- Log Analytics Workspace (recomendado para diagnostics)

## Referências

- [Resource Group Documentation](https://docs.microsoft.com/azure/azure-resource-manager/management/overview)
- [Management Locks](https://docs.microsoft.com/azure/azure-resource-manager/management/lock-resources)
- [Azure RBAC](https://docs.microsoft.com/azure/role-based-access-control/overview)
- [Azure Policy](https://docs.microsoft.com/azure/governance/policy/overview)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)