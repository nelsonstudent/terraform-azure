# Módulo Terraform - Azure Management Group

Este módulo Terraform provisiona e gerencia Azure Management Groups com suporte completo para hierarquia, políticas customizadas, policy assignments, role assignments RBAC e associação de subscriptions.

## Características

- Provisionamento de Management Groups
- Hierarquia de Management Groups (pai e filhos)
- Associação de subscriptions
- Custom Policy Definitions
- Policy Set Definitions (Initiatives)
- Policy Assignments com enforcement
- Role Assignments RBAC
- Políticas padrão recomendadas (opcional)
- Governança em escala para múltiplas subscriptions

## O que são Management Groups?

Management Groups são containers que ajudam a gerenciar acesso, políticas e compliance para múltiplas subscriptions Azure. Eles fornecem governança em escala enterprise-level acima do nível de subscription.

### Hierarquia Azure

```
Tenant Root Group
└── Management Group (Produção)
    ├── Subscription (App-Prod-01)
    ├── Subscription (App-Prod-02)
    └── Management Group (Aplicações)
        ├── Subscription (WebApp-Prod)
        └── Subscription (API-Prod)
```

## Uso Básico

```hcl
module "management_group" {
  source = "./modules/management_group"

  name         = "mg-production"
  display_name = "Production Environment"

  subscription_ids = [
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
  ]
}
```

## Exemplo com Hierarquia

```hcl
# Management Group Raiz da Empresa
module "mg_root" {
  source = "./modules/management_group"

  name         = "mg-contoso"
  display_name = "Contoso Corporation"
  
  # Sem parent - será criado no tenant root
  parent_management_group_id = null
}

# Management Groups por Ambiente
module "mg_production" {
  source = "./modules/management_group"

  name                       = "mg-production"
  display_name               = "Production"
  parent_management_group_id = module.mg_root.id

  subscription_ids = [
    data.azurerm_subscription.prod_01.subscription_id,
    data.azurerm_subscription.prod_02.subscription_id
  ]
}

module "mg_non_production" {
  source = "./modules/management_group"

  name                       = "mg-non-production"
  display_name               = "Non-Production"
  parent_management_group_id = module.mg_root.id
}

# Management Groups dentro de Non-Production
module "mg_dev" {
  source = "./modules/management_group"

  name                       = "mg-development"
  display_name               = "Development"
  parent_management_group_id = module.mg_non_production.id

  subscription_ids = [
    data.azurerm_subscription.dev_01.subscription_id
  ]
}

module "mg_staging" {
  source = "./modules/management_group"

  name                       = "mg-staging"
  display_name               = "Staging"
  parent_management_group_id = module.mg_non_production.id

  subscription_ids = [
    data.azurerm_subscription.staging_01.subscription_id
  ]
}
```

## Exemplo com Management Groups Filhos

```hcl
module "management_group" {
  source = "./modules/management_group"

  name         = "mg-production"
  display_name = "Production Environment"

  # Criar Management Groups filhos automaticamente
  child_management_groups = {
    "mg-prod-americas" = {
      display_name = "Production - Americas"
      subscription_ids = [
        "sub-prod-us-east-01",
        "sub-prod-us-west-01"
      ]
    }
    "mg-prod-emea" = {
      display_name = "Production - EMEA"
      subscription_ids = [
        "sub-prod-eu-west-01",
        "sub-prod-eu-north-01"
      ]
    }
    "mg-prod-apac" = {
      display_name = "Production - APAC"
      subscription_ids = [
        "sub-prod-asia-east-01"
      ]
    }
  }
}
```

## Exemplo com Custom Policies

```hcl
module "management_group" {
  source = "./modules/management_group"

  name         = "mg-production"
  display_name = "Production"

  # Definir políticas customizadas
  custom_policy_definitions = [
    {
      name         = "enforce-naming-convention"
      display_name = "Enforce Resource Naming Convention"
      description  = "Ensure all resources follow naming standards"
      mode         = "All"
      
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
    },
    {
      name         = "require-specific-tags"
      display_name = "Require specific tags on all resources"
      description  = "Enforce mandatory tagging"
      mode         = "Indexed"
      
      parameters = jsonencode({
        tagName = {
          type = "String"
          metadata = {
            displayName = "Tag Name"
            description = "Name of the tag to require"
          }
        }
      })
      
      policy_rule = jsonencode({
        if = {
          field  = "[concat('tags[', parameters('tagName'), ']')]"
          exists = "false"
        }
        then = {
          effect = "deny"
        }
      })
    }
  ]

  # Atribuir as políticas customizadas
  policy_assignments = [
    {
      name                 = "assign-naming-convention"
      display_name         = "Assign Naming Convention Policy"
      policy_definition_id = "WILL_BE_REPLACED_WITH_CUSTOM_POLICY_ID"
      enforce              = true
    }
  ]

  subscription_ids = [
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ]
}
```

## Exemplo com Policy Initiative (Policy Set)

```hcl
module "management_group" {
  source = "./modules/management_group"

  name         = "mg-production"
  display_name = "Production"

  # Criar initiative com múltiplas políticas
  policy_set_definitions = [
    {
      name         = "security-baseline"
      display_name = "Security Baseline Initiative"
      description  = "Comprehensive security baseline for production"
      
      policy_definition_references = [
        {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
          reference_id         = "RequireHTTPSStorage"
        },
        {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b0f33259-77d7-4c9e-aac6-3aabcfae693c"
          reference_id         = "RequireEncryptionStorage"
        },
        {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6edd7eda-6dd8-40f7-810d-67160c639cd9"
          reference_id         = "RequireSSLMySQL"
        }
      ]
      
      policy_definition_groups = [
        {
          name         = "Encryption"
          display_name = "Encryption Controls"
          category     = "Security"
        },
        {
          name         = "Network"
          display_name = "Network Security"
          category     = "Security"
        }
      ]
    }
  ]

  # Atribuir a initiative
  policy_assignments = [
    {
      name                 = "assign-security-baseline"
      display_name         = "Assign Security Baseline"
      policy_definition_id = "WILL_BE_REPLACED_WITH_INITIATIVE_ID"
      enforce              = true
    }
  ]
}
```

## Exemplo com Políticas Padrão

```hcl
module "management_group" {
  source = "./modules/management_group"

  name         = "mg-production"
  display_name = "Production"

  # Habilitar políticas padrão recomendadas
  enable_default_policies = true

  subscription_ids = [
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ]
}

# As seguintes políticas serão aplicadas automaticamente:
# - Audit VMs without managed disks
# - Allowed locations
# - Require Environment tag
```

## Exemplo com RBAC

```hcl
data "azuread_group" "platform_team" {
  display_name = "Platform Engineering"
}

data "azuread_group" "security_team" {
  display_name = "Security Team"
}

module "management_group" {
  source = "./modules/management_group"

  name         = "mg-production"
  display_name = "Production"

  role_assignments = [
    {
      principal_id         = data.azuread_group.platform_team.object_id
      role_definition_name = "Contributor"
      description          = "Platform team full access"
    },
    {
      principal_id         = data.azuread_group.security_team.object_id
      role_definition_name = "Security Admin"
      description          = "Security team admin access"
    },
    {
      principal_id         = data.azuread_group.security_team.object_id
      role_definition_name = "Reader"
      description          = "Security team read access"
    }
  ]

  subscription_ids = [
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ]
}
```

## Exemplo Completo - Enterprise Landing Zone

```hcl
# Root Management Group
module "mg_root" {
  source = "./modules/management_group"

  name         = "mg-contoso"
  display_name = "Contoso Corporation"
}

# Platform Management Group
module "mg_platform" {
  source = "./modules/management_group"

  name                       = "mg-platform"
  display_name               = "Platform"
  parent_management_group_id = module.mg_root.id

  custom_policy_definitions = [
    {
      name         = "deny-public-endpoints"
      display_name = "Deny Public Endpoints"
      description  = "Deny creation of resources with public endpoints"
      mode         = "All"
      
      policy_rule = jsonencode({
        if = {
          anyOf = [
            {
              allOf = [
                {
                  field  = "type"
                  equals = "Microsoft.Storage/storageAccounts"
                },
                {
                  field  = "Microsoft.Storage/storageAccounts/networkAcls.defaultAction"
                  equals = "Allow"
                }
              ]
            },
            {
              allOf = [
                {
                  field  = "type"
                  equals = "Microsoft.Sql/servers"
                },
                {
                  field  = "Microsoft.Sql/servers/publicNetworkAccess"
                  equals = "Enabled"
                }
              ]
            }
          ]
        }
        then = {
          effect = "deny"
        }
      })
    }
  ]

  policy_assignments = [
    {
      name                 = "require-private-endpoints"
      display_name         = "Require Private Endpoints"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/xxx"
      enforce              = true
    }
  ]

  role_assignments = [
    {
      principal_id         = data.azuread_group.platform_team.object_id
      role_definition_name = "Owner"
      description          = "Platform team ownership"
    }
  ]

  child_management_groups = {
    "mg-platform-connectivity" = {
      display_name = "Connectivity"
      subscription_ids = [
        data.azurerm_subscription.hub_network.subscription_id
      ]
    }
    "mg-platform-identity" = {
      display_name = "Identity"
      subscription_ids = [
        data.azurerm_subscription.identity.subscription_id
      ]
    }
    "mg-platform-management" = {
      display_name = "Management"
      subscription_ids = [
        data.azurerm_subscription.management.subscription_id
      ]
    }
  }
}

# Landing Zones Management Group
module "mg_landing_zones" {
  source = "./modules/management_group"

  name                       = "mg-landing-zones"
  display_name               = "Landing Zones"
  parent_management_group_id = module.mg_root.id

  policy_set_definitions = [
    {
      name         = "landing-zone-baseline"
      display_name = "Landing Zone Baseline"
      description  = "Standard policies for all landing zones"
      
      policy_definition_references = [
        {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
          reference_id         = "RequireHTTPSStorage"
        },
        {
          policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
          reference_id         = "AllowedLocations"
          parameter_values = jsonencode({
            listOfAllowedLocations = {
              value = ["eastus", "eastus2", "westus2"]
            }
          })
        }
      ]
    }
  ]

  child_management_groups = {
    "mg-lz-production" = {
      display_name = "Production Landing Zones"
    }
    "mg-lz-non-production" = {
      display_name = "Non-Production Landing Zones"
    }
    "mg-lz-sandbox" = {
      display_name = "Sandbox"
    }
  }
}

# Production Landing Zones
module "mg_production" {
  source = "./modules/management_group"

  name                       = "mg-lz-production"
  display_name               = "Production"
  parent_management_group_id = module.mg_landing_zones.id

  enable_default_policies = true

  role_assignments = [
    {
      principal_id         = data.azuread_group.app_team.object_id
      role_definition_name = "Contributor"
      description          = "Application team access"
    }
  ]

  child_management_groups = {
    "mg-prod-online" = {
      display_name = "Online Applications"
      subscription_ids = [
        "sub-webapp-prod-01",
        "sub-api-prod-01"
      ]
    }
    "mg-prod-corp" = {
      display_name = "Corporate Applications"
      subscription_ids = [
        "sub-erp-prod-01",
        "sub-crm-prod-01"
      ]
    }
  }
}

# Decommissioned Management Group
module "mg_decommissioned" {
  source = "./modules/management_group"

  name                       = "mg-decommissioned"
  display_name               = "Decommissioned"
  parent_management_group_id = module.mg_root.id

  policy_assignments = [
    {
      name                 = "deny-all-deployments"
      display_name         = "Deny All Resource Deployments"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/xxx"
      enforce              = true
    }
  ]

  role_assignments = [
    {
      principal_id         = data.azuread_group.decom_team.object_id
      role_definition_name = "Contributor"
      description          = "Decommissioning team access"
    }
  ]
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| name | Nome (ID) do Management Group | `string` | n/a | sim |
| display_name | Nome de exibição | `string` | `name` | não |
| parent_management_group_id | ID do MG pai | `string` | `null` | não |
| subscription_ids | IDs das subscriptions | `list(string)` | `[]` | não |
| child_management_groups | MGs filhos | `map(object)` | `{}` | não |
| policy_assignments | Policy assignments | `list(object)` | `[]` | não |
| role_assignments | Role assignments | `list(object)` | `[]` | não |
| custom_policy_definitions | Políticas customizadas | `list(object)` | `[]` | não |
| policy_set_definitions | Initiatives | `list(object)` | `[]` | não |
| enable_default_policies | Habilitar políticas padrão | `bool` | `false` | não |
| default_location | Localização padrão | `string` | `"eastus"` | não |
| tags | Tags (para recursos) | `map(string)` | `{}` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| id | ID do Management Group |
| name | Nome do Management Group |
| display_name | Nome de exibição |
| parent_management_group_id | ID do MG pai |
| subscription_ids | IDs das subscriptions |
| subscription_associations | Associações criadas |
| child_management_groups | MGs filhos |
| child_management_group_ids | IDs dos MGs filhos |
| custom_policy_definitions | Políticas customizadas |
| custom_policy_definition_ids | IDs das políticas |
| policy_set_definitions | Initiatives |
| policy_set_definition_ids | IDs das initiatives |
| policy_assignments | Assignments criadas |
| policy_assignment_ids | IDs dos assignments |
| role_assignments | Role assignments |
| role_assignment_ids | IDs dos assignments |
| hierarchy | Hierarquia completa |
| governance_summary | Resumo da governança |
| resource | Objeto completo |

## Conceitos Importantes

### Management Group Hierarchy

**Limites:**
- Máximo 6 níveis de profundidade (excluindo root)
- Máximo 10.000 Management Groups por tenant
- Cada Management Group pode ter apenas 1 pai
- Subscriptions podem pertencer a apenas 1 Management Group

### Herança de Políticas

Políticas aplicadas em Management Groups são herdadas por:
- ✅ Management Groups filhos
- ✅ Subscriptions dentro do Management Group
- ✅ Resource Groups nas subscriptions
- ✅ Recursos individuais

```
MG Root (Policy A, B)
└── MG Child (Policy C)
    └── Subscription
        └── Resource Group
            └── Resource (Herda A, B, C)
```

### Policy Compliance

```bash
# Verificar compliance
az policy state list \
  --management-group mg-production \
  --filter "complianceState eq 'NonCompliant'"

# Ver detalhes de policy
az policy assignment list \
  --management-group mg-production
```

## Padrões de Design

### 1. Enterprise Landing Zone (Microsoft CAF)

```
Tenant Root
├── Platform
│   ├── Connectivity (Hub Networks)
│   ├── Identity (AD, AAD)
│   └── Management (Monitoring, Security)
├── Landing Zones
│   ├── Production
│   ├── Non-Production
│   └── Sandbox
├── Decommissioned
└── Quarantine
```

### 2. Por Ambiente

```
Tenant Root
├── Production
├── Staging
├── Development
└── Sandbox
```

### 3. Por Unidade de Negócio

```
Tenant Root
├── Business Unit A
│   ├── Production
│   └── Non-Production
├── Business Unit B
│   ├── Production
│   └── Non-Production
└── Shared Services
```

### 4. Por Geografia

```
Tenant Root
├── Americas
│   ├── North America
│   └── South America
├── EMEA
│   ├── Europe
│   └── Middle East
└── APAC
```

### 5. Híbrido (Recomendado)

```
Tenant Root
├── Platform (Shared)
│   ├── Connectivity
│   ├── Identity
│   └── Management
├── Landing Zones
│   ├── Production
│   │   ├── Americas
│   │   ├── EMEA
│   │   └── APAC
│   └── Non-Production
│       ├── Development
│       ├── Staging
│       └── QA
├── Sandbox
└── Decommissioned
```

## Built-in Policies Comuns

```hcl
# Allowed Locations
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

# Require Tag
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"

# Audit VMs without Managed Disks
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"

# Require HTTPS for Storage
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"

# Require SSL for MySQL
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e802a67a-daf5-4436-9ea6-f6d821dd0c5d"

# Require SQL Server TDE
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/17k78e20-9358-41c9-923c-fb736d382a12"

# Deny Public IP
policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
```

## Built-in Initiatives Comuns

```hcl
# Azure Security Benchmark
policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"

# NIST SP 800-53 R4
policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/cf25b9c1-bd23-4eb6-bd2c-f4f3ac644a5f"

# ISO 27001:2013
policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2"

# PCI DSS 3.2.1
policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/496eeda9-8f2f-4d5e-8dfd-204f0a92ed41"

# HIPAA HITRUST 9.2
policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab"
```

## RBAC no Management Group

### Roles Recomendadas

**Management Group Level:**
- **Owner** - Administradores seniores
- **Contributor** - Platform teams
- **Reader** - Auditores, segurança
- **Management Group Contributor** - Gerenciar MGs
- **Resource Policy Contributor** - Gerenciar políticas

**Subscription Level (herdadas):**
- Todas as roles atribuídas no MG aplicam-se às subscriptions

### Best Practice RBAC

```hcl
# Root MG - Apenas ownership mínimo
role_assignments = [
  {
    principal_id         = data.azuread_group.global_admins.object_id
    role_definition_name = "Owner"
  }
]

# Platform MG - Platform teams
role_assignments = [
  {
    principal_id         = data.azuread_group.platform_team.object_id
    role_definition_name = "Contributor"
  }
]

# Landing Zone MG - Application teams
role_assignments = [
  {
    principal_id         = data.azuread_group.app_teams.object_id
    role_definition_name = "Contributor"
  }
]
```

## Migrando Subscriptions

```bash
# Mover subscription entre Management Groups
az account management-group subscription add \
  --name mg-production \
  --subscription "sub-id"

# Via Terraform
resource "azurerm_management_group_subscription_association" "move" {
  management_group_id = azurerm_management_group.new.id
  subscription_id     = "/subscriptions/xxx"
}
```

## Troubleshooting

### Erro: "ManagementGroupNotFound"
- Verifique se o Management Group existe
- Confirme permissões (Owner ou MG Contributor)

### Erro: "SubscriptionAlreadyAssociated"
- Subscription já pertence a outro MG
- Remova do MG atual antes de associar

### Erro: "PolicyAssignmentFailed"
- Verifique se policy definition existe
- Confirme parâmetros obrigatórios
- Valide JSON de parâmetros

### Erro: "MaximumHierarchyLevelReached"
- Limite de 6 níveis atingido
- Redesenhe hierarquia mais plana

### Policy não aplicando
- Aguarde até 30 minutos para propagação
- Force evaluation: `az policy state trigger-scan`
- Verifique se está em modo Audit ou Deny

## Best Practices

1. ✅ **Planeje hierarquia antes** - difícil mudar depois
2. ✅ **Use no máximo 3-4 níveis** de profundidade
3. ✅ **Aplique políticas no nível mais alto possível** para herança
4. ✅ **Use naming convention consistente** (mg-*)
5. ✅ **Documente estrutura e propósito** de cada MG
6. ✅ **Separe Platform de Landing Zones**
7. ✅ **Use Policy Initiatives** ao invés de policies individuais
8. ✅ **Teste policies em modo Audit** antes de Deny
9. ✅ **Implemente RBAC por camada** (root, platform, workload)
10. ✅ **Crie MG para Decommissioned resources**

## Limitações

- Máximo 6 níveis de profundidade
- 10.000 Management Groups por tenant
- Subscription em apenas 1 Management Group
- Propagação de policy pode levar 30 minutos
- Não suporta tags diretamente
- Alguns recursos não suportam policy inheritance

## Custo

Management Groups são **100% gratuitos**.

## Recursos Criados

- `azurerm_management_group` - Management Group principal
- `azurerm_management_group` - Management Groups filhos
- `azurerm_management_group_subscription_association` - Associações
- `azurerm_policy_definition` - Políticas customizadas
- `azurerm_policy_set_definition` - Initiatives
- `azurerm_management_group_policy_assignment` - Assignments
- `azurerm_role_assignment` - RBAC

## Dependências

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Permissões: Owner ou Management Group Contributor
- Azure AD (para role assignments)

## Referências

- [Management Groups Documentation](https://docs.microsoft.com/azure/governance/management-groups/)
- [Azure Policy](https://docs.microsoft.com/azure/governance/policy/)
- [Enterprise-Scale Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group)