# Azure DevOps Terraform Module

Módulo Terraform para provisionar e gerenciar recursos do Azure DevOps, incluindo projetos, repositórios, pipelines, variable groups, políticas de branch e ambientes.

## Funcionalidades

- ✅ Criação de projetos Azure DevOps com features configuráveis
- ✅ Gerenciamento de repositórios Git
- ✅ Configuração de pipelines CI/CD baseados em YAML
- ✅ Variable groups (com integração opcional ao Azure Key Vault)
- ✅ Service connections para Azure Resource Manager
- ✅ Políticas de branch (reviewers, build validation)
- ✅ Ambientes para deployment
- ✅ Times e permissões

## Pré-requisitos

- Terraform >= 1.0
- Azure DevOps organization
- Personal Access Token (PAT) com permissões adequadas
- Provider `microsoft/azuredevops` configurado

## Configuração do Provider

```hcl
provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/your-organization"
  personal_access_token = var.azuredevops_pat
}
```

## Uso Básico

```hcl
module "azure_devops" {
  source = "../../modules/ci_cd/azure_devops"

  project_name        = "my-project"
  project_description = "Projeto de exemplo"
  project_visibility  = "private"
  version_control     = "Git"
  work_item_template  = "Agile"

  enable_boards     = true
  enable_repos      = true
  enable_pipelines  = true
  enable_test_plans = false
  enable_artifacts  = true

  repositories = {
    "backend-api" = {
      default_branch = "refs/heads/main"
      init_type      = "Clean"
    }
    "frontend-app" = {
      default_branch = "refs/heads/main"
      init_type      = "Clean"
    }
  }

  pipelines = {
    "backend-ci" = {
      repository_name = "backend-api"
      branch_name     = "refs/heads/main"
      yaml_path       = "azure-pipelines.yml"
      variables = {
        "BuildConfiguration" = "Release"
        "DotNetVersion"      = "8.0.x"
      }
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Exemplo Completo

```hcl
module "azure_devops" {
  source = "../../modules/ci_cd/azure_devops"

  # Configuração do Projeto
  project_name        = "ecommerce-platform"
  project_description = "Plataforma de e-commerce completa"
  project_visibility  = "private"
  version_control     = "Git"
  work_item_template  = "Scrum"

  # Features
  enable_boards     = true
  enable_repos      = true
  enable_pipelines  = true
  enable_test_plans = true
  enable_artifacts  = true

  # Repositórios
  repositories = {
    "backend-api" = {
      default_branch = "refs/heads/main"
      init_type      = "Clean"
    }
    "frontend-web" = {
      default_branch = "refs/heads/main"
      init_type      = "Clean"
    }
    "mobile-app" = {
      default_branch = "refs/heads/main"
      init_type      = "Clean"
    }
  }

  # Service Connection
  create_service_connection    = true
  service_connection_name      = "azure-production"
  service_connection_description = "Connection to Azure Production Subscription"
  service_principal_id         = var.service_principal_id
  tenant_id                    = var.tenant_id
  subscription_id              = var.subscription_id
  subscription_name            = "Production Subscription"

  # Pipelines
  pipelines = {
    "backend-ci-cd" = {
      repository_name = "backend-api"
      branch_name     = "refs/heads/main"
      yaml_path       = "pipelines/azure-pipelines.yml"
      variables = {
        "BuildConfiguration" = "Release"
        "DotNetVersion"      = "8.0.x"
      }
    }
    "frontend-ci-cd" = {
      repository_name = "frontend-web"
      branch_name     = "refs/heads/main"
      yaml_path       = "azure-pipelines.yml"
      variables = {
        "NodeVersion" = "20.x"
      }
    }
  }

  # Variable Groups
  variable_groups = {
    "production-vars" = {
      description    = "Variáveis de produção"
      allow_access   = true
      variables = {
        "API_URL"     = "https://api.example.com"
        "Environment" = "production"
      }
      key_vault_name = "kv-prod-secrets"
    }
    "staging-vars" = {
      description    = "Variáveis de staging"
      allow_access   = true
      variables = {
        "API_URL"     = "https://api-staging.example.com"
        "Environment" = "staging"
      }
      key_vault_name = null
    }
  }

  # Branch Policies - Pull Request Reviews
  branch_policies = {
    "backend-main-policy" = {
      repository_name                = "backend-api"
      branch_name                    = "refs/heads/main"
      minimum_reviewers              = 2
      blocking                       = true
      submitter_can_vote             = false
      last_pusher_cannot_approve     = true
      allow_completion_with_rejects  = false
      reset_votes_on_push            = true
    }
    "frontend-main-policy" = {
      repository_name                = "frontend-web"
      branch_name                    = "refs/heads/main"
      minimum_reviewers              = 1
      blocking                       = true
      submitter_can_vote             = false
      last_pusher_cannot_approve     = true
      allow_completion_with_rejects  = false
      reset_votes_on_push            = true
    }
  }

  # Build Validation Policies
  build_validation_policies = {
    "backend-build-validation" = {
      repository_name   = "backend-api"
      branch_name       = "refs/heads/main"
      pipeline_name     = "backend-ci-cd"
      display_name      = "Backend Build Validation"
      blocking          = true
      valid_duration    = 720
      filename_patterns = ["*.cs", "*.csproj"]
    }
  }

  # Environments
  environments = {
    "development" = {
      description = "Ambiente de desenvolvimento"
    }
    "staging" = {
      description = "Ambiente de staging/homologação"
    }
    "production" = {
      description = "Ambiente de produção"
    }
  }

  # Teams
  teams = {
    "backend-team" = {
      description    = "Time de desenvolvimento backend"
      administrators = ["user1@example.com"]
      members        = ["user2@example.com", "user3@example.com"]
    }
    "frontend-team" = {
      description    = "Time de desenvolvimento frontend"
      administrators = ["user4@example.com"]
      members        = ["user5@example.com", "user6@example.com"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "ecommerce"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| project_name | Nome do projeto Azure DevOps | `string` | - | Sim |
| project_description | Descrição do projeto | `string` | `""` | Não |
| project_visibility | Visibilidade do projeto (private/public) | `string` | `"private"` | Não |
| version_control | Sistema de controle de versão (Git/Tfvc) | `string` | `"Git"` | Não |
| work_item_template | Template de work items | `string` | `"Agile"` | Não |
| enable_boards | Habilitar Azure Boards | `bool` | `true` | Não |
| enable_repos | Habilitar Azure Repos | `bool` | `true` | Não |
| enable_pipelines | Habilitar Azure Pipelines | `bool` | `true` | Não |
| enable_test_plans | Habilitar Azure Test Plans | `bool` | `false` | Não |
| enable_artifacts | Habilitar Azure Artifacts | `bool` | `true` | Não |
| repositories | Mapa de repositórios a criar | `map(object)` | `{}` | Não |
| pipelines | Mapa de pipelines a criar | `map(object)` | `{}` | Não |
| variable_groups | Mapa de variable groups | `map(object)` | `{}` | Não |
| branch_policies | Políticas de branch | `map(object)` | `{}` | Não |
| build_validation_policies | Políticas de validação de build | `map(object)` | `{}` | Não |
| environments | Ambientes para deployment | `map(object)` | `{}` | Não |
| teams | Times do projeto | `map(object)` | `{}` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| project_id | ID do projeto Azure DevOps |
| project_name | Nome do projeto |
| repository_ids | IDs dos repositórios criados |
| repository_urls | URLs dos repositórios |
| pipeline_ids | IDs dos pipelines |
| variable_group_ids | IDs dos variable groups |
| environment_ids | IDs dos ambientes |
| team_ids | IDs dos times |

## Integração com Azure Key Vault

Para integrar variable groups com Azure Key Vault:

1. Crie uma service connection primeiro (`create_service_connection = true`)
2. Configure o `key_vault_name` no variable group
3. Certifique-se de que o Service Principal tem permissões no Key Vault

```hcl
variable_groups = {
  "secrets-from-keyvault" = {
    description    = "Secrets do Key Vault"
    allow_access   = true
    variables      = {}  # Variáveis serão importadas do Key Vault
    key_vault_name = "kv-prod-secrets"
  }
}
```

## Boas Práticas

### 1. **Segurança**
- Use Workload Identity Federation para service connections
- Armazene secrets no Azure Key Vault
- Configure políticas de branch para branches principais
- Exija revisões de código (minimum 2 reviewers para produção)

### 2. **Organização**
- Use naming conventions consistentes
- Organize repositórios por domínio/serviço
- Crie teams baseados em responsabilidades
- Use tags para tracking de custos e organização

### 3. **CI/CD**
- Sempre use YAML pipelines (versionados no repositório)
- Configure build validation para branches protegidas
- Use variable groups para configurações por ambiente
- Implemente aprovações manuais para produção

### 4. **Branch Policies**
- Main/master sempre protegida
- Mínimo 2 reviewers para produção
- Build validation obrigatória
- Reset de votos ao fazer novos pushes

## Estrutura de Arquivos YAML Pipeline

Exemplo de `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: production-vars
  - name: buildConfiguration
    value: 'Release'

stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - task: UseDotNet@2
            inputs:
              version: '8.0.x'
          
          - task: DotNetCoreCLI@2
            displayName: 'dotnet build'
            inputs:
              command: 'build'
              projects: '**/*.csproj'
              arguments: '--configuration $(buildConfiguration)'
  
  - stage: Deploy
    dependsOn: Build
    condition: succeeded()
    jobs:
      - deployment: DeployJob
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploy to production"
```

## Troubleshooting

### Erro: "TF401019: The Git repository with name or identifier ... does not exist"
- Verifique se o repositório foi criado antes de referenciá-lo nos pipelines
- Use `depends_on` se necessário para garantir ordem de criação

### Erro: "Service connection not found"
- Certifique-se de que `create_service_connection = true`
- Verifique as credenciais do Service Principal

### Erro: "Access denied" ao criar políticas de branch
- O PAT precisa ter permissões de "Code (Full)"
- Verifique se o usuário tem permissões de admin no projeto

## Referências

- [Azure DevOps Terraform Provider](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs)
- [Azure Pipelines Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)
- [Azure DevOps REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
