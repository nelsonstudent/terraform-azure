# Módulo Terraform - Azure DNS

Este módulo Terraform cria e gerencia zonas DNS públicas e privadas no Azure com suporte a todos os tipos de registros DNS, VNet links para Private DNS, e integração com serviços Azure.

## Recursos Criados

- **Public DNS Zone** - Zona DNS pública para domínios na internet
- **Private DNS Zone** - Zona DNS privada para resolução interna
- **DNS Records** - A, AAAA, CNAME, MX, NS, PTR, SRV, TXT, CAA
- **VNet Links** - Vinculação de VNets à Private DNS Zone
- **Traffic Manager Records** - CNAMEs para Traffic Manager
- **Azure Service Records** - Registros para Private Link endpoints
- **Diagnostic Settings** - Monitoramento e logs (opcional)

## Características

✅ Public e Private DNS Zones  
✅ Todos os tipos de registros DNS  
✅ VNet linking para Private DNS  
✅ Auto-registro de VMs  
✅ SOA record customizado  
✅ CAA records para validação SSL  
✅ SRV records para service discovery  
✅ Traffic Manager integration  
✅ Private Link DNS records  
✅ DNSSEC support (Public DNS)  
✅ Diagnostic settings  
✅ Query logs  

## Uso Básico - Public DNS Zone

```hcl
module "public_dns" {
  source = "./modules/azure_dns"

  name                = "example.com"
  resource_group_name = "my-resource-group"
  zone_type           = "Public"
  create_public_zone  = true

  # A Records
  a_records = [
    {
      name    = "www"
      ttl     = 3600
      records = ["20.20.20.20"]
    },
    {
      name    = "@"
      ttl     = 3600
      records = ["20.20.20.20"]
    }
  ]

  # CNAME Records
  cname_records = [
    {
      name   = "blog"
      ttl    = 3600
      record = "www.example.com"
    }
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo Private DNS Zone

```hcl
module "private_dns" {
  source = "./modules/azure_dns"

  name                 = "internal.contoso.com"
  resource_group_name  = azurerm_resource_group.main.name
  zone_type            = "Private"
  create_private_zone  = true

  # VNet Links
  vnet_links = [
    {
      name                 = "hub-vnet-link"
      virtual_network_id   = azurerm_virtual_network.hub.id
      registration_enabled = true
    },
    {
      name                 = "spoke1-vnet-link"
      virtual_network_id   = azurerm_virtual_network.spoke1.id
      registration_enabled = false
    }
  ]

  # A Records
  a_records = [
    {
      name    = "sql-server"
      ttl     = 300
      records = ["10.0.1.10"]
    },
    {
      name    = "app-server"
      ttl     = 300
      records = ["10.0.1.20", "10.0.1.21"]
    }
  ]

  tags = {
    Environment = "Production"
    Type        = "Private"
  }
}
```

## Exemplo Completo com Múltiplos Tipos de Registros

```hcl
module "complete_dns" {
  source = "./modules/azure_dns"

  name                = "mycompany.com"
  resource_group_name = azurerm_resource_group.main.name
  zone_type           = "Public"
  create_public_zone  = true

  # SOA Record customizado
  soa_record = {
    email        = "admin.mycompany.com"
    refresh_time = 3600
    retry_time   = 300
    expire_time  = 2419200
    minimum_ttl  = 300
    ttl          = 3600
  }

  # A Records
  a_records = [
    {
      name    = "www"
      ttl     = 3600
      records = ["40.112.72.205"]
    },
    {
      name    = "api"
      ttl     = 3600
      records = ["40.112.72.206", "40.112.72.207"]
    }
  ]

  # AAAA Records (IPv6)
  aaaa_records = [
    {
      name    = "www"
      ttl     = 3600
      records = ["2001:0db8:85a3::8a2e:0370:7334"]
    }
  ]

  # CNAME Records
  cname_records = [
    {
      name   = "blog"
      ttl    = 3600
      record = "myblog.azurewebsites.net"
    },
    {
      name   = "cdn"
      ttl    = 3600
      record = "mycdn.azureedge.net"
    }
  ]

  # MX Records
  mx_records = [
    {
      name = "@"
      ttl  = 3600
      records = [
        {
          preference = 10
          exchange   = "mail1.mycompany.com"
        },
        {
          preference = 20
          exchange   = "mail2.mycompany.com"
        }
      ]
    }
  ]

  # TXT Records
  txt_records = [
    {
      name = "@"
      ttl  = 3600
      records = [
        "v=spf1 include:_spf.google.com ~all",
        "MS=ms12345678"
      ]
    },
    {
      name = "_dmarc"
      ttl  = 3600
      records = [
        "v=DMARC1; p=quarantine; rua=mailto:dmarc@mycompany.com"
      ]
    }
  ]

  # SRV Records
  srv_records = [
    {
      name = "_sip._tcp"
      ttl  = 3600
      records = [
        {
          priority = 10
          weight   = 60
          port     = 5060
          target   = "sip.mycompany.com"
        }
      ]
    }
  ]

  # CAA Records
  caa_records = [
    {
      name = "@"
      ttl  = 3600
      records = [
        {
          flags = 0
          tag   = "issue"
          value = "letsencrypt.org"
        },
        {
          flags = 0
          tag   = "issuewild"
          value = "letsencrypt.org"
        },
        {
          flags = 0
          tag   = "iodef"
          value = "mailto:security@mycompany.com"
        }
      ]
    }
  ]

  tags = {
    Environment = "Production"
    Domain      = "Primary"
  }
}
```

## Exemplo com Traffic Manager

```hcl
module "dns_with_traffic_manager" {
  source = "./modules/azure_dns"

  name                = "global.mycompany.com"
  resource_group_name = azurerm_resource_group.main.name
  zone_type           = "Public"
  create_public_zone  = true

  # Regular A Records
  a_records = [
    {
      name    = "www"
      ttl     = 3600
      records = ["40.112.72.205"]
    }
  ]

  # Traffic Manager Records
  create_traffic_manager_records = true
  traffic_manager_records = [
    {
      name                 = "app"
      ttl                  = 300
      traffic_manager_fqdn = "myapp.trafficmanager.net"
    },
    {
      name                 = "api"
      ttl                  = 300
      traffic_manager_fqdn = "myapi.trafficmanager.net"
    }
  ]

  tags = {
    Environment = "Production"
    LoadBalancer = "TrafficManager"
  }
}
```

## Exemplo Private DNS para Azure Services (Private Link)

```hcl
module "private_dns_azure_services" {
  source = "./modules/azure_dns"

  name                 = "privatelink.database.windows.net"
  resource_group_name  = azurerm_resource_group.main.name
  zone_type            = "Private"
  create_private_zone  = true

  # VNet Links
  vnet_links = [
    {
      name                 = "hub-vnet-link"
      virtual_network_id   = azurerm_virtual_network.hub.id
      registration_enabled = false
    }
  ]

  # Azure Service Records (Private Endpoints)
  create_azure_service_records = true
  azure_service_records = [
    {
      name       = "sql-server-prod"
      ip_address = "10.0.3.4"
      ttl        = 300
    },
    {
      name       = "sql-server-dev"
      ip_address = "10.0.3.5"
      ttl        = 300
    }
  ]

  tags = {
    Environment = "Production"
    Service     = "PrivateLink"
  }
}
```

## Exemplo Multi-Zone (Hub-Spoke)

```hcl
# Private DNS Zone para domínio interno
module "internal_dns" {
  source = "./modules/azure_dns"

  name                 = "internal.company.local"
  resource_group_name  = azurerm_resource_group.dns.name
  zone_type            = "Private"
  create_private_zone  = true

  # Link para Hub VNet com auto-registro
  vnet_links = [
    {
      name                 = "hub-vnet-link"
      virtual_network_id   = azurerm_virtual_network.hub.id
      registration_enabled = true
    },
    {
      name                 = "spoke1-vnet-link"
      virtual_network_id   = azurerm_virtual_network.spoke1.id
      registration_enabled = false
    },
    {
      name                 = "spoke2-vnet-link"
      virtual_network_id   = azurerm_virtual_network.spoke2.id
      registration_enabled = false
    }
  ]

  # Registros estáticos para serviços críticos
  a_records = [
    {
      name    = "dc01"
      ttl     = 300
      records = ["10.0.0.4"]
    },
    {
      name    = "dc02"
      ttl     = 300
      records = ["10.0.0.5"]
    }
  ]

  tags = {
    Environment = "Production"
    Scope       = "Enterprise"
  }
}

# Private DNS Zones para serviços Azure
locals {
  private_link_zones = [
    "privatelink.blob.core.windows.net",
    "privatelink.database.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.postgres.database.azure.com",
    "privatelink.redis.cache.windows.net"
  ]
}

module "azure_private_dns_zones" {
  for_each = toset(local.private_link_zones)
  source   = "./modules/azure_dns"

  name                 = each.value
  resource_group_name  = azurerm_resource_group.dns.name
  zone_type            = "Private"
  create_private_zone  = true

  vnet_links = [
    {
      name                 = "hub-vnet-link"
      virtual_network_id   = azurerm_virtual_network.hub.id
      registration_enabled = false
    }
  ]

  tags = {
    Environment = "Production"
    Service     = "PrivateLink"
    Zone        = each.value
  }
}
```

## Exemplo com Email (MX, TXT, SPF, DKIM, DMARC)

```hcl
module "email_dns" {
  source = "./modules/azure_dns"

  name                = "mycompany.com"
  resource_group_name = azurerm_resource_group.main.name
  zone_type           = "Public"
  create_public_zone  = true

  # MX Records
  mx_records = [
    {
      name = "@"
      ttl  = 3600
      records = [
        {
          preference = 1
          exchange   = "aspmx.l.google.com"
        },
        {
          preference = 5
          exchange   = "alt1.aspmx.l.google.com"
        },
        {
          preference = 5
          exchange   = "alt2.aspmx.l.google.com"
        },
        {
          preference = 10
          exchange   = "alt3.aspmx.l.google.com"
        },
        {
          preference = 10
          exchange   = "alt4.aspmx.l.google.com"
        }
      ]
    }
  ]

  # TXT Records (SPF, DKIM, DMARC, Domain Verification)
  txt_records = [
    {
      name = "@"
      ttl  = 3600
      records = [
        "v=spf1 include:_spf.google.com ~all",
        "google-site-verification=abc123xyz"
      ]
    },
    {
      name = "google._domainkey"
      ttl  = 3600
      records = [
        "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA..."
      ]
    },
    {
      name = "_dmarc"
      ttl  = 3600
      records = [
        "v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@mycompany.com; ruf=mailto:dmarc-forensics@mycompany.com; fo=1"
      ]
    }
  ]

  tags = {
    Environment = "Production"
    Service     = "Email"
  }
}
```

## Exemplo com Monitoring

```hcl
module "monitored_dns" {
  source = "./modules/azure_dns"

  name                = "monitored.example.com"
  resource_group_name = azurerm_resource_group.main.name
  zone_type           = "Public"
  create_public_zone  = true

  a_records = [
    {
      name    = "www"
      ttl     = 3600
      records = ["40.112.72.205"]
    }
  ]

  # Diagnostic Settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  diagnostic_logs = [
    "QueryLog"
  ]
  
  diagnostic_metrics = [
    "AllMetrics"
  ]

  tags = {
    Environment = "Production"
    Monitoring  = "Enabled"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome da DNS Zone | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `zone_type` | Tipo da zona (Public, Private) | `string` | `"Public"` | Não |
| `create_public_zone` | Criar Public DNS Zone | `bool` | `true` | Não |
| `create_private_zone` | Criar Private DNS Zone | `bool` | `false` | Não |
| `vnet_links` | VNet links (Private DNS) | `list(object)` | `[]` | Não |
| `a_records` | Registros A | `list(object)` | `[]` | Não |
| `aaaa_records` | Registros AAAA | `list(object)` | `[]` | Não |
| `cname_records` | Registros CNAME | `list(object)` | `[]` | Não |
| `mx_records` | Registros MX | `list(object)` | `[]` | Não |
| `txt_records` | Registros TXT | `list(object)` | `[]` | Não |
| `srv_records` | Registros SRV | `list(object)` | `[]` | Não |
| `caa_records` | Registros CAA | `list(object)` | `[]` | Não |
| `soa_record` | Registro SOA | `object` | `null` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID da DNS Zone |
| `name` | Nome da DNS Zone |
| `name_servers` | Name servers (Public DNS) |
| `zone_type` | Tipo da zona |
| `a_records` | Informações dos registros A |
| `cname_records` | Informações dos registros CNAME |
| `zone_summary` | Resumo das informações |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## Tipos de Registros DNS

### A Record
Mapeia nome para endereço IPv4
```hcl
a_records = [
  {
    name    = "www"
    ttl     = 3600
    records = ["192.168.1.10"]
  }
]
```

### AAAA Record
Mapeia nome para endereço IPv6
```hcl
aaaa_records = [
  {
    name    = "www"
    ttl     = 3600
    records = ["2001:0db8:85a3::8a2e:0370:7334"]
  }
]
```

### CNAME Record
Alias para outro nome
```hcl
cname_records = [
  {
    name   = "blog"
    ttl    = 3600
    record = "www.example.com"
  }
]
```

### MX Record
Mail exchange servers
```hcl
mx_records = [
  {
    name = "@"
    ttl  = 3600
    records = [
      { preference = 10, exchange = "mail1.example.com" },
      { preference = 20, exchange = "mail2.example.com" }
    ]
  }
]
```

### TXT Record
Texto arbitrário (SPF, DKIM, DMARC, verification)
```hcl
txt_records = [
  {
    name    = "@"
    ttl     = 3600
    records = ["v=spf1 include:_spf.google.com ~all"]
  }
]
```

### SRV Record
Service location
```hcl
srv_records = [
  {
    name = "_sip._tcp"
    ttl  = 3600
    records = [
      {
        priority = 10
        weight   = 60
        port     = 5060
        target   = "sip.example.com"
      }
    ]
  }
]
```

### CAA Record
Certificate Authority Authorization
```hcl
caa_records = [
  {
    name = "@"
    ttl  = 3600
    records = [
      { flags = 0, tag = "issue", value = "letsencrypt.org" }
    ]
  }
]
```

## Private DNS Zones para Azure Services

### Private Link DNS Zones
- **Storage**: `privatelink.blob.core.windows.net`
- **SQL Database**: `privatelink.database.windows.net`
- **Cosmos DB**: `privatelink.documents.azure.com`
- **Key Vault**: `privatelink.vaultcore.azure.net`
- **App Service**: `privatelink.azurewebsites.net`
- **PostgreSQL**: `privatelink.postgres.database.azure.com`
- **MySQL**: `privatelink.mysql.database.azure.com`
- **Redis**: `privatelink.redis.cache.windows.net`
- **Event Hubs**: `privatelink.servicebus.windows.net`
- **ACR**: `privatelink.azurecr.io`

## TTL (Time To Live)

### Valores Recomendados
- **A/AAAA Records**: 3600 (1 hora) - padrão
- **CNAME Records**: 3600 (1 hora)
- **MX Records**: 3600 (1 hora)
- **TXT Records**: 3600 (1 hora)
- **NS Records**: 86400 (24 horas)
- **SOA Record**: 3600 (1 hora)

### Casos Especiais
- **Traffic Manager**: 300 (5 minutos) - failover rápido
- **CDN**: 3600 (1 hora)
- **Mudança de IP**: 300 (5 minutos) - durante migração
- **Load Balancer**: 60-300 (1-5 minutos)

## Melhores Práticas

### Public DNS
1. **Use CAA records** - Previna emissão não autorizada de certificados
2. **Configure SPF, DKIM, DMARC** - Proteja seu domínio de spoofing
3. **Use TTL apropriado** - Balance entre cache e flexibilidade
4. **Implemente DNSSEC** - Autenticidade dos registros
5. **Monitore queries** - Detecte anomalias

### Private DNS
1. **Use auto-registro** - Para VMs que mudam frequentemente
2. **Link todas VNets relevantes** - Hub-spoke topology
3. **Crie zones para Private Link** - Para cada serviço Azure
4. **Use TTLs baixos** - Ambientes dinâmicos (300s)
5. **Documente zonas** - Mantenha inventário

### Segurança
1. **Restrinja acesso à zona** - RBAC apropriado
2. **Use Private DNS** - Para recursos internos
3. **Habilite query logs** - Auditoria
4. **Valide registros** - Antes de aplicar
5. **Backup configuração** - State file do Terraform

### Performance
1. **Use CNAMEs para CDN** - Facilita mudanças
2. **Minimize número de registros** - Por consulta
3. **Use A records para apex** - Não CNAME em @
4. **Configure health checks** - Para failover
5. **Use Traffic Manager** - Para distribuição global

## Troubleshooting

### Zona não resolve
- Verifique name servers no registrar
- Aguarde propagação (até 48h)
- Teste com `nslookup` ou `dig`
- Valide registros na zona

### Private DNS não resolve
- Confirme VNet link
- Verifique DNS settings na VNet
- Valide que VMs usam Azure DNS
- Teste de dentro da VNet

### Registro não atualiza
- Aguarde TTL expirar
- Force cache flush local
- Verifique propagação com múltiplos DNS
- Valide mudança foi aplicada

### Auto-registro não funciona
- Confirme registration_enabled = true
- Verifique que VMs estão na VNet correta
- Aguarde alguns minutos
- Reinicie VM se necessário

## Limitações

### Public DNS
- Máximo 10,000 record sets por zona
- Máximo 500 records por record set
- DNSSEC: apenas em zonas específicas
- Alias records: apenas para recursos Azure

### Private DNS
- Máximo 25,000 record sets por zona
- Máximo 1000 VNet links por zona
- Máximo 100 VNet links com auto-registro
- Não suporta zone transfer

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure com permissões adequadas
- Domínio registrado (para Public DNS)
- VNet (para Private DNS)