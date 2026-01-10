# Módulo Terraform - Azure ExpressRoute

Este módulo Terraform cria e gerencia um Azure ExpressRoute Circuit completo com suporte a Azure Private Peering, Microsoft Peering, Global Reach, Route Filters e conexão com Virtual Network Gateways.

## Recursos Criados

- **ExpressRoute Circuit** - Circuito ExpressRoute principal
- **Azure Private Peering** - Peering privado para acesso a VNets (opcional)
- **Microsoft Peering** - Peering para serviços Microsoft 365 e Azure Public (opcional)
- **Route Filter** - Filtro de rotas para Microsoft Peering (opcional)
- **Circuit Authorizations** - Autorizações para outras subscriptions (opcional)
- **Gateway Connection** - Conexão com VNet Gateway (opcional)
- **Global Reach Connections** - Conexões entre circuits ExpressRoute (opcional)
- **Diagnostic Settings** - Monitoramento e logs (opcional)

## Características

✅ Standard, Premium e Local SKUs  
✅ Metered e Unlimited Data plans  
✅ Azure Private Peering (acesso VNets)  
✅ Microsoft Peering (Microsoft 365, Azure Public)  
✅ IPv4 e IPv6 support  
✅ ExpressRoute Global Reach  
✅ ExpressRoute FastPath  
✅ Route Filters para Microsoft Peering  
✅ Circuit Authorizations  
✅ BGP communities  
✅ Diagnostic settings  
✅ Multiple bandwidth options  

## Uso Básico

```hcl
module "expressroute" {
  source = "./modules/expressroute"

  name                  = "mycompany-er-circuit"
  resource_group_name   = "my-resource-group"
  location              = "East US"
  service_provider_name = "Equinix"
  peering_location      = "Washington DC"
  bandwidth_in_mbps     = 1000

  sku = {
    tier   = "Standard"
    family = "MeteredData"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Azure Private Peering

```hcl
module "expressroute_private" {
  source = "./modules/expressroute"

  name                  = "mycompany-er-circuit"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  service_provider_name = "Equinix"
  peering_location      = "Silicon Valley"
  bandwidth_in_mbps     = 1000

  sku = {
    tier   = "Premium"
    family = "UnlimitedData"
  }

  # Azure Private Peering
  enable_azure_private_peering = true
  azure_private_peering = {
    peer_asn                      = 65001
    primary_peer_address_prefix   = "192.168.10.0/30"
    secondary_peer_address_prefix = "192.168.10.4/30"
    vlan_id                       = 100
    shared_key                    = var.bgp_shared_key
  }

  tags = {
    Environment = "Production"
    Connectivity = "Hybrid"
  }
}
```

## Exemplo com Microsoft Peering

```hcl
module "expressroute_microsoft" {
  source = "./modules/expressroute"

  name                  = "mycompany-er-circuit"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  service_provider_name = "AT&T"
  peering_location      = "Washington DC"
  bandwidth_in_mbps     = 500

  sku = {
    tier   = "Standard"
    family = "MeteredData"
  }

  # Microsoft Peering
  enable_microsoft_peering = true
  microsoft_peering = {
    peer_asn                      = 65002
    primary_peer_address_prefix   = "203.0.113.0/30"
    secondary_peer_address_prefix = "203.0.113.4/30"
    vlan_id                       = 200
    advertised_public_prefixes    = ["203.0.113.0/24"]
    routing_registry_name         = "ARIN"
  }

  # Route Filter para Microsoft Peering
  create_route_filter = true
  route_filter_name   = "mycompany-route-filter"
  
  route_filter_rules = [
    {
      name        = "allow-office365"
      access      = "Allow"
      rule_type   = "Community"
      communities = ["12076:5030"]  # Office 365
    },
    {
      name        = "allow-azure-public"
      access      = "Allow"
      rule_type   = "Community"
      communities = ["12076:5040"]  # Azure Public Services
    }
  ]

  tags = {
    Environment = "Production"
    Service     = "Microsoft365"
  }
}
```

## Exemplo Completo com Gateway Connection

```hcl
# ExpressRoute Circuit
module "expressroute_complete" {
  source = "./modules/expressroute"

  name                  = "mycompany-er-circuit"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  service_provider_name = "Verizon"
  peering_location      = "Silicon Valley"
  bandwidth_in_mbps     = 2000

  sku = {
    tier   = "Premium"
    family = "UnlimitedData"
  }

  # Azure Private Peering
  enable_azure_private_peering = true
  azure_private_peering = {
    peer_asn                      = 65001
    primary_peer_address_prefix   = "10.100.0.0/30"
    secondary_peer_address_prefix = "10.100.0.4/30"
    vlan_id                       = 100
    shared_key                    = var.bgp_shared_key
  }

  # Gateway Connection
  create_gateway_connection    = true
  virtual_network_gateway_id   = azurerm_virtual_network_gateway.er_gateway.id
  connection_name              = "hub-to-onprem"
  routing_weight               = 0
  enable_fastpath              = true

  # Circuit Authorizations (para outras subscriptions)
  create_circuit_authorizations = true
  circuit_authorizations = [
    {
      name = "spoke1-subscription"
    },
    {
      name = "spoke2-subscription"
    }
  ]

  # Monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "Production"
    Tier        = "Premium"
  }
}

# ExpressRoute Gateway
resource "azurerm_virtual_network_gateway" "er_gateway" {
  name                = "er-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "ExpressRoute"
  sku      = "ErGw3AZ"  # For FastPath support

  ip_configuration {
    name                          = "gateway-config"
    public_ip_address_id          = azurerm_public_ip.er_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}
```

## Exemplo com Global Reach

```hcl
# Primary ExpressRoute Circuit
module "expressroute_primary" {
  source = "./modules/expressroute"

  name                  = "er-useast-circuit"
  resource_group_name   = azurerm_resource_group.main.name
  location              = "East US"
  service_provider_name = "Equinix"
  peering_location      = "Washington DC"
  bandwidth_in_mbps     = 1000

  sku = {
    tier   = "Premium"
    family = "UnlimitedData"
  }

  enable_azure_private_peering = true
  azure_private_peering = {
    peer_asn                      = 65001
    primary_peer_address_prefix   = "10.100.0.0/30"
    secondary_peer_address_prefix = "10.100.0.4/30"
    vlan_id                       = 100
  }

  tags = {
    Environment = "Production"
    Region      = "EastUS"
  }
}

# Secondary ExpressRoute Circuit
module "expressroute_secondary" {
  source = "./modules/expressroute"

  name                  = "er-europe-circuit"
  resource_group_name   = azurerm_resource_group.main.name
  location              = "West Europe"
  service_provider_name = "Equinix"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 1000

  sku = {
    tier   = "Premium"
    family = "UnlimitedData"
  }

  enable_azure_private_peering = true
  azure_private_peering = {
    peer_asn                      = 65002
    primary_peer_address_prefix   = "10.101.0.0/30"
    secondary_peer_address_prefix = "10.101.0.4/30"
    vlan_id                       = 101
  }

  # Global Reach - conecta os dois circuits
  enable_global_reach = true
  global_reach_connections = [
    {
      name                          = "useast-to-europe"
      peer_express_route_circuit_id = module.expressroute_primary.id
    }
  ]

  tags = {
    Environment = "Production"
    Region      = "WestEurope"
  }
}
```

## Exemplo com IPv6

```hcl
module "expressroute_ipv6" {
  source = "./modules/expressroute"

  name                  = "mycompany-er-ipv6"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  service_provider_name = "Equinix"
  peering_location      = "Silicon Valley"
  bandwidth_in_mbps     = 1000

  sku = {
    tier   = "Premium"
    family = "UnlimitedData"
  }

  # Azure Private Peering com IPv6
  enable_azure_private_peering = true
  azure_private_peering = {
    peer_asn                      = 65001
    primary_peer_address_prefix   = "10.100.0.0/30"
    secondary_peer_address_prefix = "10.100.0.4/30"
    vlan_id                       = 100
    
    # IPv6 configuration
    ipv6 = {
      primary_peer_address_prefix   = "2001:db8:100::/126"
      secondary_peer_address_prefix = "2001:db8:100:4::/126"
      enabled                       = true
    }
  }

  tags = {
    Environment = "Production"
    IPv6        = "Enabled"
  }
}
```

## Exemplo Multi-Region com Redundância

```hcl
# Primary Circuit - East US
module "expressroute_primary" {
  source = "./modules/expressroute"

  name                  = "er-primary-useast"
  resource_group_name   = azurerm_resource_group.main.name
  location              = "East US"
  service_provider_name = "Equinix"
  peering_location      = "Washington DC"
  bandwidth_in_mbps     = 10000

  sku = {
    tier   = "Premium"
    family = "UnlimitedData"
  }

  enable_azure_private_peering = true
  azure_private_peering = {
    peer_asn                      = 65001
    primary_peer_address_prefix   = "10.100.0.0/30"
    secondary_peer_address_prefix = "10.100.0.4/30"
    vlan_id                       = 100
  }

  create_gateway_connection  = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.primary.id
  connection_name            = "primary-connection"
  routing_weight             = 100  # Higher weight for primary

  tags = {
    Environment = "Production"
    Role        = "Primary"
  }
}

# Secondary Circuit - West US (Redundancy)
module "expressroute_secondary" {
  source = "./modules/expressroute"

  name                  = "er-secondary-uswest"
  resource_group_name   = azurerm_resource_group.main.name
  location              = "West US"
  service_provider_name = "Equinix"
  peering_location      = "Silicon Valley"
  bandwidth_in_mbps     = 10000

  sku = {
    tier   = "Premium"
    family = "UnlimitedData"
  }

  enable_azure_private_peering = true
  azure_private_peering = {
    peer_asn                      = 65001
    primary_peer_address_prefix   = "10.101.0.0/30"
    secondary_peer_address_prefix = "10.101.0.4/30"
    vlan_id                       = 101
  }

  create_gateway_connection  = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.primary.id
  connection_name            = "secondary-connection"
  routing_weight             = 50  # Lower weight for secondary

  tags = {
    Environment = "Production"
    Role        = "Secondary"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome do ExpressRoute Circuit | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `service_provider_name` | Nome do service provider | `string` | - | Sim |
| `peering_location` | Localização do peering | `string` | - | Sim |
| `bandwidth_in_mbps` | Largura de banda em Mbps | `number` | - | Sim |
| `sku` | Configuração do SKU | `object` | - | Sim |
| `enable_azure_private_peering` | Habilitar Private Peering | `bool` | `false` | Não |
| `enable_microsoft_peering` | Habilitar Microsoft Peering | `bool` | `false` | Não |
| `create_gateway_connection` | Criar conexão com gateway | `bool` | `false` | Não |
| `enable_global_reach` | Habilitar Global Reach | `bool` | `false` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID do ExpressRoute Circuit |
| `name` | Nome do circuit |
| `service_key` | Service key (sensível) |
| `service_provider_provisioning_state` | Estado de provisionamento |
| `azure_private_peering_id` | ID do Private Peering |
| `microsoft_peering_id` | ID do Microsoft Peering |
| `circuit_summary` | Resumo das informações |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## SKUs

### Standard
- Conectividade dentro da mesma região geopolítica
- Azure Private Peering
- Microsoft Peering
- Metered ou Unlimited Data

### Premium
- Conectividade global (todas as regiões)
- Azure Private Peering
- Microsoft Peering
- Global Reach
- Até 10,000 rotas
- Metered ou Unlimited Data

### Local
- Acesso local a região Azure específica
- Menor custo
- Azure Private Peering apenas
- Metered Data apenas

## Bandwidth Options

- **50 Mbps**
- **100 Mbps**
- **200 Mbps**
- **500 Mbps**
- **1 Gbps** (1000 Mbps)
- **2 Gbps** (2000 Mbps)
- **5 Gbps** (5000 Mbps)
- **10 Gbps** (10000 Mbps)

## Peering Types

### Azure Private Peering
- Acesso privado a VNets
- Comunicação com VMs, PaaS services
- Usa BGP
- /30 subnet para cada link (primary e secondary)
- Redundância automática

### Microsoft Peering
- Acesso a serviços Microsoft 365
- Acesso a Azure Public Services (PaaS)
- Requer IPs públicos
- Route filters para controlar tráfego
- BGP communities

## Service Providers

### Principais Providers
- **Equinix**
- **AT&T**
- **Verizon**
- **Level 3 (CenturyLink)**
- **British Telecom**
- **Orange**
- **Telia Carrier**
- **Megaport**
- **PCCW Global**
- **Colt**

### Peering Locations
Varia por provider. Exemplos:
- Silicon Valley
- Washington DC
- New York
- London
- Amsterdam
- Hong Kong
- Singapore
- Sydney
- Tokyo

## BGP Communities

### Microsoft Peering
- **12076:5030** - Office 365
- **12076:5040** - Azure Public Services (East US)
- **12076:5050** - Azure Public Services (West US)
- **12076:5060** - Azure Public Services (Europe)
- **12076:5070** - Azure Public Services (Asia)

## ExpressRoute Global Reach

Permite conectar dois circuits ExpressRoute para criar conectividade privada entre redes on-premises através da rede Microsoft.

### Requisitos
- Premium SKU
- Circuits na mesma região geopolítica ou cross-region
- /29 subnet para conexão

### Casos de Uso
- Conectar datacenters em diferentes regiões
- Multi-cloud connectivity
- Disaster recovery entre sites

## FastPath

Melhora a performance de data path enviando tráfego diretamente para VMs, bypass do gateway.

### Requisitos
- UltraPerformance ou ErGw3AZ gateway
- Standard ou Premium SKU circuit
- Azure Private Peering

### Benefícios
- Menor latência
- Maior throughput
- Melhor performance para workloads intensivos

## Melhores Práticas

### Design
1. **Use Premium SKU para global** - Se precisa acesso global
2. **Implemente redundância** - Múltiplos circuits
3. **Use Global Reach** - Para conectar sites on-premises
4. **Configure route filters** - Para Microsoft Peering
5. **Implemente FastPath** - Para performance

### Segurança
1. **Use shared keys BGP** - Autenticação BGP
2. **Implemente Route Filters** - Controle de tráfego
3. **Use Private Peering** - Para tráfego interno
4. **Configure NSGs** - Nas VNets
5. **Monitore peering state** - Detecte problemas

### Performance
1. **Escolha bandwidth adequado** - Baseado em necessidade
2. **Use FastPath** - Quando possível
3. **Otimize roteamento** - BGP weights
4. **Monitore utilização** - Bandwidth e latência
5. **Considere ExpressRoute Direct** - Para >10Gbps

### Custo
1. **Use Local SKU** - Quando possível
2. **Unlimited vs Metered** - Calcule baseado em uso
3. **Monitore bandwidth** - Evite over-provisioning
4. **Revise route filters** - Minimize tráfego Microsoft Peering
5. **Considere compartilhamento** - Circuit authorizations

## Troubleshooting

### Circuit Não Provisiona
- Verifique service key com provider
- Confirme peering location correto
- Valide bandwidth suportado
- Aguarde provisionamento do provider

### Peering Down
- Verifique configuração BGP
- Valide IPs de peering
- Confirme VLAN IDs únicos
- Teste conectividade física

### Rotas Não Anunciadas
- Verifique Route Filters (Microsoft Peering)
- Valide BGP configuration
- Confirme advertised prefixes
- Check AS Path

### Performance Issues
- Verifique bandwidth utilization
- Valide latência do circuit
- Teste com FastPath
- Review routing weights

## Estados de Provisionamento

### Service Provider States
- **NotProvisioned**: Service provider não provisionou ainda
- **Provisioning**: Em processo de provisionamento
- **Provisioned**: Circuit pronto para uso
- **Deprovisioning**: Em processo de desprovisionamento

### Circuit States
- **Enabled**: Circuit ativo
- **Disabled**: Circuit desabilitado

## Limitações

### Standard SKU
- Conectividade regional apenas
- Máximo 4,000 rotas
- Sem Global Reach
- Sem conectividade cross-region

### Premium SKU
- Máximo 10,000 rotas
- Custo adicional
- Requer validação para algumas regiões

### Local SKU
- Uma região Azure específica apenas
- Metered Data apenas
- Sem Microsoft Peering option
- Private Peering apenas

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure com permissões adequadas
- Contrato com Service Provider
- Configuração BGP (ASN, IPs)