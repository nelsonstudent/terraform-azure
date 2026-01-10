# Módulo Terraform - Azure Defender for Cloud

Este módulo Terraform provisiona e configura o Microsoft Defender for Cloud (anteriormente Azure Security Center) com proteção avançada para recursos Azure, automações de segurança, políticas JIT e integração com Log Analytics.

## Características

- Habilitação de planos Defender para diversos tipos de recursos
- Configuração de contatos de segurança
- Auto-provisioning de agentes de segurança
- Integração com Log Analytics Workspace
- Workflow Automations para resposta a incidentes
- Just-In-Time (JIT) VM Access
- Advanced Threat Protection para recursos específicos
- Integração com Microsoft Cloud App Security (MCAS)
- Integração com Windows Defender ATP (WDATP)
- Integração com Microsoft Sentinel

## Planos Defender Disponíveis

- **VirtualMachines** - Proteção para VMs
- **SqlServers** - Proteção para SQL Servers
- **AppServices** - Proteção para App Services
- **StorageAccounts** - Proteção para Storage Accounts
- **KubernetesService** - Proteção para AKS
- **ContainerRegistry** - Proteção para ACR
- **KeyVaults** - Proteção para Key Vaults
- **Dns** - Proteção DNS
- **Arm** - Proteção Resource Manager
- **OpenSourceRelationalDatabases** - Proteção para PostgreSQL/MySQL
- **Containers** - Proteção para Containers
- **CosmosDbs** - Proteção para Cosmos DB
- **CloudPosture** - CSPM (Cloud Security Posture Management)
- **Api** - Proteção para APIs

## Uso Básico

```hcl
module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  resource_type = "VirtualMachines"
  tier          = "Standard"

  email_security_contact = "security@company.com"
  phone_security_contact = "+1234567890"

  log_analytics_workspace_id = module.log_analytics.id
}
```

## Exemplo com Múltiplos Planos

```hcl
module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  security_center_pricing = {
    VirtualMachines = {
      tier    = "Standard"
      subplan = "P2"
      extensions = [
        {
          name = "AgentlessVmScanning"
          additional_extension_properties = {
            ExclusionTags = "[]"
          }
        }
      ]
    }
    SqlServers = {
      tier = "Standard"
    }
    AppServices = {
      tier = "Standard"
    }
    StorageAccounts = {
      tier = "Standard"
      extensions = [
        {
          name = "OnUploadMalwareScanning"
          additional_extension_properties = {
            CapGBPerMonthPerStorageAccount = "5000"
          }
        }
      ]
    }
    KubernetesService = {
      tier = "Standard"
    }
    ContainerRegistry = {
      tier = "Standard"
    }
    KeyVaults = {
      tier = "Standard"
    }
    Dns = {
      tier = "Standard"
    }
    Arm = {
      tier = "Standard"
    }
    Containers = {
      tier = "Standard"
    }
  }

  email_security_contact       = "security-team@company.com"
  phone_security_contact       = "+5511999999999"
  alert_notifications_enabled  = true
  alerts_to_admins_enabled     = true

  auto_provisioning = {
    enabled                    = true
    log_analytics_workspace_id = module.log_analytics.id
  }

  log_analytics_workspace_id = module.log_analytics.id

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Workflow Automation

```hcl
module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  security_center_pricing = {
    VirtualMachines = {
      tier = "Standard"
    }
  }

  email_security_contact = "security@company.com"

  workflow_automations = [
    {
      name                = "alert-to-logic-app"
      location            = "eastus"
      resource_group_name = "rg-security-prod"
      description         = "Send high severity alerts to Logic App"
      enabled             = true
      scopes              = ["/subscriptions/${data.azurerm_subscription.current.id}"]

      sources = [
        {
          event_source = "Alerts"
          rule_sets = [
            {
              rules = [
                {
                  property_path  = "properties.metadata.severity"
                  operator       = "Equals"
                  expected_value = "High"
                  property_type  = "String"
                }
              ]
            }
          ]
        }
      ]

      actions = [
        {
          type        = "LogicApp"
          resource_id = azurerm_logic_app_workflow.security_alerts.id
        }
      ]

      tags = {
        Purpose = "SecurityAutomation"
      }
    }
  ]
}
```

## Exemplo com Just-In-Time VM Access

```hcl
module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  security_center_pricing = {
    VirtualMachines = {
      tier = "Standard"
    }
  }

  email_security_contact = "security@company.com"
  log_analytics_workspace_id = module.log_analytics.id

  jit_policies = [
    {
      name                = "jit-policy-prod-vms"
      location            = "eastus"
      resource_group_name = "rg-compute-prod"
      virtual_machine_ids = [
        azurerm_linux_virtual_machine.app01.id,
        azurerm_linux_virtual_machine.app02.id
      ]
      rules = [
        {
          number                        = 22
          protocol                      = "Tcp"
          allowed_source_address_prefix = "*"
          max_request_access_duration   = "PT3H"
        },
        {
          number                        = 3389
          protocol                      = "Tcp"
          allowed_source_address_prefix = "10.0.0.0/16"
          max_request_access_duration   = "PT2H"
        }
      ]
    }
  ]
}
```

## Exemplo com Advanced Threat Protection

```hcl
module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  security_center_pricing = {
    StorageAccounts = {
      tier = "Standard"
    }
  }

  email_security_contact = "security@company.com"

  advanced_threat_protection = [
    {
      target_resource_id = module.storage_account_data.id
      enabled            = true
    },
    {
      target_resource_id = module.storage_account_logs.id
      enabled            = true
    },
    {
      target_resource_id = module.cosmos_db.id
      enabled            = true
    }
  ]
}
```

## Exemplo com Defender for Containers

```hcl
module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  security_center_pricing = {
    Containers = {
      tier = "Standard"
      extensions = [
        {
          name = "ContainerRegistriesVulnerabilityAssessments"
          additional_extension_properties = {}
        }
      ]
    }
    ContainerRegistry = {
      tier = "Standard"
    }
    KubernetesService = {
      tier = "Standard"
    }
  }

  email_security_contact = "security@company.com"
  log_analytics_workspace_id = module.log_analytics.id

  defender_for_containers_settings = {
    scan_images_on_push                = true
    agentless_vulnerability_assessment = true
    runtime_threat_protection          = true
  }

  auto_provisioning = {
    enabled = true
  }
}
```

## Exemplo Completo - Empresa

```hcl
data "azurerm_subscription" "current" {}

module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  subscription_id = data.azurerm_subscription.current.subscription_id

  # Habilitar todos os planos Defender
  security_center_pricing = {
    VirtualMachines = {
      tier    = "Standard"
      subplan = "P2"
      extensions = [
        {
          name = "AgentlessVmScanning"
        },
        {
          name = "MdeDesignatedSubscription"
        }
      ]
    }
    SqlServers = {
      tier = "Standard"
    }
    AppServices = {
      tier = "Standard"
    }
    StorageAccounts = {
      tier = "Standard"
      extensions = [
        {
          name = "OnUploadMalwareScanning"
          additional_extension_properties = {
            CapGBPerMonthPerStorageAccount = "10000"
          }
        },
        {
          name = "SensitiveDataDiscovery"
        }
      ]
    }
    KubernetesService = {
      tier = "Standard"
    }
    ContainerRegistry = {
      tier = "Standard"
    }
    KeyVaults = {
      tier = "Standard"
    }
    Dns = {
      tier = "Standard"
    }
    Arm = {
      tier = "Standard"
    }
    OpenSourceRelationalDatabases = {
      tier = "Standard"
    }
    Containers = {
      tier = "Standard"
    }
    CosmosDbs = {
      tier = "Standard"
    }
    CloudPosture = {
      tier = "Standard"
    }
    Api = {
      tier = "Standard"
    }
  }

  # Contatos de segurança
  security_contacts = [
    {
      name                = "primary"
      email               = "security-primary@company.com"
      phone               = "+5511999998888"
      alert_notifications = true
      alerts_to_admins    = true
    },
    {
      name                = "secondary"
      email               = "security-backup@company.com"
      alert_notifications = true
      alerts_to_admins    = false
    }
  ]

  # Auto-provisioning e integração
  auto_provisioning = {
    enabled                    = true
    log_analytics_workspace_id = module.log_analytics.id
  }

  log_analytics_workspace_id = module.log_analytics.id

  # Workflow Automations
  workflow_automations = [
    {
      name                = "critical-alerts-to-teams"
      location            = "eastus"
      resource_group_name = "rg-security-prod"
      description         = "Send critical alerts to Microsoft Teams"
      enabled             = true
      scopes              = [data.azurerm_subscription.current.id]

      sources = [
        {
          event_source = "Alerts"
          rule_sets = [
            {
              rules = [
                {
                  property_path  = "properties.metadata.severity"
                  operator       = "Equals"
                  expected_value = "High"
                  property_type  = "String"
                }
              ]
            }
          ]
        }
      ]

      actions = [
        {
          type        = "LogicApp"
          resource_id = azurerm_logic_app_workflow.teams_alerts.id
        }
      ]
    },
    {
      name                = "compliance-violations-to-email"
      location            = "eastus"
      resource_group_name = "rg-security-prod"
      description         = "Email compliance violations"
      enabled             = true
      scopes              = [data.azurerm_subscription.current.id]

      sources = [
        {
          event_source = "RegulatoryComplianceAssessment"
        }
      ]

      actions = [
        {
          type        = "LogicApp"
          resource_id = azurerm_logic_app_workflow.compliance_email.id
        }
      ]
    }
  ]

  # JIT Policies
  jit_policies = [
    {
      name                = "jit-production-vms"
      location            = "eastus"
      resource_group_name = "rg-compute-prod"
      virtual_machine_ids = module.virtual_machines_prod[*].id
      rules = [
        {
          number                        = 22
          protocol                      = "Tcp"
          allowed_source_address_prefix = "10.0.0.0/8"
          max_request_access_duration   = "PT3H"
        }
      ]
    }
  ]

  # Advanced Threat Protection
  advanced_threat_protection = [
    {
      target_resource_id = module.storage_prod.id
      enabled            = true
    },
    {
      target_resource_id = module.storage_logs.id
      enabled            = true
    },
    {
      target_resource_id = module.cosmos_db_prod.id
      enabled            = true
    }
  ]

  defender_cspm_enabled = true
  mcsb_enabled          = true

  tags = {
    Environment = "Production"
    CostCenter  = "Security"
    Compliance  = "ISO27001,SOC2,HIPAA"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| subscription_id | ID da subscription | `string` | current | não |
| resource_type | Tipo de recurso (único) | `string` | `null` | não* |
| tier | Tier (Standard/Free) | `string` | `"Standard"` | não |
| subplan | Subplan (P1/P2) | `string` | `null` | não |
| extensions | Extensões do plano | `list(object)` | `[]` | não |
| security_center_pricing | Múltiplos planos | `map(object)` | `{}` | não* |
| email_security_contact | Email de contato | `string` | `null` | não** |
| phone_security_contact | Telefone de contato | `string` | `null` | não |
| security_contacts | Lista de contatos | `list(object)` | `[]` | não** |
| alert_notifications_enabled | Notificações | `bool` | `true` | não |
| alerts_to_admins_enabled | Alertas para admins | `bool` | `true` | não |
| auto_provisioning | Config auto-provisioning | `object` | ver abaixo | não |
| log_analytics_workspace_id | Workspace ID | `string` | `null` | não |
| workflow_automations | Automações | `list(object)` | `[]` | não |
| jit_policies | Políticas JIT | `list(object)` | `[]` | não |
| advanced_threat_protection | ATP configs | `list(object)` | `[]` | não |
| defender_for_containers_settings | Containers settings | `object` | `{}` | não |
| defender_cspm_enabled | Habilitar CSPM | `bool` | `false` | não |
| mcsb_enabled | Habilitar MCSB | `bool` | `true` | não |
| tags | Tags | `map(string)` | `{}` | não |

\* Você deve fornecer `resource_type` OU `security_center_pricing`  
\** Você deve fornecer `email_security_contact` OU `security_contacts`

### Auto Provisioning Padrão

```hcl
{
  enabled = true
}
```

## Outputs

| Nome | Descrição |
|------|-----------|
| subscription_id | ID da subscription |
| pricing_tiers | Tiers configurados |
| pricing_ids | IDs dos pricings |
| security_contacts | Contatos configurados |
| security_contact_ids | IDs dos contatos |
| auto_provisioning_enabled | Status auto-provisioning |
| auto_provisioning_id | ID auto-provisioning |
| workspace_id | Workspace ID |
| workspace_integration_id | ID integração workspace |
| assessment_policies | Políticas de assessment |
| workflow_automations | Automações configuradas |
| workflow_automation_ids | IDs das automações |
| jit_policies | Políticas JIT |
| jit_policy_ids | IDs JIT |
| advanced_threat_protection | ATP configs |
| advanced_threat_protection_ids | IDs ATP |
| mcas_setting_id | ID MCAS |
| wdatp_setting_id | ID WDATP |
| sentinel_setting_id | ID Sentinel |
| defender_plans_summary | Resumo dos planos |
| security_posture | Postura de segurança |

## Planos Defender - Detalhes

### Defender for Servers (VirtualMachines)

**Subplans:**
- **P1**: Proteção básica com Microsoft Defender for Endpoint
- **P2**: Proteção completa com vulnerability assessment, JIT, file integrity monitoring

**Extensões:**
- `AgentlessVmScanning` - Scan sem agente
- `MdeDesignatedSubscription` - MDE subscription designada

**Custo:** ~$15/servidor/mês (P1), ~$20/servidor/mês (P2)

### Defender for SQL

Protege:
- Azure SQL Database
- SQL Managed Instance
- SQL Server em VMs

**Recursos:**
- Vulnerability Assessment
- Threat Detection
- Data Discovery & Classification

**Custo:** ~$15/servidor/mês

### Defender for App Service

Protege Web Apps, Function Apps, API Apps

**Recursos:**
- Threat detection para ataques web
- Análise de tráfego
- Detecção de malware

**Custo:** ~$2.50/App Service/mês

### Defender for Storage

**Extensões:**
- `OnUploadMalwareScanning` - Scan de malware no upload
- `SensitiveDataDiscovery` - Descoberta de dados sensíveis

**Recursos:**
- Malware scanning
- Detecção de acesso suspeito
- Proteção contra ransomware

**Custo:** ~$0.02/10k transações

### Defender for Kubernetes (KubernetesService)

Protege clusters AKS

**Recursos:**
- Runtime threat protection
- Vulnerability assessment
- Configuration assessment
- Azure Policy integration

**Custo:** ~$7/vCore/mês

### Defender for Container Registries

Protege Azure Container Registry

**Recursos:**
- Vulnerability scanning de imagens
- Compliance scanning
- Continuous scanning

**Custo:** ~$0.29/imagem scaneada

### Defender for Key Vault

**Recursos:**
- Detecção de acesso anômalo
- Proteção contra vazamento de secrets
- Threat intelligence

**Custo:** ~$0.02/10k transações

### Defender for DNS

**Recursos:**
- Detecção de DNS tunneling
- Detecção de C2 communication
- Análise de queries DNS

**Custo:** ~$0.70/milhão queries

### Defender for Resource Manager (Arm)

**Recursos:**
- Detecção de operações suspeitas
- Análise de deployment
- Proteção contra privilege escalation

**Custo:** ~$2/milhão operações

### Defender for Open-Source Databases

Protege PostgreSQL, MySQL, MariaDB

**Recursos:**
- Threat detection
- Anomaly detection
- Brute force detection

**Custo:** ~$15/servidor/mês

### Defender for Containers (novo)

Substitui Defender for Kubernetes e Container Registry

**Recursos:**
- Runtime protection
- Vulnerability assessment
- Compliance
- Network policy recommendations

**Custo:** Variável por uso

### Defender CSPM (Cloud Security Posture Management)

**Recursos:**
- Security posture assessment
- Compliance dashboard
- Attack path analysis
- Cloud security graph

**Custo:** Grátis (básico), ~$5/recurso/mês (premium)

### Defender for APIs

**Recursos:**
- API discovery
- Security posture
- Runtime protection
- Threat detection

**Custo:** ~$3.50/milhão chamadas

## Just-In-Time VM Access

### Como Funciona

1. Portas administrativas fechadas por padrão
2. Usuário solicita acesso temporário
3. Defender valida permissões
4. Acesso concedido por período limitado
5. Porta fecha automaticamente

### Duração de Acesso

Formato: ISO 8601 Duration (PT#H ou PT#M)
- `PT3H` = 3 horas
- `PT30M` = 30 minutos
- `PT1H30M` = 1 hora e 30 minutos

### Solicitar Acesso JIT

```bash
# Via Azure CLI
az security jit-policy start \
  --resource-group rg-compute-prod \
  --location eastus \
  --name jit-policy-prod-vms \
  --virtual-machines "/subscriptions/.../vm1" \
  --port 22 \
  --source-address-prefix "203.0.113.10"
```

## Workflow Automations

### Event Sources Disponíveis

- **Alerts** - Alertas de segurança
- **Assessments** - Resultados de assessments
- **AssessmentsSnapshot** - Snapshot de assessments
- **RegulatoryComplianceAssessment** - Compliance regulatório
- **RegulatoryComplianceAssessmentSnapshot** - Snapshot compliance
- **SecureScores** - Secure score changes
- **SecureScoresSnapshot** - Snapshot secure score
- **SecureScoreControls** - Mudanças em controles
- **SecureScoreControlsSnapshot** - Snapshot controles

### Action Types

- **LogicApp** - Trigger Logic App
- **EventHub** - Enviar para Event Hub
- **Webhook** - Chamar webhook

### Exemplo de Regra

```hcl
rules = [
  {
    property_path  = "properties.metadata.severity"
    operator       = "Equals"
    expected_value = "High"
    property_type  = "String"
  },
  {
    property_path  = "properties.status"
    operator       = "Contains"
    expected_value = "Active"
    property_type  = "String"
  }
]
```

### Operators Disponíveis

- `Equals`
- `NotEquals`
- `Contains`
- `StartsWith`
- `EndsWith`

## Integração com Logic Apps

### Exemplo: Enviar Alertas para Teams

```hcl
# Logic App para Teams
resource "azurerm_logic_app_workflow" "teams_alerts" {
  name                = "security-alerts-teams"
  location            = "eastus"
  resource_group_name = "rg-security-prod"
}

resource "azurerm_logic_app_trigger_http_request" "teams" {
  name         = "defender-alert"
  logic_app_id = azurerm_logic_app_workflow.teams_alerts.id
  schema       = file("${path.module}/schemas/defender-alert.json")
}

resource "azurerm_logic_app_action_custom" "teams_post" {
  name         = "post-to-teams"
  logic_app_id = azurerm_logic_app_workflow.teams_alerts.id

  body = jsonencode({
    type = "Http"
    inputs = {
      method = "POST"
      uri    = "<TEAMS_WEBHOOK_URL>"
      body = {
        text = "Security Alert: @{triggerBody()?['AlertDisplayName']}"
      }
    }
  })
}

module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  workflow_automations = [
    {
      name                = "teams-alerts"
      location            = "eastus"
      resource_group_name = "rg-security-prod"
      scopes              = [data.azurerm_subscription.current.id]

      sources = [{
        event_source = "Alerts"
        rule_sets = [{
          rules = [{
            property_path  = "properties.metadata.severity"
            operator       = "Equals"
            expected_value = "High"
            property_type  = "String"
          }]
        }]
      }]

      actions = [{
        type        = "LogicApp"
        resource_id = azurerm_logic_app_workflow.teams_alerts.id
      }]
    }
  ]
}
```

## Integração com Sentinel

Quando `log_analytics_workspace_id` é configurado, o Defender automaticamente integra com o Sentinel se ele estiver habilitado no workspace.

```hcl
# Habilitar Sentinel
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "main" {
  workspace_id = module.log_analytics.id
}

# Configurar Defender
module "defender_for_cloud" {
  source = "./modules/defender_for_cloud"

  log_analytics_workspace_id = module.log_analytics.id
  
  # ... outras configurações
}
```

## Secure Score

O Secure Score é calculado automaticamente baseado em:
- Configurações de segurança
- Vulnerabilidades descobertas
- Recomendações implementadas
- Políticas de compliance

### Melhorar Secure Score

1. ✅ Implementar recomendações do Defender
2. ✅ Habilitar mais planos Defender
3. ✅ Configurar auto-provisioning
4. ✅ Implementar JIT VM Access
5. ✅ Corrigir vulnerabilidades
6. ✅ Aplicar NSG rules
7. ✅ Habilitar disk encryption
8. ✅ Configurar backup

## Custos Estimados

### Cenário Pequeno (Startup)
- 5 VMs (P1): $75/mês
- 1 SQL Server: $15/mês
- 2 App Services: $5/mês
- 1 Storage Account: ~$1/mês
- **Total: ~$96/mês**

### Cenário Médio (Empresa)
- 50 VMs (P2): $1,000/mês
- 5 SQL Servers: $75/mês
- 10 App Services: $25/mês
- 5 Storage Accounts: ~$5/mês
- 2 AKS Clusters (16 vCores): $224/mês
- **Total: ~$1,329/mês**

### Cenário Grande (Enterprise)
- 500 VMs (P2): $10,000/mês
- 50 SQL Servers: $750/mês
- 100 App Services: $250/mês
- 50 Storage Accounts: ~$50/mês
- 10 AKS Clusters (80 vCores): $1,120/mês
- Defender CSPM Premium: ~$500/mês
- **Total: ~$12,670/mês**

## Best Practices

1. ✅ **Sempre habilite Defender for Servers (P2)** para VMs críticas
2. ✅ **Configure contatos de segurança** para receber alertas
3. ✅ **Integre com Log Analytics** para análise centralizada
4. ✅ **Habilite auto-provisioning** para deployment automático de agentes
5. ✅ **Configure JIT Access** para VMs com portas administrativas
6. ✅ **Implemente Workflow Automations** para resposta rápida
7. ✅ **Revise Secure Score** mensalmente e implemente recomendações
8. ✅ **Use ATP** em Storage e Cosmos DB para dados sensíveis
9. ✅ **Habilite Defender CSPM** para compliance
10. ✅ **Configure alertas** para mudanças em Secure Score

## Compliance Frameworks

Defender for Cloud suporta:
- **Azure Security Benchmark**
- **PCI DSS 3.2.1**
- **ISO 27001**
- **SOC 2 Type 2**
- **HIPAA/HITRUST**
- **NIST SP 800-53**
- **CIS Microsoft Azure Foundations Benchmark**
- **GDPR**

## Troubleshooting

### Agente não instalando
- Verifique se auto-provisioning está habilitado
- Confirme permissões da Managed Identity
- Verifique logs no Log Analytics

### JIT não funcionando
- Confirme que Defender for Servers está habilitado
- Verifique NSG rules
- Valide permissões RBAC

### Alertas não chegando
- Verifique contatos de segurança
- Confirme workflow automations
- Valide regras de filtering

### Custo alto inesperado
- Revise planos habilitados
- Verifique número de recursos protegidos
- Considere usar tier Free para ambientes de dev/test

## Limitações

- Alguns planos requerem tier Premium de recursos
- JIT requer NSG configurado
- Workflow Automations limitadas a 100 por subscription
- Alguns recursos não suportam ATP
- Propagação de configurações pode levar até 24h

## Recursos Criados

- `azurerm_security_center_subscription_pricing` - Planos Defender
- `azurerm_security_center_contact` - Contatos
- `azurerm_security_center_auto_provisioning` - Auto-provisioning
- `azurerm_security_center_workspace` - Integração workspace
- `azurerm_security_center_automation` - Automações
- `azurerm_security_center_jit_network_access_policy` - Políticas JIT
- `azurerm_advanced_threat_protection` - ATP
- `azurerm_security_center_setting` - Configurações

## Dependências

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription Owner ou Security Admin role
- Log Analytics Workspace (recomendado)

## Referências

- [Defender for Cloud Documentation](https://docs.microsoft.com/azure/defender-for-cloud/)
- [Pricing](https://azure.microsoft.com/pricing/details/defender-for-cloud/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_subscription_pricing)