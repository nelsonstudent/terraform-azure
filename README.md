# Azure Terraform Modules

> Coleção completa e padronizada de módulos Terraform para provisionamento de infraestrutura no Microsoft Azure

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Índice

- [Visão Geral](#visão-geral)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Módulos Disponíveis](#módulos-disponíveis)
- [Pré-requisitos](#pré-requisitos)
- [Início Rápido](#início-rápido)
- [Uso dos Módulos](#uso-dos-módulos)
- [Exemplos Práticos](#exemplos-práticos)
- [Padrões e Convenções](#padrões-e-convenções)
- [Contribuindo](#contribuindo)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)

## Visão Geral

Esta biblioteca fornece módulos Terraform reutilizáveis, testados e documentados para provisionamento de infraestrutura no Microsoft Azure. Cada módulo segue as melhores práticas de governança, segurança e operação, permitindo que equipes implementem infraestrutura como código de forma consistente e eficiente.

### Características

- ✅ **27 módulos** cobrindo todas as áreas principais do Azure
- ✅ **Documentação completa** com exemplos práticos para cada módulo
- ✅ **Governança integrada** com suporte a tags, locks, RBAC e policies
- ✅ **Segurança por padrão** com configurações otimizadas
- ✅ **Modular e componível** - use apenas o que precisa
- ✅ **Validações de entrada** para prevenir erros comuns
- ✅ **Outputs padronizados** facilitando integração entre módulos
- ✅ **Exemplos reais** de uso em diferentes cenários

## Estrutura do Projeto

```
azure-terraform-modules/
├── modules/
│   ├── ci_cd/
│   │   └── azure_devops/              # CI/CD e pipelines
│   │
│   ├── compute/
│   │   ├── aks/                       # Kubernetes gerenciado
│   │   ├── app_service/               # Serverless functions
│   │   ├── azure_functions/           # Web Apps e API Apps
│   │   ├── container_apps/            # Containers serverless
│   │   └── virtual_machine/           # VMs Windows/Linux
│   │
│   ├── database/
│   │   ├── cosmos_db/                 # NoSQL multi-modelo 
│   │   ├── postgresql_flexible/       # PostgreSQL gerenciado
│   │   ├── redis_cache /              # Cache em memória 
│   │   ├── sql_database/              # SQL Server gerenciado 
│   │   └── storage_account/           # Blob, Files, Tables, Queues 
│   │
│   ├── network/
│   │   ├── virtual_network/           # VNet, Subnets, NSGs
│   │   ├── application_gateway/       # Load Balancer L7 + WAF
│   │   ├── load_balancer/             # Load Balancer L4
│   │   ├── nat_gateway/               # NAT para saída
│   │   ├── azure_dns/                 # DNS gerenciado
│   │   └── expressroute/              # Conectividade dedicada
│   │
│   ├── observability/
│   │   ├── azure_monitor/             # Monitoramento e alertas
│   │   ├── log_analytics_workspace/   # Agregação de logs
│   │   └── application_insights/      # APM e telemetria
│   │
│   ├── security/
│   │   ├── entra_id/                  # Identidade e acesso (Azure AD)
│   │   ├── key_vault/                 # Secrets e certificados
│   │   ├── managed_identity/          # Identidades gerenciadas
│   │   └── defender_for_cloud/        # Postura de segurança
│   │
│   └── governance/
│       ├── resource_group/            # Agrupamento de recursos
│       ├── management_group/          # Hierarquia organizacional
│       └── azure_policy/              # Compliance e governança
│
└── README.md
```

## Módulos Disponíveis

### CI/CD (1 módulo)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| [azure_devops](modules/ci_cd/azure_devops/) | Pipelines, repos, trabalhos e agentes | ✅ Completo |

### Compute (5 módulos)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| [app_service](modules/compute/app_service/) | Web Apps, API Apps, Function Apps | ✅ Completo |
| [azure_functions](modules/compute/azure_functions/) | Functions serverless | ✅ Completo |
| [container_apps](modules/compute/container_apps/) | Containers serverless com escala automática | ✅ Completo |
| [aks](modules/compute/aks/) | Azure Kubernetes Service | ✅ Completo |
| [virtual_machine](modules/compute/virtual_machine/) | VMs Windows e Linux | ✅ Completo |

### Database (5 módulos)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| [sql_database](modules/database/sql_database/) | Azure SQL Database | ✅ Completo |
| [cosmos_db](modules/database/cosmos_db/) | Cosmos DB (NoSQL multi-modelo) | ✅ Completo |
| [storage_account](modules/database/storage_account/) | Blob, Files, Tables, Queues | ✅ Completo |
| [redis_cache](modules/database/redis_cache/) | Azure Cache for Redis | ✅ Completo |
| [postgresql_flexible](modules/database/postgresql_flexible/) | PostgreSQL Flexible Server | ✅ Completo |

### Network (7 módulos)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| [virtual_network](modules/network/virtual_network/) | VNet, Subnets, NSGs, Peering | ✅ Completo |
| [application_gateway](modules/network/application_gateway/) | Load Balancer L7 com WAF | ✅ Completo |
| [load_balancer](modules/network/load_balancer/) | Load Balancer L4 | ✅ Completo |
| [nat_gateway](modules/network/nat_gateway/) | NAT Gateway | ✅ Completo |
| [azure_dns](modules/network/azure_dns/) | DNS Zone gerenciado | ✅ Completo |
| [expressroute](modules/network/expressroute/) | ExpressRoute Circuit | ✅ Completo |

### Observability (3 módulos)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| [azure_monitor](modules/observability/azure_monitor/) | Alertas e action groups | ✅ Completo |
| [log_analytics_workspace](modules/observability/log_analytics_workspace/) | Workspace para logs | ✅ Completo |
| [application_insights](modules/observability/application_insights/) | APM e telemetria | ✅ Completo |

### Security (4 módulos)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| [entra_id](modules/security/entra_id/) | Azure AD, grupos, aplicações | ✅ Completo |
| [key_vault](modules/security/key_vault/) | Secrets, keys, certificados | ✅ Completo |
| [managed_identity](modules/security/managed_identity/) | User-Assigned Identities | ✅ Completo |
| [defender_for_cloud](modules/security/defender_for_cloud/) | Security posture e compliance | ✅ Completo |

### Governance (3 módulos)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| [resource_group](modules/governance/resource_group/) | Resource Groups com locks e budgets | ✅ Completo |
| [management_group](modules/governance/management_group/) | Hierarquia organizacional | ✅ Completo |
| [azure_policy](modules/governance/azure_policy/) | Policies, initiatives, assignments | ✅ Completo |

**Total: 27 módulos prontos para uso**

## Pré-requisitos

### Software Necessário

- **Terraform** >= 1.0
- **Azure CLI** >= 2.30
- **Git** (para clonar o repositório)

### Credenciais Azure

```bash
# Login via Azure CLI
az login

# Definir subscription padrão
az account set --subscription "sua-subscription-id"

# Verificar conta atual
az account show
```

### Permissões Necessárias

Para usar os módulos, você precisará de:
- **Contributor** ou **Owner** na subscription/resource group
- **User Access Administrator** (para RBAC assignments)
- **Policy Contributor** (para Azure Policies)

## Início Rápido

### 1. Clone o Repositório

```bash
git clone https://github.com/seu-org/azure-terraform-modules.git
cd azure-terraform-modules
```

### 2. Crie Sua Infraestrutura

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
module "resource_group" {
  source = "./modules/governance/resource_group"

  name             = "rg-myapp-prod"
  location         = "eastus"
  prevent_deletion = true

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
module "virtual_network" {
  source = "./modules/network/virtual_network"

  name                = "vnet-myapp-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "subnet-app" = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }

  tags = module.resource_group.tags
}

# App Service
module "app_service" {
  source = "./modules/compute/app_service"

  name                = "app-myapp-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  
  sku_name = "P1v3"

  app_settings = {
    "ENVIRONMENT" = "Production"
  }

  tags = module.resource_group.tags
}
```

### 3. Inicialize e Aplique

```bash
# Inicializar Terraform
terraform init

# Ver plano de execução
terraform plan

# Aplicar mudanças
terraform apply
```

## Uso dos Módulos

### Padrão de Uso

Todos os módulos seguem o mesmo padrão de estrutura:

```hcl
module "nome_descritivo" {
  source = "./modules/categoria/nome_modulo"

  # Parâmetros obrigatórios
  name                = "recurso-nome"
  location            = "eastus"
  resource_group_name = "rg-nome"

  # Parâmetros opcionais
  tags = {
    Environment = "Production"
  }
}

# Usar outputs
output "recurso_id" {
  value = module.nome_descritivo.id
}
```

### Composição de Módulos

Os módulos são projetados para trabalhar juntos:

```hcl
# 1. Base - Resource Group
module "rg" {
  source   = "./modules/governance/resource_group"
  name     = "rg-app-prod"
  location = "eastus"
}

# 2. Rede
module "vnet" {
  source              = "./modules/network/virtual_network"
  name                = "vnet-app-prod"
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.0.0.0/16"]
}

# 3. Segurança
module "kv" {
  source              = "./modules/security/key_vault"
  name                = "kv-app-prod-001"
  resource_group_name = module.rg.name
  location            = module.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

# 4. Compute
module "app" {
  source              = "./modules/compute/app_service"
  name                = "app-prod-001"
  resource_group_name = module.rg.name
  location            = module.rg.location
  
  # Integrar com Key Vault
  app_settings = {
    "KEY_VAULT_URI" = module.kv.vault_uri
  }
}
```

## Exemplos Práticos

### Exemplo 1: Aplicação Web Simples

```hcl
# Web app com SQL Database
module "resource_group" {
  source   = "./modules/governance/resource_group"
  name     = "rg-webapp-prod"
  location = "eastus"
}

module "sql_server" {
  source              = "./modules/database/sql_database"
  server_name         = "sql-webapp-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  
  databases = {
    "appdb" = {
      max_size_gb = 10
      sku_name    = "S1"
    }
  }
}

module "app_service" {
  source              = "./modules/compute/app_service"
  name                = "app-webapp-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  
  app_settings = {
    "DB_CONNECTION_STRING" = module.sql_server.databases["appdb"].connection_string
  }
}
```

### Exemplo 2: Arquitetura Microserviços (AKS)

```hcl
# Cluster AKS com rede isolada
module "vnet" {
  source              = "./modules/network/virtual_network"
  name                = "vnet-aks-prod"
  resource_group_name = module.resource_group.name
  location            = "eastus"
  address_space       = ["10.1.0.0/16"]
  
  subnets = {
    "subnet-aks" = {
      address_prefixes = ["10.1.1.0/24"]
    }
  }
}

module "aks" {
  source              = "./modules/compute/aks"
  name                = "aks-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  
  default_node_pool = {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v3"
    vnet_subnet_id = module.vnet.subnet_ids["subnet-aks"]
  }
  
  network_profile = {
    network_plugin = "azure"
    network_policy = "calico"
  }
}

module "acr" {
  source              = "./modules/database/storage_account"
  name                = "acrprod001"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = "Premium"
}
```

### Exemplo 3: Landing Zone Enterprise

```hcl
# Hierarquia de Management Groups
module "mg_root" {
  source       = "./modules/governance/management_group"
  name         = "mg-company"
  display_name = "Company Root"
}

module "mg_platform" {
  source                     = "./modules/governance/management_group"
  name                       = "mg-platform"
  display_name               = "Platform"
  parent_management_group_id = module.mg_root.id
  
  child_management_groups = {
    "mg-connectivity" = { display_name = "Connectivity" }
    "mg-identity"     = { display_name = "Identity" }
    "mg-management"   = { display_name = "Management" }
  }
}

module "mg_landing_zones" {
  source                     = "./modules/governance/management_group"
  name                       = "mg-landing-zones"
  display_name               = "Landing Zones"
  parent_management_group_id = module.mg_root.id
  
  child_management_groups = {
    "mg-production"     = { display_name = "Production" }
    "mg-non-production" = { display_name = "Non-Production" }
  }
}

# Policies no Management Group raiz
module "policy_baseline" {
  source = "./modules/governance/azure_policy"
  
  policy_type  = "set_definition"
  name         = "security-baseline"
  display_name = "Security Baseline Initiative"
  
  management_group_id = module.mg_root.id
  
  policy_definitions = [
    # Múltiplas policies...
  ]
}
```

## Padrões e Convenções

### Nomenclatura de Recursos

Seguimos o padrão Microsoft para nomenclatura:

```
<tipo-recurso>-<workload>-<ambiente>-<região>-<instância>
```

Exemplos:
```hcl
# Resource Groups
rg-webapp-prod-eastus-001
rg-aks-staging-westus2-001

# Virtual Networks
vnet-hub-prod-eastus-001
vnet-spoke-app-prod-eastus-001

# App Services
app-api-prod-eastus-001
func-processor-prod-eastus-001

# Storage Accounts (sem hífens, máx 24 chars)
stwebappprod001
stlogsprod001
```

### Estrutura de Tags

Tags obrigatórias em todos os recursos:

```hcl
tags = {
  Environment  = "Production"           # Dev, Staging, Production
  Owner        = "team@company.com"     # Time responsável
  CostCenter   = "Engineering"          # Centro de custo
  Project      = "MyApp"                # Projeto
  ManagedBy    = "Terraform"            # Ferramenta de gestão
  Criticality  = "High"                 # High, Medium, Low
}
```

### Organização de Arquivos

```
seu-projeto/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── production/
│
├── modules/                 # Cópia ou referência aos módulos
│
└── shared/
    ├── backend.tf          # Configuração de backend
    └── provider.tf         # Configuração de providers
```

### Versionamento de Módulos

Use tags Git para versionar módulos:

```hcl
module "app_service" {
  source = "git::https://github.com/org/azure-terraform-modules.git//modules/compute/app_service?ref=v1.0.0"
  
  # ...
}
```

## Contribuindo

Contribuições são bem-vindas! Por favor, siga estas diretrizes:

### 1. Fork e Clone

```bash
git clone https://github.com/seu-usuario/azure-terraform-modules.git
cd azure-terraform-modules
git checkout -b feature/novo-modulo
```

### 2. Estrutura de Novo Módulo

Todo módulo deve conter:

```
modules/categoria/nome_modulo/
├── variables.tf      # Todas as variáveis de entrada
├── main.tf          # Lógica principal do módulo
├── outputs.tf       # Todos os outputs
├── README.md        # Documentação completa
└── examples/        # Exemplos de uso (opcional)
```

### 3. Documentação Obrigatória

Cada módulo deve ter README.md com:

- ✅ Descrição e características
- ✅ Exemplo de uso básico
- ✅ Tabela de inputs
- ✅ Tabela de outputs
- ✅ Exemplos práticos (mínimo 2)
- ✅ Best practices
- ✅ Troubleshooting

### 4. Padrões de Código

```hcl
# ✅ BOM - Variáveis com descrição e validação
variable "name" {
  description = "Nome do recurso"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Nome deve conter apenas letras minúsculas, números e hífens."
  }
}

# ✅ BOM - Outputs descritivos
output "id" {
  description = "ID do recurso criado"
  value       = azurerm_resource.main.id
}

# ❌ RUIM - Sem descrição
variable "name" {
  type = string
}
```

### 5. Teste Seus Módulos

```bash
# Validar sintaxe
terraform fmt -check -recursive

# Validar configuração
terraform validate

# Testar localmente
cd modules/categoria/seu_modulo
terraform init
terraform plan
```

### 6. Submit Pull Request

- Descreva claramente as mudanças
- Referencie issues relacionadas
- Adicione screenshots se relevante
- Certifique-se que CI/CD passa

## Troubleshooting

### Problemas Comuns

#### 1. Erro de Autenticação

```
Error: Unable to authenticate with Azure
```

**Solução:**
```bash
az login
az account set --subscription "sua-subscription-id"
```

#### 2. Conflito de Nomes

```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-name" already exists
```

**Solução:**
- Use nomes únicos globalmente para: Storage Accounts, Key Vaults, DNS Zones
- Adicione sufixos únicos: `${var.name}-${random_string.suffix.result}`

#### 3. Quota Excedida

```
Error: QuotaExceeded
```

**Solução:**
```bash
# Verificar quotas
az vm list-usage --location eastus --output table

# Solicitar aumento via portal Azure
```

#### 4. Estado Terraform Corrompido

```
Error: Error acquiring the state lock
```

**Solução:**
```bash
# Remover lock (USE COM CUIDADO)
terraform force-unlock <LOCK_ID>

# Ou re-inicializar backend
terraform init -reconfigure
```

### Debug Avançado

```bash
# Logs detalhados
export TF_LOG=DEBUG
terraform plan

# Validar provider
terraform providers

# Verificar state
terraform state list
terraform state show <recurso>
```

## Roadmap

### Em Desenvolvimento

- [ ] Módulo de Azure Backup
- [ ] Módulo de Azure Site Recovery
- [ ] Módulo de Azure Front Door
- [ ] Módulo de Azure API Management
- [ ] Módulo de Azure Service Bus

### Melhorias Planejadas

- [ ] Exemplos de arquiteturas completas
- [ ] CI/CD templates (GitHub Actions, Azure DevOps)
- [ ] Testes automatizados (Terratest)
- [ ] Documentação de custos estimados
- [ ] Guias de migração (AWS → Azure, GCP → Azure)
- [ ] Blueprints de compliance (PCI-DSS, HIPAA, ISO 27001)

### Integração com Ferramentas

- [ ] Checkov (security scanning)
- [ ] TFLint (linting)
- [ ] Infracost (cost estimation)
- [ ] Terraform Cloud/Enterprise

## Comparação com Cloud Providers

Para equipes migrando de outros cloud providers:

| Azure | AWS | GCP | OCI |
|-------|-----|-----|-----|
| App Service | Elastic Beanstalk | App Engine | Compute |
| Azure Functions | Lambda | Cloud Functions | OCI Functions |
| Container Apps | ECS Fargate | Cloud Run | Container Instances |
| AKS | EKS | GKE | OKE |
| Virtual Machine | EC2 | Compute Engine | Virtual Machines |
| SQL Database | RDS | Cloud SQL | ATP |
| Cosmos DB | DynamoDB | Firestore/Bigtable | Autonomous Database (JSON) / NoSQL Database |
| Storage Account | S3 | Cloud Storage | Object Storage |
| Virtual Network | VPC | VPC | Virtual Cloud Network (VCN) |
| Application Gateway | ALB | Cloud Load Balancing | Load Balancer / Application Gateway |
| Key Vault | Secrets Manager + KMS | Cloud KMS | Vault |
| Managed Identity | IAM Roles | Service Accounts | Identity and Access Management (IAM) Dynamic Groups |
| Azure Policy | Config Rules + SCP | Organization Policies | Cloud Guard / IAM Policies |

## 🔗 Recursos Úteis

### Documentação Oficial

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)
- [Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)

### Ferramentas

- [Azure CLI](https://docs.microsoft.com/cli/azure/)
- [Azure PowerShell](https://docs.microsoft.com/powershell/azure/)
- [VS Code Azure Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)
- [Terraform Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)

### Comunidade

- [Azure GitHub](https://github.com/Azure)
- [Terraform Registry](https://registry.terraform.io/)
- [Azure Reddit](https://reddit.com/r/AZURE)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)

