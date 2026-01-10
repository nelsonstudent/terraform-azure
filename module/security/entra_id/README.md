# Módulo Terraform - Microsoft Entra ID (Azure Active Directory)

Este módulo Terraform gerencia identidades e acessos no Microsoft Entra ID (anteriormente Azure Active Directory), incluindo usuários, grupos, aplicações, service principals, conditional access policies e muito mais.

## Recursos Criados

- **Users** - Usuários do Entra ID
- **Groups** - Grupos de segurança e Microsoft 365
- **Applications** - Application registrations
- **Service Principals** - Service principals para aplicações
- **Administrative Units** - Unidades administrativas
- **Conditional Access Policies** - Políticas de acesso condicional
- **Named Locations** - Localizações nomeadas para CA
- **Custom Directory Roles** - Roles customizadas
- **Group Memberships** - Associações de usuários a grupos

## Características

✅ Gerenciamento completo de usuários  
✅ Grupos de segurança e Microsoft 365  
✅ Application registrations  
✅ Service Principals  
✅ Conditional Access Policies  
✅ Administrative Units  
✅ Custom Directory Roles  
✅ Named Locations  
✅ Group memberships automatizados  
✅ API permissions configuration  
✅ App roles e OAuth2 scopes  
✅ Multi-tenant applications  

## Uso Básico - Usuários e Grupos

```hcl
module "entra_id" {
  source = "./modules/entra_id"

  # Usuários
  users = [
    {
      user_principal_name   = "john.doe@contoso.com"
      display_name          = "John Doe"
      password              = "ChangeMe123!"
      force_password_change = true
      usage_location        = "US"
      job_title             = "Software Engineer"
      department            = "Engineering"
    },
    {
      user_principal_name   = "jane.smith@contoso.com"
      display_name          = "Jane Smith"
      password              = "ChangeMe456!"
      force_password_change = true
      usage_location        = "US"
      job_title             = "Product Manager"
      department            = "Product"
    }
  ]

  # Grupos
  groups = [
    {
      display_name     = "Engineering Team"
      security_enabled = true
      description      = "Engineering department group"
    },
    {
      display_name     = "Product Team"
      security_enabled = true
      description      = "Product department group"
    }
  ]

  # Associações
  group_memberships = {
    "engineering-members" = {
      group_name  = "Engineering Team"
      member_upns = ["john.doe@contoso.com"]
    }
    "product-members" = {
      group_name  = "Product Team"
      member_upns = ["jane.smith@contoso.com"]
    }
  }
}
```

## Exemplo com Application Registration

```hcl
module "entra_id_apps" {
  source = "./modules/entra_id"

  # Application Registration
  applications = [
    {
      display_name     = "My Web App"
      sign_in_audience = "AzureADMyOrg"
      description      = "Internal web application"
      
      identifier_uris = [
        "api://mywebapp"
      ]
      
      # Web application configuration
      web = {
        homepage_url  = "https://mywebapp.contoso.com"
        logout_url    = "https://mywebapp.contoso.com/logout"
        redirect_uris = [
          "https://mywebapp.contoso.com/auth/callback"
        ]
        implicit_grant = {
          access_token_issuance_enabled = true
          id_token_issuance_enabled     = true
        }
      }
      
      # API Permissions
      required_resource_access = [
        {
          resource_app_id = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph
          resource_access = [
            {
              id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"  # User.Read
              type = "Scope"
            },
            {
              id   = "b340eb25-3456-403f-be2f-af7a0d370277"  # User.ReadBasic.All
              type = "Scope"
            }
          ]
        }
      ]
      
      # App Roles
      app_roles = [
        {
          allowed_member_types = ["User"]
          description         = "Administrators have full access"
          display_name        = "Administrator"
          id                  = "00000000-0000-0000-0000-000000000001"
          value               = "Admin"
          enabled             = true
        },
        {
          allowed_member_types = ["User"]
          description         = "Users have read-only access"
          display_name        = "User"
          id                  = "00000000-0000-0000-0000-000000000002"
          value               = "User"
          enabled             = true
        }
      ]
    }
  ]

  # Service Principal
  service_principals = [
    {
      display_name = "My Web App"
      app_role_assignment_required = true
      tags = ["WebApp", "Production"]
    }
  ]
}
```

## Exemplo com Conditional Access Policy

```hcl
module "entra_id_ca" {
  source = "./modules/entra_id"

  # Named Locations
  named_locations = [
    {
      display_name = "Corporate Network"
      ip_ranges    = ["203.0.113.0/24", "198.51.100.0/24"]
      trusted      = true
    },
    {
      display_name = "Home Office IPs"
      ip_ranges    = ["192.0.2.0/24"]
      trusted      = false
    }
  ]

  # Conditional Access Policy
  conditional_access_policies = [
    {
      display_name = "Require MFA for all users"
      state        = "enabled"
      
      conditions = {
        client_app_types = ["all"]
        
        applications = {
          included_applications = ["All"]
          excluded_applications = []
        }
        
        users = {
          included_users  = ["All"]
          excluded_users  = []
          included_groups = []
          excluded_groups = []
          included_roles  = []
          excluded_roles  = ["Global Administrator"]
        }
        
        locations = {
          included_locations = ["All"]
          excluded_locations = ["AllTrusted"]
        }
        
        platforms = {
          included_platforms = ["all"]
        }
      }
      
      grant_controls = {
        operator          = "OR"
        built_in_controls = ["mfa"]
      }
      
      session_controls = {
        sign_in_frequency        = 12
        sign_in_frequency_period = "hours"
      }
    },
    {
      display_name = "Block legacy authentication"
      state        = "enabled"
      
      conditions = {
        client_app_types = [
          "exchangeActiveSync",
          "other"
        ]
        
        applications = {
          included_applications = ["All"]
        }
        
        users = {
          included_users = ["All"]
          excluded_roles = ["Global Administrator"]
        }
      }
      
      grant_controls = {
        operator          = "OR"
        built_in_controls = ["block"]
      }
    }
  ]
}
```

## Exemplo Completo - Organização

```hcl
module "entra_id_organization" {
  source = "./modules/entra_id"

  # Usuários
  users = [
    # Executivos
    {
      user_principal_name = "ceo@contoso.com"
      display_name        = "Chief Executive Officer"
      job_title           = "CEO"
      department          = "Executive"
      usage_location      = "US"
      password            = var.ceo_password
    },
    {
      user_principal_name = "cto@contoso.com"
      display_name        = "Chief Technology Officer"
      job_title           = "CTO"
      department          = "Executive"
      usage_location      = "US"
      password            = var.cto_password
    },
    
    # Engineering
    {
      user_principal_name = "alice.dev@contoso.com"
      display_name        = "Alice Developer"
      job_title           = "Senior Software Engineer"
      department          = "Engineering"
      usage_location      = "US"
      password            = var.alice_password
    },
    {
      user_principal_name = "bob.dev@contoso.com"
      display_name        = "Bob Developer"
      job_title           = "Software Engineer"
      department          = "Engineering"
      usage_location      = "US"
      password            = var.bob_password
    },
    
    # Operations
    {
      user_principal_name = "ops.admin@contoso.com"
      display_name        = "Operations Admin"
      job_title           = "DevOps Engineer"
      department          = "Operations"
      usage_location      = "US"
      password            = var.ops_password
    }
  ]

  # Grupos Organizacionais
  groups = [
    {
      display_name     = "Executives"
      security_enabled = true
      description      = "Executive leadership team"
      assignable_to_role = true
    },
    {
      display_name     = "Engineering"
      security_enabled = true
      description      = "Engineering department"
    },
    {
      display_name     = "DevOps"
      security_enabled = true
      description      = "DevOps and Operations team"
    },
    {
      display_name     = "All Employees"
      security_enabled = true
      description      = "All company employees"
      types            = ["Unified"]
      mail_enabled     = true
      mail_nickname    = "allemployees"
    }
  ]

  # Group Memberships
  group_memberships = {
    "executives" = {
      group_name  = "Executives"
      member_upns = ["ceo@contoso.com", "cto@contoso.com"]
    }
    "engineering" = {
      group_name  = "Engineering"
      member_upns = ["alice.dev@contoso.com", "bob.dev@contoso.com"]
    }
    "devops" = {
      group_name  = "DevOps"
      member_upns = ["ops.admin@contoso.com"]
    }
    "all-employees" = {
      group_name = "All Employees"
      member_upns = [
        "ceo@contoso.com",
        "cto@contoso.com",
        "alice.dev@contoso.com",
        "bob.dev@contoso.com",
        "ops.admin@contoso.com"
      ]
    }
  }

  # Applications
  applications = [
    {
      display_name     = "Company Portal"
      sign_in_audience = "AzureADMyOrg"
      
      web = {
        homepage_url = "https://portal.contoso.com"
        redirect_uris = [
          "https://portal.contoso.com/auth/callback"
        ]
      }
      
      required_resource_access = [
        {
          resource_app_id = "00000003-0000-0000-c000-000000000000"
          resource_access = [
            {
              id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
              type = "Scope"
            }
          ]
        }
      ]
    }
  ]

  service_principals = [
    {
      display_name = "Company Portal"
      app_role_assignment_required = true
    }
  ]

  # Administrative Units
  administrative_units = [
    {
      display_name = "Engineering AU"
      description  = "Administrative unit for engineering department"
      members      = ["alice.dev@contoso.com", "bob.dev@contoso.com"]
    }
  ]

  # Conditional Access
  named_locations = [
    {
      display_name = "Office Network"
      ip_ranges    = ["203.0.113.0/24"]
      trusted      = true
    }
  ]

  conditional_access_policies = [
    {
      display_name = "Require MFA outside office"
      state        = "enabled"
      
      conditions = {
        client_app_types = ["all"]
        
        applications = {
          included_applications = ["All"]
        }
        
        users = {
          included_groups = [module.entra_id_organization.group_object_ids["All Employees"]]
          excluded_roles  = ["Global Administrator"]
        }
        
        locations = {
          included_locations = ["All"]
          excluded_locations = [module.entra_id_organization.named_location_ids["Office Network"]]
        }
      }
      
      grant_controls = {
        operator          = "OR"
        built_in_controls = ["mfa"]
      }
    }
  ]
}
```

## Exemplo Multi-Tenant Application

```hcl
module "entra_id_multitenant" {
  source = "./modules/entra_id"

  applications = [
    {
      display_name     = "SaaS Application"
      sign_in_audience = "AzureADMultipleOrgs"  # Multi-tenant
      description      = "Multi-tenant SaaS application"
      
      identifier_uris = [
        "api://saas-app"
      ]
      
      web = {
        homepage_url = "https://saas.contoso.com"
        redirect_uris = [
          "https://saas.contoso.com/signin-oidc"
        ]
      }
      
      required_resource_access = [
        {
          resource_app_id = "00000003-0000-0000-c000-000000000000"
          resource_access = [
            {
              id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
              type = "Scope"
            },
            {
              id   = "37f7f235-527c-4136-accd-4a02d197296e"
              type = "Scope"
            }
          ]
        }
      ]
      
      app_roles = [
        {
          allowed_member_types = ["User", "Application"]
          description         = "Full access to the application"
          display_name        = "FullAccess"
          id                  = "00000000-0000-0000-0000-000000000001"
          value               = "FullAccess"
          enabled             = true
        }
      ]
    }
  ]

  service_principals = [
    {
      display_name = "SaaS Application"
      app_role_assignment_required = false  # Multi-tenant
      tags = ["SaaS", "MultiTenant"]
    }
  ]
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `users` | Lista de usuários | `list(object)` | `[]` | Não |
| `groups` | Lista de grupos | `list(object)` | `[]` | Não |
| `group_memberships` | Associações de grupos | `map(object)` | `{}` | Não |
| `applications` | Application registrations | `list(object)` | `[]` | Não |
| `service_principals` | Service principals | `list(object)` | `[]` | Não |
| `conditional_access_policies` | Políticas CA | `list(object)` | `[]` | Não |
| `administrative_units` | Administrative units | `list(object)` | `[]` | Não |
| `named_locations` | Named locations | `list(object)` | `[]` | Não |
| `custom_directory_roles` | Custom roles | `list(object)` | `[]` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `tenant_id` | ID do tenant |
| `users` | Informações dos usuários |
| `user_object_ids` | Map UPN → Object ID |
| `groups` | Informações dos grupos |
| `group_object_ids` | Map nome → Object ID |
| `applications` | Informações das aplicações |
| `application_ids` | Application IDs (Client IDs) |
| `service_principals` | Informações dos SPs |
| `summary` | Resumo dos recursos |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## Graph API Permissions (Common)

### Microsoft Graph API
- **Application ID**: `00000003-0000-0000-c000-000000000000`

### Delegated Permissions (Scopes)
- `e1fe6dd8-ba31-4d61-89e7-88639da4683d` - User.Read
- `b340eb25-3456-403f-be2f-af7a0d370277` - User.ReadBasic.All
- `7427e0e9-2fba-42fe-b0c0-848c9e6a8182` - offline_access
- `37f7f235-527c-4136-accd-4a02d197296e` - openid
- `14dad69e-099b-42c9-810b-d002981feec1` - profile
- `64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0` - email

### Application Permissions (Roles)
- `df021288-bdef-4463-88db-98f22de89214` - User.Read.All
- `741f803b-c850-494e-b5df-cde7c675a1ca` - User.ReadWrite.All
- `5b567255-7703-4780-807c-7be8301ae99b` - Group.Read.All
- `62a82d76-70ea-41e2-9197-370581804d09` - Group.ReadWrite.All

## Sign-in Audience Types

- **AzureADMyOrg**: Single tenant (seu org apenas)
- **AzureADMultipleOrgs**: Multi-tenant (qualquer Azure AD)
- **AzureADandPersonalMicrosoftAccount**: Azure AD + contas pessoais
- **PersonalMicrosoftAccount**: Apenas contas pessoais

## Conditional Access - Grant Controls

### Built-in Controls
- **block**: Bloquear acesso
- **mfa**: Requer autenticação multifator
- **compliantDevice**: Requer dispositivo compatível
- **domainJoinedDevice**: Requer dispositivo domain-joined
- **approvedApplication**: Requer aplicação aprovada
- **compliantApplication**: Requer aplicação compatível
- **passwordChange**: Requer mudança de senha

## Conditional Access - Client App Types

- **all**: Todos os tipos
- **browser**: Navegadores
- **mobileAppsAndDesktopClients**: Apps móveis e desktop
- **exchangeActiveSync**: Exchange ActiveSync
- **other**: Outros (ex: legacy auth)

## Melhores Práticas

### Usuários
1. **Use strong passwords** - Mínimo 12 caracteres
2. **Force password change** - Primeiro login
3. **Set usage location** - Para licenciamento
4. **Use naming convention** - firstname.lastname@domain
5. **Populate job info** - Para relatórios

### Grupos
1. **Use security groups** - Para acesso
2. **Use Microsoft 365 groups** - Para colaboração
3. **Naming convention** - Prefixos claros
4. **Add descriptions** - Documente propósito
5. **Use role-assignable groups** - Para RBAC

### Aplicações
1. **Use least privilege** - API permissions mínimas
2. **Rotate secrets** - Regularmente
3. **Use certificate auth** - Quando possível
4. **Document app roles** - Claramente
5. **Test in dev first** - Antes de prod

### Conditional Access
1. **Start with report-only** - Teste antes
2. **Exclude break-glass** - Accounts de emergência
3. **Use named locations** - Para trusted networks
4. **Layer policies** - Múltiplas camadas
5. **Monitor sign-ins** - Logs regularmente

### Segurança
1. **Enable MFA** - Para todos usuários
2. **Block legacy auth** - Conditional Access
3. **Use managed identities** - Quando possível
4. **Implement PIM** - Para admin roles
5. **Regular access reviews** - Trimestral

## Troubleshooting

### User Creation Fails
- Verifique UPN único
- Confirme domínio verificado
- Valide password complexity
- Check license availability

### Application Permission Issues
- Verify API permissions
- Check admin consent
- Validate application ID
- Review service principal

### Conditional Access Blocks
- Check policy conditions
- Review user/group memberships
- Validate named locations
- Test with excluded user

### Group Membership Not Applied
- Wait for sync (pode levar minutos)
- Check dynamic rules
- Verify user object exists
- Review nested groups

## Limitações

### Free Tier
- Máximo 50,000 objects
- Basic reporting
- No Conditional Access
- No PIM

### Premium P1
- Unlimited objects
- Conditional Access
- Self-service password reset
- Advanced reporting

### Premium P2
- P1 features +
- Identity Protection
- Privileged Identity Management
- Access Reviews

## Requisitos

- Terraform >= 1.0
- Provider AzureAD ~> 2.0
- Azure AD tenant
- Global Administrator ou equivalent permissions
- Premium licenses (para CA, PIM)