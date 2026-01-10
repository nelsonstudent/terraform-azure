# Módulo Terraform - Azure Load Balancer

Este módulo Terraform cria e gerencia um Azure Load Balancer completo com suporte a balanceamento de carga Layer 4, health probes, NAT rules, outbound rules, HA ports e zone redundancy.

## Recursos Criados

- **Load Balancer** - Balanceador de carga Layer 4
- **Frontend IP Configurations** - Configurações de IP público ou privado
- **Backend Address Pools** - Pools de servidores backend
- **Health Probes** - Verificações de saúde dos backends
- **Load Balancing Rules** - Regras de distribuição de tráfego
- **NAT Rules** - Regras de NAT inbound
- **Outbound Rules** - Regras para tráfego de saída (Standard SKU)
- **HA Ports Rules** - Regras de alta disponibilidade (Standard Internal)
- **Diagnostic Settings** - Monitoramento e logs (opcional)

## Características

✅ SKUs Basic, Standard e Gateway  
✅ Load Balancer Público e Interno  
✅ Zone redundancy (Standard SKU)  
✅ Global Load Balancer (cross-region)  
✅ Health probes (TCP, HTTP, HTTPS)  
✅ Session persistence (affinity)  
✅ Floating IP support  
✅ TCP reset  
✅ Outbound rules (SNAT)  
✅ HA Ports (Standard Internal)  
✅ NAT rules e NAT pools  
✅ Multiple frontend IPs  
✅ Managed Identity  
✅ Diagnostic settings  

## Uso Básico - Public Load Balancer

```hcl
module "load_balancer" {
  source = "./modules/load_balancer"

  name                = "myapp-lb"
  resource_group_name = "my-resource-group"
  location            = "eastus"
  sku                 = "Standard"

  frontend_ip_configurations = [
    {
      name                 = "frontend-ip"
      public_ip_address_id = azurerm_public_ip.lb.id
    }
  ]

  backend_address_pools = [
    {
      name = "backend-pool"
    }
  ]

  probes = [
    {
      name     = "http-probe"
      protocol = "Http"
      port     = 80
      request_path = "/health"
    }
  ]

  lb_rules = [
    {
      name                           = "http-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "frontend-ip"
      backend_address_pool_names     = ["backend-pool"]
      probe_name                     = "http-probe"
    }
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo Internal Load Balancer

```hcl
module "internal_load_balancer" {
  source = "./modules/load_balancer"

  name                = "myapp-internal-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  frontend_ip_configurations = [
    {
      name                          = "internal-frontend"
      subnet_id                     = azurerm_subnet.backend.id
      private_ip_address            = "10.0.1.10"
      private_ip_address_allocation = "Static"
    }
  ]

  backend_address_pools = [
    {
      name = "web-backend-pool"
    }
  ]

  probes = [
    {
      name                = "https-probe"
      protocol            = "Https"
      port                = 443
      request_path        = "/api/health"
      interval_in_seconds = 15
      number_of_probes    = 2
    }
  ]

  lb_rules = [
    {
      name                           = "https-rule"
      protocol                       = "Tcp"
      frontend_port                  = 443
      backend_port                   = 443
      frontend_ip_configuration_name = "internal-frontend"
      backend_address_pool_names     = ["web-backend-pool"]
      probe_name                     = "https-probe"
      load_distribution              = "SourceIP"
    }
  ]

  tags = {
    Environment = "Production"
    Type        = "Internal"
  }
}
```

## Exemplo com Zone Redundancy

```hcl
module "zone_redundant_lb" {
  source = "./modules/load_balancer"

  name                = "myapp-zr-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  sku_tier            = "Regional"

  # Frontend com Zone Redundancy
  frontend_ip_configurations = [
    {
      name                 = "zone-redundant-frontend"
      public_ip_address_id = azurerm_public_ip.lb_zr.id
      zones                = ["1", "2", "3"]
    }
  ]

  backend_address_pools = [
    {
      name = "zr-backend-pool"
    }
  ]

  probes = [
    {
      name     = "tcp-probe"
      protocol = "Tcp"
      port     = 80
    }
  ]

  lb_rules = [
    {
      name                           = "web-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "zone-redundant-frontend"
      backend_address_pool_names     = ["zr-backend-pool"]
      probe_name                     = "tcp-probe"
      enable_tcp_reset               = true
    }
  ]

  tags = {
    Environment    = "Production"
    Availability   = "ZoneRedundant"
  }
}

# Public IP Zone Redundant
resource "azurerm_public_ip" "lb_zr" {
  name                = "myapp-lb-pip-zr"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}
```

## Exemplo com Multiple Frontend IPs

```hcl
module "multi_frontend_lb" {
  source = "./modules/load_balancer"

  name                = "myapp-multi-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  # Múltiplos Frontend IPs
  frontend_ip_configurations = [
    {
      name                 = "web-frontend"
      public_ip_address_id = azurerm_public_ip.web.id
    },
    {
      name                 = "api-frontend"
      public_ip_address_id = azurerm_public_ip.api.id
    }
  ]

  backend_address_pools = [
    {
      name = "web-pool"
    },
    {
      name = "api-pool"
    }
  ]

  probes = [
    {
      name         = "web-probe"
      protocol     = "Http"
      port         = 80
      request_path = "/"
    },
    {
      name         = "api-probe"
      protocol     = "Http"
      port         = 8080
      request_path = "/api/health"
    }
  ]

  lb_rules = [
    {
      name                           = "web-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "web-frontend"
      backend_address_pool_names     = ["web-pool"]
      probe_name                     = "web-probe"
    },
    {
      name                           = "api-rule"
      protocol                       = "Tcp"
      frontend_port                  = 8080
      backend_port                   = 8080
      frontend_ip_configuration_name = "api-frontend"
      backend_address_pool_names     = ["api-pool"]
      probe_name                     = "api-probe"
    }
  ]

  tags = {
    Environment = "Production"
    Services    = "Multiple"
  }
}
```

## Exemplo com NAT Rules

```hcl
module "lb_with_nat" {
  source = "./modules/load_balancer"

  name                = "myapp-lb-nat"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  frontend_ip_configurations = [
    {
      name                 = "frontend-ip"
      public_ip_address_id = azurerm_public_ip.lb.id
    }
  ]

  backend_address_pools = [
    {
      name = "vm-pool"
    }
  ]

  probes = [
    {
      name     = "ssh-probe"
      protocol = "Tcp"
      port     = 22
    }
  ]

  lb_rules = [
    {
      name                           = "web-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "frontend-ip"
      backend_address_pool_names     = ["vm-pool"]
    }
  ]

  # NAT Rules para acesso SSH individual
  nat_rules = [
    {
      name                           = "ssh-vm1"
      protocol                       = "Tcp"
      frontend_port                  = 50001
      backend_port                   = 22
      frontend_ip_configuration_name = "frontend-ip"
    },
    {
      name                           = "ssh-vm2"
      protocol                       = "Tcp"
      frontend_port                  = 50002
      backend_port                   = 22
      frontend_ip_configuration_name = "frontend-ip"
    },
    {
      name                           = "rdp-vm1"
      protocol                       = "Tcp"
      frontend_port                  = 50003
      backend_port                   = 3389
      frontend_ip_configuration_name = "frontend-ip"
    }
  ]

  tags = {
    Environment = "Production"
    NAT         = "Enabled"
  }
}
```

## Exemplo com Outbound Rules (SNAT)

```hcl
module "lb_with_outbound" {
  source = "./modules/load_balancer"

  name                = "myapp-lb-outbound"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  frontend_ip_configurations = [
    {
      name                 = "inbound-frontend"
      public_ip_address_id = azurerm_public_ip.inbound.id
    },
    {
      name                 = "outbound-frontend"
      public_ip_address_id = azurerm_public_ip.outbound.id
    }
  ]

  backend_address_pools = [
    {
      name = "backend-pool"
    }
  ]

  probes = [
    {
      name     = "http-probe"
      protocol = "Http"
      port     = 80
      request_path = "/health"
    }
  ]

  lb_rules = [
    {
      name                           = "http-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "inbound-frontend"
      backend_address_pool_names     = ["backend-pool"]
      probe_name                     = "http-probe"
      disable_outbound_snat          = true  # Usar outbound rule
    }
  ]

  # Outbound Rule para SNAT
  outbound_rules = [
    {
      name                            = "outbound-rule"
      protocol                        = "All"
      backend_address_pool_name       = "backend-pool"
      frontend_ip_configuration_names = ["outbound-frontend"]
      allocated_outbound_ports        = 10000
      idle_timeout_in_minutes         = 4
      enable_tcp_reset                = true
    }
  ]

  tags = {
    Environment = "Production"
    Outbound    = "Configured"
  }
}
```

## Exemplo com HA Ports (Internal Load Balancer)

```hcl
module "ha_ports_lb" {
  source = "./modules/load_balancer"

  name                = "myapp-ha-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  # Internal Load Balancer
  frontend_ip_configurations = [
    {
      name                          = "internal-frontend"
      subnet_id                     = azurerm_subnet.nva.id
      private_ip_address            = "10.0.1.100"
      private_ip_address_allocation = "Static"
    }
  ]

  backend_address_pools = [
    {
      name = "nva-pool"
    }
  ]

  probes = [
    {
      name     = "nva-probe"
      protocol = "Tcp"
      port     = 80
    }
  ]

  # HA Ports Rule (todo o tráfego)
  ha_ports_rules = [
    {
      name                           = "ha-ports-rule"
      protocol                       = "All"
      frontend_ip_configuration_name = "internal-frontend"
      backend_address_pool_names     = ["nva-pool"]
      probe_name                     = "nva-probe"
      enable_floating_ip             = true
    }
  ]

  tags = {
    Environment = "Production"
    Type        = "HAports"
  }
}
```

## Exemplo com Backend Addresses

```hcl
module "lb_with_backend_addresses" {
  source = "./modules/load_balancer"

  name                = "myapp-lb-addresses"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  frontend_ip_configurations = [
    {
      name                          = "internal-frontend"
      subnet_id                     = azurerm_subnet.lb.id
      private_ip_address_allocation = "Dynamic"
    }
  ]

  backend_address_pools = [
    {
      name = "app-pool"
    }
  ]

  # Backend addresses (IPs na VNet)
  backend_addresses = [
    {
      name                      = "app-vm1"
      backend_address_pool_name = "app-pool"
      virtual_network_id        = azurerm_virtual_network.main.id
      ip_address                = "10.0.2.10"
    },
    {
      name                      = "app-vm2"
      backend_address_pool_name = "app-pool"
      virtual_network_id        = azurerm_virtual_network.main.id
      ip_address                = "10.0.2.11"
    }
  ]

  probes = [
    {
      name     = "app-probe"
      protocol = "Tcp"
      port     = 8080
    }
  ]

  lb_rules = [
    {
      name                           = "app-rule"
      protocol                       = "Tcp"
      frontend_port                  = 8080
      backend_port                   = 8080
      frontend_ip_configuration_name = "internal-frontend"
      backend_address_pool_names     = ["app-pool"]
      probe_name                     = "app-probe"
    }
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Session Persistence (Source IP Affinity)

```hcl
module "lb_session_affinity" {
  source = "./modules/load_balancer"

  name                = "myapp-lb-affinity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  frontend_ip_configurations = [
    {
      name                 = "frontend-ip"
      public_ip_address_id = azurerm_public_ip.lb.id
    }
  ]

  backend_address_pools = [
    {
      name = "stateful-app-pool"
    }
  ]

  probes = [
    {
      name         = "app-probe"
      protocol     = "Http"
      port         = 80
      request_path = "/health"
    }
  ]

  lb_rules = [
    {
      name                           = "app-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "frontend-ip"
      backend_address_pool_names     = ["stateful-app-pool"]
      probe_name                     = "app-probe"
      load_distribution              = "SourceIP"  # Session affinity
      idle_timeout_in_minutes        = 15
    }
  ]

  tags = {
    Environment = "Production"
    Affinity    = "SourceIP"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome do Load Balancer | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `sku` | SKU (Basic, Standard, Gateway) | `string` | `"Standard"` | Não |
| `sku_tier` | SKU Tier (Regional, Global) | `string` | `"Regional"` | Não |
| `frontend_ip_configurations` | Configurações de IP frontend | `list(object)` | - | Sim |
| `backend_address_pools` | Backend pools | `list(object)` | - | Sim |
| `probes` | Health probes | `list(object)` | `[]` | Não |
| `lb_rules` | Regras de balanceamento | `list(object)` | `[]` | Não |
| `nat_rules` | Regras NAT | `list(object)` | `[]` | Não |
| `outbound_rules` | Regras outbound | `list(object)` | `[]` | Não |
| `ha_ports_rules` | Regras HA Ports | `list(object)` | `[]` | Não |
| `zones` | Zonas de disponibilidade | `list(string)` | `null` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID do Load Balancer |
| `name` | Nome do Load Balancer |
| `frontend_ip_configuration_ids` | IDs das configurações frontend |
| `backend_address_pool_ids` | IDs dos backend pools |
| `probe_ids` | IDs dos health probes |
| `private_ip_address` | IP privado (se internal) |
| `is_public` | Indica se é público |
| `is_internal` | Indica se é interno |
| `lb_summary` | Resumo das informações |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## SKUs

### Basic
- ✅ Até 300 instances no backend
- ✅ Health probes (HTTP, HTTPS, TCP)
- ✅ Port forwarding
- ❌ Não tem SLA
- ❌ Não suporta zones
- ❌ Não suporta outbound rules
- ❌ Não suporta HA ports

### Standard
- ✅ Até 1000 instances no backend
- ✅ SLA 99.99%
- ✅ Zone redundancy
- ✅ Outbound rules (SNAT)
- ✅ HA Ports (internal)
- ✅ TCP reset
- ✅ Multiple frontend IPs
- ✅ Diagnostic logs

### Gateway (Preview)
- Para encadeamento de Network Virtual Appliances (NVAs)

## Diferenças: Public vs Internal

### Public Load Balancer
- Frontend com Public IP
- Distribui tráfego da internet
- SNAT automático para outbound traffic
- Use para aplicações web expostas

### Internal Load Balancer
- Frontend com Private IP
- Distribui tráfego interno na VNet
- Suporta HA Ports (Standard)
- Use para bancos de dados, app tiers internos

## Load Distribution (Session Persistence)

### Default (5-tuple hash)
- Source IP
- Source port
- Destination IP
- Destination port
- Protocol type

### SourceIP (2-tuple hash)
- Source IP
- Destination IP
- Session affinity

### SourceIPProtocol (3-tuple hash)
- Source IP
- Destination IP
- Protocol type

## Health Probes

### TCP Probe
```hcl
probes = [
  {
    name     = "tcp-probe"
    protocol = "Tcp"
    port     = 80
  }
]
```

### HTTP Probe
```hcl
probes = [
  {
    name         = "http-probe"
    protocol     = "Http"
    port         = 80
    request_path = "/health"
  }
]
```

### HTTPS Probe
```hcl
probes = [
  {
    name         = "https-probe"
    protocol     = "Https"
    port         = 443
    request_path = "/api/health"
  }
]
```

## Floating IP

Use Floating IP quando:
- SQL Server Always On
- Network Virtual Appliances (NVAs)
- Múltiplos serviços na mesma porta
- HA Ports scenarios

## Melhores Práticas

### Alta Disponibilidade
1. **Use Standard SKU** - SLA 99.99%
2. **Implemente zone redundancy** - Multiple zones
3. **Configure health probes** - Detecte backends não saudáveis
4. **Use múltiplos backends** - Redundância
5. **Implemente circuit breaker** - Na aplicação

### Performance
1. **Otimize health probes** - Balance frequência vs overhead
2. **Use connection pooling** - Reutilize conexões
3. **Configure timeouts apropriados** - Evite conexões pendentes
4. **Use SourceIP distribution** - Para aplicações stateful
5. **Implemente connection draining** - Para VMs sendo removidas

### Segurança
1. **Use NSGs nos backends** - Restrinja tráfego
2. **Configure outbound rules** - Controle SNAT
3. **Use Internal LB para tiers internos** - Não exponha
4. **Monitore métricas** - Detecte anomalias
5. **Habilite diagnostic logs** - Auditoria

### Custo
1. **Use Standard SKU** - Melhor custo-benefício
2. **Otimize outbound rules** - Minimize custos SNAT
3. **Revise frontend IPs** - Remova não utilizados
4. **Monitore data transfer** - Entre zonas/regiões

## Troubleshooting

### Backend Health Down
- Verifique NSG rules
- Confirme que aplicação está respondendo
- Valide health probe path
- Revise firewall no backend

### Conexões Intermitentes
- Verifique load distribution setting
- Revise health probe configuration
- Confirme que backends são homogêneos
- Valide idle timeout

### SNAT Port Exhaustion
- Configure outbound rules
- Aumente allocated_outbound_ports
- Implemente connection pooling
- Use múltiplos frontend IPs

### HA Ports Não Funciona
- Confirme que é Internal LB
- Valide que SKU é Standard
- Verifique Floating IP está habilitado
- Revise NSG rules

## Limitações

### Basic SKU
- Máximo 300 instances
- Máximo 250 flows por instância
- Sem SLA
- Sem zones

### Standard SKU
- Máximo 1000 instances
- Sem limite de flows
- Máximo 600 rules
- Outbound: máximo 64k ports por frontend IP

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure com permissões adequadas
- Public IP (Standard SKU para Standard LB)
- Subnet (para Internal LB)