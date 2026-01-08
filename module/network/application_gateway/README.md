# Módulo Terraform - Azure Application Gateway

Este módulo Terraform cria e gerencia um Azure Application Gateway completo com suporte a balanceamento de carga Layer 7, SSL/TLS termination, Web Application Firewall (WAF), autoscaling e roteamento avançado baseado em URL.

## Recursos Criados

- **Application Gateway** - Gateway de aplicação Layer 7
- **Backend Address Pools** - Pools de servidores backend
- **Backend HTTP Settings** - Configurações HTTP para backends
- **HTTP Listeners** - Listeners para portas e protocolos
- **Routing Rules** - Regras de roteamento (básico e baseado em path)
- **Health Probes** - Verificações de saúde dos backends
- **SSL Certificates** - Certificados SSL/TLS
- **WAF Configuration** - Web Application Firewall (opcional)
- **URL Path Maps** - Roteamento baseado em URL (opcional)
- **Redirect Rules** - Redirecionamentos (opcional)
- **Rewrite Rules** - Reescrita de headers e URLs (opcional)
- **Diagnostic Settings** - Monitoramento e logs (opcional)

## Características

✅ SKUs Standard e WAF (v1 e v2)  
✅ Autoscaling (v2 SKUs)  
✅ Zone redundancy (v2 SKUs)  
✅ SSL/TLS termination  
✅ End-to-end SSL encryption  
✅ Web Application Firewall (WAF)  
✅ URL-based routing  
✅ Multi-site hosting  
✅ HTTP/2 support  
✅ Connection draining  
✅ Custom health probes  
✅ Rewrite rules (headers e URL)  
✅ Redirect configurations  
✅ Private Link support  
✅ Managed Identity  

## Uso Básico

```hcl
module "application_gateway" {
  source = "./modules/application_gateway"

  name                = "myapp-appgw"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  subnet_id            = azurerm_subnet.appgw.id
  public_ip_address_id = azurerm_public_ip.appgw.id

  backend_address_pools = [
    {
      name         = "backend-pool"
      ip_addresses = ["10.0.1.4", "10.0.1.5"]
    }
  ]

  backend_http_settings = [
    {
      name                  = "backend-http-settings"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 30
    }
  ]

  http_listeners = [
    {
      name                           = "http-listener"
      frontend_ip_configuration_name = "frontend-ip-config"
      frontend_port_name             = "http"
      protocol                       = "Http"
    }
  ]

  request_routing_rules = [
    {
      name                       = "routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "http-listener"
      backend_address_pool_name  = "backend-pool"
      backend_http_settings_name = "backend-http-settings"
      priority                   = 100
    }
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com HTTPS e SSL Certificate

```hcl
module "application_gateway_https" {
  source = "./modules/application_gateway"

  name                = "myapp-appgw-https"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  subnet_id            = azurerm_subnet.appgw.id
  public_ip_address_id = azurerm_public_ip.appgw.id
  enable_http2         = true

  # Backend pools
  backend_address_pools = [
    {
      name  = "web-backend-pool"
      fqdns = ["web1.internal.com", "web2.internal.com"]
    }
  ]

  # Backend HTTP settings
  backend_http_settings = [
    {
      name                                = "https-backend-settings"
      cookie_based_affinity               = "Disabled"
      port                                = 443
      protocol                            = "Https"
      request_timeout                     = 60
      pick_host_name_from_backend_address = true
      probe_name                          = "health-probe"
    }
  ]

  # Health probe
  probes = [
    {
      name                                      = "health-probe"
      protocol                                  = "Https"
      path                                      = "/health"
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = true
      match = {
        status_code = ["200", "201", "202"]
      }
    }
  ]

  # SSL Certificate
  ssl_certificates = [
    {
      name     = "ssl-cert"
      data     = filebase64("${path.module}/certificates/cert.pfx")
      password = var.certificate_password
    }
  ]

  # HTTPS listener
  http_listeners = [
    {
      name                           = "https-listener"
      frontend_ip_configuration_name = "frontend-ip-config"
      frontend_port_name             = "https"
      protocol                       = "Https"
      ssl_certificate_name           = "ssl-cert"
      require_sni                    = false
    }
  ]

  # Routing rule
  request_routing_rules = [
    {
      name                       = "https-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "https-listener"
      backend_address_pool_name  = "web-backend-pool"
      backend_http_settings_name = "https-backend-settings"
      priority                   = 100
    }
  ]

  tags = {
    Environment = "Production"
    SSL         = "Enabled"
  }
}
```

## Exemplo com WAF (Web Application Firewall)

```hcl
module "application_gateway_waf" {
  source = "./modules/application_gateway"

  name                = "myapp-appgw-waf"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  # Autoscaling
  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 10
  }

  zones = ["1", "2", "3"]

  subnet_id            = azurerm_subnet.appgw.id
  public_ip_address_id = azurerm_public_ip.appgw.id

  # WAF Configuration
  waf_configuration = {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
    
    # Disable specific rules if needed
    disabled_rule_group = [
      {
        rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
        rules           = [942100, 942200]
      }
    ]
    
    # WAF exclusions
    exclusion = [
      {
        match_variable          = "RequestHeaderNames"
        selector_match_operator = "Equals"
        selector                = "User-Agent"
      }
    ]
  }

  backend_address_pools = [
    {
      name  = "protected-backend"
      fqdns = ["app.internal.com"]
    }
  ]

  backend_http_settings = [
    {
      name                  = "backend-settings"
      cookie_based_affinity = "Disabled"
      port                  = 443
      protocol              = "Https"
    }
  ]

  http_listeners = [
    {
      name                           = "https-listener"
      frontend_ip_configuration_name = "frontend-ip-config"
      frontend_port_name             = "https"
      protocol                       = "Https"
      ssl_certificate_name           = "ssl-cert"
    }
  ]

  request_routing_rules = [
    {
      name                       = "waf-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "https-listener"
      backend_address_pool_name  = "protected-backend"
      backend_http_settings_name = "backend-settings"
      priority                   = 100
    }
  ]

  ssl_certificates = [
    {
      name                = "ssl-cert"
      key_vault_secret_id = azurerm_key_vault_certificate.cert.secret_id
    }
  ]

  # Managed Identity for Key Vault access
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.appgw.id]

  tags = {
    Environment = "Production"
    WAF         = "Enabled"
    Protection  = "Maximum"
  }
}
```

## Exemplo com Path-Based Routing

```hcl
module "application_gateway_path_routing" {
  source = "./modules/application_gateway"

  name                = "myapp-appgw-path"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }

  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 5
  }

  subnet_id            = azurerm_subnet.appgw.id
  public_ip_address_id = azurerm_public_ip.appgw.id

  # Multiple backend pools
  backend_address_pools = [
    {
      name  = "api-backend"
      fqdns = ["api.internal.com"]
    },
    {
      name  = "web-backend"
      fqdns = ["web.internal.com"]
    },
    {
      name  = "images-backend"
      fqdns = ["images.internal.com"]
    }
  ]

  # Backend HTTP settings for each pool
  backend_http_settings = [
    {
      name                  = "api-settings"
      cookie_based_affinity = "Disabled"
      port                  = 8080
      protocol              = "Http"
      path                  = "/api"
    },
    {
      name                  = "web-settings"
      cookie_based_affinity = "Enabled"
      affinity_cookie_name  = "ApplicationGatewayAffinity"
      port                  = 80
      protocol              = "Http"
    },
    {
      name                  = "images-settings"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
    }
  ]

  # Listener
  http_listeners = [
    {
      name                           = "http-listener"
      frontend_ip_configuration_name = "frontend-ip-config"
      frontend_port_name             = "http"
      protocol                       = "Http"
    }
  ]

  # URL Path Maps
  url_path_maps = [
    {
      name                               = "path-map"
      default_backend_address_pool_name  = "web-backend"
      default_backend_http_settings_name = "web-settings"
      
      path_rule = [
        {
          name                       = "api-rule"
          paths                      = ["/api/*"]
          backend_address_pool_name  = "api-backend"
          backend_http_settings_name = "api-settings"
        },
        {
          name                       = "images-rule"
          paths                      = ["/images/*", "/static/*"]
          backend_address_pool_name  = "images-backend"
          backend_http_settings_name = "images-settings"
        }
      ]
    }
  ]

  # Routing rule with path-based routing
  request_routing_rules = [
    {
      name               = "path-routing-rule"
      rule_type          = "PathBasedRouting"
      http_listener_name = "http-listener"
      url_path_map_name  = "path-map"
      priority           = 100
    }
  ]

  tags = {
    Environment = "Production"
    Routing     = "PathBased"
  }
}
```

## Exemplo com HTTP to HTTPS Redirect

```hcl
module "application_gateway_redirect" {
  source = "./modules/application_gateway"

  name                = "myapp-appgw-redirect"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  subnet_id            = azurerm_subnet.appgw.id
  public_ip_address_id = azurerm_public_ip.appgw.id

  backend_address_pools = [
    {
      name  = "backend-pool"
      fqdns = ["app.internal.com"]
    }
  ]

  backend_http_settings = [
    {
      name                  = "https-settings"
      cookie_based_affinity = "Disabled"
      port                  = 443
      protocol              = "Https"
    }
  ]

  # HTTP Listener
  http_listeners = [
    {
      name                           = "http-listener"
      frontend_ip_configuration_name = "frontend-ip-config"
      frontend_port_name             = "http"
      protocol                       = "Http"
    },
    {
      name                           = "https-listener"
      frontend_ip_configuration_name = "frontend-ip-config"
      frontend_port_name             = "https"
      protocol                       = "Https"
      ssl_certificate_name           = "ssl-cert"
    }
  ]

  # SSL Certificate
  ssl_certificates = [
    {
      name                = "ssl-cert"
      key_vault_secret_id = azurerm_key_vault_certificate.cert.secret_id
    }
  ]

  # Redirect Configuration
  redirect_configurations = [
    {
      name                 = "http-to-https"
      redirect_type        = "Permanent"
      target_listener_name = "https-listener"
      include_path         = true
      include_query_string = true
    }
  ]

  # Routing Rules
  request_routing_rules = [
    {
      name                        = "http-redirect-rule"
      rule_type                   = "Basic"
      http_listener_name          = "http-listener"
      redirect_configuration_name = "http-to-https"
      priority                    = 100
    },
    {
      name                       = "https-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "https-listener"
      backend_address_pool_name  = "backend-pool"
      backend_http_settings_name = "https-settings"
      priority                   = 200
    }
  ]

  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.appgw.id]

  tags = {
    Environment = "Production"
    Redirect    = "HTTPS"
  }
}
```

## Exemplo com Rewrite Rules

```hcl
module "application_gateway_rewrite" {
  source = "./modules/application_gateway"

  name                = "myapp-appgw-rewrite"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  subnet_id            = azurerm_subnet.appgw.id
  public_ip_address_id = azurerm_public_ip.appgw.id

  backend_address_pools = [
    {
      name  = "backend-pool"
      fqdns = ["app.internal.com"]
    }
  ]

  backend_http_settings = [
    {
      name                  = "backend-settings"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
    }
  ]

  http_listeners = [
    {
      name                           = "http-listener"
      frontend_ip_configuration_name = "frontend-ip-config"
      frontend_port_name             = "http"
      protocol                       = "Http"
    }
  ]

  # Rewrite Rule Sets
  rewrite_rule_sets = [
    {
      name = "security-headers"
      rewrite_rule = [
        {
          name          = "add-security-headers"
          rule_sequence = 100
          
          # Add security headers to response
          response_header_configuration = [
            {
              header_name  = "X-Content-Type-Options"
              header_value = "nosniff"
            },
            {
              header_name  = "X-Frame-Options"
              header_value = "DENY"
            },
            {
              header_name  = "Strict-Transport-Security"
              header_value = "max-age=31536000; includeSubDomains"
            }
          ]
        },
        {
          name          = "remove-server-header"
          rule_sequence = 200
          
          response_header_configuration = [
            {
              header_name  = "Server"
              header_value = ""
            }
          ]
        }
      ]
    }
  ]

  request_routing_rules = [
    {
      name                       = "routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "http-listener"
      backend_address_pool_name  = "backend-pool"
      backend_http_settings_name = "backend-settings"
      rewrite_rule_set_name      = "security-headers"
      priority                   = 100
    }
  ]

  tags = {
    Environment = "Production"
    Security    = "Enhanced"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome do Application Gateway | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `sku` | Configuração do SKU | `object` | - | Sim |
| `subnet_id` | ID da subnet | `string` | - | Sim |
| `autoscale_configuration` | Configuração de autoscaling | `object` | `null` | Não |
| `zones` | Zonas de disponibilidade | `list(string)` | `null` | Não |
| `backend_address_pools` | Backend pools | `list(object)` | - | Sim |
| `backend_http_settings` | Configurações HTTP backend | `list(object)` | - | Sim |
| `http_listeners` | HTTP listeners | `list(object)` | - | Sim |
| `request_routing_rules` | Regras de roteamento | `list(object)` | - | Sim |
| `probes` | Health probes | `list(object)` | `[]` | Não |
| `ssl_certificates` | Certificados SSL | `list(object)` | `[]` | Não |
| `waf_configuration` | Configuração WAF | `object` | `null` | Não |
| `url_path_maps` | URL path maps | `list(object)` | `[]` | Não |
| `redirect_configurations` | Redirecionamentos | `list(object)` | `[]` | Não |
| `rewrite_rule_sets` | Rewrite rules | `list(object)` | `[]` | Não |
| `enable_http2` | Habilitar HTTP/2 | `bool` | `false` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID do Application Gateway |
| `name` | Nome do Application Gateway |
| `frontend_ip_configuration` | Configuração de IP frontend |
| `backend_address_pool_ids` | IDs dos backend pools |
| `http_listener_ids` | IDs dos listeners |
| `gateway_summary` | Resumo das informações |
| `waf_enabled` | Status do WAF |
| `identity` | Identidade gerenciada |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## SKUs Disponíveis

### Standard Tier (v1 - Legacy)
- **Standard_Small**: 2 vCPUs
- **Standard_Medium**: 4 vCPUs
- **Standard_Large**: 8 vCPUs

### Standard_v2 Tier
- Autoscaling
- Zone redundancy
- Static VIP
- Performance melhorada
- Custo baseado em uso

### WAF Tier (v1 - Legacy)
- **WAF_Medium**: Standard_Medium + WAF
- **WAF_Large**: Standard_Large + WAF

### WAF_v2 Tier
- Todos os recursos do Standard_v2
- Web Application Firewall
- OWASP Core Rule Set
- Custom rules support
- Bot protection

## Capacidade e Autoscaling

### Manual Scaling (v1 e v2)
```hcl
sku = {
  name     = "Standard_v2"
  tier     = "Standard_v2"
  capacity = 2  # 1-125 instances
}
```

### Autoscaling (v2 only)
```hcl
autoscale_configuration = {
  min_capacity = 2   # 0-125
  max_capacity = 10  # 0-125
}
```

## SSL/TLS Configuration

### SSL Certificates

#### From File
```hcl
ssl_certificates = [
  {
    name     = "ssl-cert"
    data     = filebase64("cert.pfx")
    password = "certificate_password"
  }
]
```

#### From Key Vault
```hcl
ssl_certificates = [
  {
    name                = "ssl-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.cert.secret_id
  }
]
```

### SSL Policy

#### Predefined Policy
```hcl
ssl_policy = {
  policy_type = "Predefined"
  policy_name = "AppGwSslPolicy20170401S"
}
```

#### Custom Policy
```hcl
ssl_policy = {
  policy_type          = "Custom"
  min_protocol_version = "TLSv1_2"
  cipher_suites = [
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
  ]
}
```

## Health Probes

### HTTP Probe
```hcl
probes = [
  {
    name                = "health-probe"
    protocol            = "Http"
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "example.com"
    match = {
      status_code = ["200", "201"]
    }
  }
]
```

### HTTPS Probe with Custom Host
```hcl
probes = [
  {
    name                                      = "https-probe"
    protocol                                  = "Https"
    path                                      = "/api/health"
    pick_host_name_from_backend_http_settings = false
    host                                      = "api.example.com"
    port                                      = 443
    match = {
      status_code = ["200-399"]
      body        = "healthy"
    }
  }
]
```

## WAF Rule Sets

- **OWASP 3.2** (Latest)
- **OWASP 3.1**
- **OWASP 3.0**
- **OWASP 2.2.9**

### WAF Modes
- **Detection**: Logs threats but doesn't block
- **Prevention**: Blocks malicious requests

## Melhores Práticas

### Segurança
1. **Use WAF em produção** - Proteção contra OWASP Top 10
2. **Habilite HTTPS** - Use SSL/TLS termination
3. **Implemente redirects HTTP→HTTPS** - Force conexões seguras
4. **Use Key Vault para certificados** - Managed Identity
5. **Configure health probes** - Detecte backends não saudáveis
6. **Adicione security headers** - Use rewrite rules
7. **Use SSL policy moderno** - TLS 1.2+

### Performance
1. **Use v2 SKUs** - Melhor performance e features
2. **Habilite autoscaling** - Para cargas variáveis
3. **Use HTTP/2** - Melhor performance
4. **Configure connection draining** - Evite perda de requisições
5. **Use zone redundancy** - Alta disponibilidade
6. **Otimize health probes** - Balance frequência vs overhead

### Custo
1. **Use autoscaling** - Pague apenas pelo que usar
2. **Monitore capacity units** - Otimize custos
3. **Revise configuração** - Remove recursos não usados
4. **Use Reserved Capacity** - Para workloads previsíveis

### Operacional
1. **Habilite diagnostic logs** - Para troubleshooting
2. **Configure alertas** - Para problemas de saúde
3. **Use Managed Identity** - Para Key Vault access
4. **Documente routing rules** - Para manutenção
5. **Teste failover** - Valide HA configuration

## Troubleshooting

### Backend Health Issues
- Verifique NSG rules na subnet do backend
- Confirme que health probe path está acessível
- Valide configuração de certificados (para HTTPS)
- Revise timeout settings

### 502 Bad Gateway
- Backend está down ou inacessível
- Health probe failing
- Timeout muito curto
- SSL/TLS mismatch

### 504 Gateway Timeout
- Backend muito lento
- Request timeout muito curto
- Problemas de rede/latência

### WAF Blocking Legitimate Traffic
- Revise WAF logs
- Adicione exclusions para false positives
- Ajuste regras customizadas
- Use Detection mode primeiro

## Limitações

- Máximo 125 instances (autoscaling)
- Máximo 100 sites por Application Gateway
- Máximo 100 URL path maps
- Máximo 20 listeners
- SSL certificate: máximo 10 MB
- Request timeout: 1-86400 segundos

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subnet dedicada (mínimo /24)
- Public IP (Standard SKU para v2)