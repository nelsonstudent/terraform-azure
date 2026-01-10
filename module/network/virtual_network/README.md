# Módulo Terraform - Azure Virtual Network

Este módulo Terraform cria e gerencia uma Azure Virtual Network (VNet) completa com subnets, Network Security Groups (NSGs), Route Tables, VNet Peering, NAT Gateways, Azure Bastion e VPN Gateway.

## Recursos Criados

- **Virtual Network** - Rede virtual principal
- **Subnets** - Sub-redes com delegações e service endpoints (opcional)
- **Network Security Groups (NSGs)** - Grupos de segurança com regras (opcional)
- **Route Tables** - Tabelas de roteamento com rotas customizadas (opcional)
- **VNet Peering** - Peering entre VNets (opcional)
- **NAT Gateways** - Gateways NAT para saída de internet (opcional)
- **Azure Bastion** - Acesso seguro a VMs via RDP/SSH (opcional)
- **VPN Gateway** - Gateway VPN para conectividade híbrida (opcional)
- **Network Watcher** - Monitoramento e diagnóstico de rede (opcional)
- **NSG Flow Logs** - Logs de fluxo de rede (opcional)

## Características

✅ VNet com múltiplos address spaces  
✅ Subnets com service endpoints  
✅ Subnet delegation para serviços PaaS  
✅ NSGs com regras de segurança  
✅ Route Tables com rotas customizadas  
✅ VNet Peering (hub-spoke, mesh)  
✅ NAT Gateway para saída de internet  
✅ Azure Bastion para acesso seguro  
✅ VPN Gateway (Site-to-Site, Point-to-Site)  
✅ Network Watcher e Flow Logs  
✅ Traffic Analytics  
✅ DDoS Protection Plan  
✅ Diagnósticos e monitoramento  

## Uso Básico

```hcl
module "virtual_network" {
  source = "./modules/virtual_network"

  name                = "my-vnet"
  resource_group_name = "my-resource-group"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name             = "subnet-app"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name             = "subnet-db"
      address_prefixes = ["10.0.2.0/24"]
    }
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo Completo com NSGs e Route Tables

```hcl
module "virtual_network" {
  source = "./modules/virtual_network"

  name                = "myapp-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  # Subnets
  subnets = [
    {
      name                                      = "frontend-subnet"
      address_prefixes                          = ["10.0.1.0/24"]
      service_endpoints                         = ["Microsoft.Storage", "Microsoft.Sql"]
      private_endpoint_network_policies_enabled = true
    },
    {
      name             = "backend-subnet"
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.KeyVault"]
    },
    {
      name             = "data-subnet"
      address_prefixes = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Sql"]
      private_endpoint_network_policies_enabled = true
    }
  ]

  # Network Security Groups
  network_security_groups = [
    {
      name = "frontend-nsg"
      security_rules = [
        {
          name                       = "allow-http"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
          description                = "Allow HTTP from Internet"
        },
        {
          name                       = "allow-https"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
          description                = "Allow HTTPS from Internet"
        }
      ]
    },
    {
      name = "backend-nsg"
      security_rules = [
        {
          name                       = "allow-frontend"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = ["8080", "8443"]
          source_address_prefix      = "10.0.1.0/24"
          destination_address_prefix = "*"
          description                = "Allow from frontend subnet"
        },
        {
          name                       = "deny-internet"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
          description                = "Deny all from Internet"
        }
      ]
    }
  ]

  # NSG to Subnet Associations
  nsg_subnet_associations = {
    "frontend-assoc" = {
      subnet_name = "frontend-subnet"
      nsg_name    = "frontend-nsg"
    }
    "backend-assoc" = {
      subnet_name = "backend-subnet"
      nsg_name    = "backend-nsg"
    }
  }

  # Route Tables
  route_tables = [
    {
      name = "frontend-rt"
      routes = [
        {
          name                   = "to-firewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.100.4"
        }
      ]
    }
  ]

  # Route Table to Subnet Associations
  route_table_subnet_associations = {
    "frontend-rt-assoc" = {
      subnet_name      = "frontend-subnet"
      route_table_name = "frontend-rt"
    }
  }

  tags = {
    Environment = "Production"
    Application = "MyApp"
  }
}
```

## Exemplo com NAT Gateway

```hcl
module "virtual_network_nat" {
  source = "./modules/virtual_network"

  name                = "myapp-vnet-nat"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.1.0.0/16"]

  subnets = [
    {
      name             = "private-subnet-1"
      address_prefixes = ["10.1.1.0/24"]
    },
    {
      name             = "private-subnet-2"
      address_prefixes = ["10.1.2.0/24"]
    }
  ]

  # NAT Gateways
  nat_gateways = [
    {
      name                    = "myapp-nat-gateway"
      sku_name                = "Standard"
      idle_timeout_in_minutes = 10
      zones                   = ["1", "2", "3"]
      subnet_associations     = ["private-subnet-1", "private-subnet-2"]
    }
  ]

  # Public IPs para NAT Gateway
  nat_gateway_public_ips = {
    "myapp-nat-gateway" = 2  # 2 Public IPs
  }

  tags = {
    Environment = "Production"
    NAT         = "Enabled"
  }
}
```

## Exemplo com Azure Bastion

```hcl
module "virtual_network_bastion" {
  source = "./modules/virtual_network"

  name                = "myapp-vnet-bastion"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.2.0.0/16"]

  subnets = [
    {
      name             = "vm-subnet"
      address_prefixes = ["10.2.1.0/24"]
    }
  ]

  # Azure Bastion
  create_bastion = true
  bastion_config = {
    name                   = "myapp-bastion"
    sku                    = "Standard"
    copy_paste_enabled     = true
    file_copy_enabled      = true
    ip_connect_enabled     = true
    scale_units            = 4
    shareable_link_enabled = false
    tunneling_enabled      = true
  }

  tags = {
    Environment = "Production"
    Bastion     = "Enabled"
  }
}
```

## Exemplo Hub-Spoke com VNet Peering

```hcl
# Hub VNet
module "hub_vnet" {
  source = "./modules/virtual_network"

  name                = "hub-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name             = "firewall-subnet"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name             = "gateway-subnet"
      address_prefixes = ["10.0.2.0/24"]
    }
  ]

  # VPN Gateway
  create_vpn_gateway = true
  vpn_gateway_config = {
    name       = "hub-vpn-gateway"
    type       = "Vpn"
    vpn_type   = "RouteBased"
    sku        = "VpnGw1"
    generation = "Generation1"
    enable_bgp = false
  }

  tags = {
    Environment = "Production"
    Type        = "Hub"
  }
}

# Spoke 1 VNet
module "spoke1_vnet" {
  source = "./modules/virtual_network"

  name                = "spoke1-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.1.0.0/16"]

  subnets = [
    {
      name             = "app-subnet"
      address_prefixes = ["10.1.1.0/24"]
    }
  ]

  # Peering para Hub
  vnet_peerings = [
    {
      name                         = "spoke1-to-hub"
      remote_virtual_network_id    = module.hub_vnet.id
      allow_virtual_network_access = true
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = true
    }
  ]

  tags = {
    Environment = "Production"
    Type        = "Spoke"
  }
}

# Spoke 2 VNet
module "spoke2_vnet" {
  source = "./modules/virtual_network"

  name                = "spoke2-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.2.0.0/16"]

  subnets = [
    {
      name             = "data-subnet"
      address_prefixes = ["10.2.1.0/24"]
    }
  ]

  # Peering para Hub
  vnet_peerings = [
    {
      name                         = "spoke2-to-hub"
      remote_virtual_network_id    = module.hub_vnet.id
      allow_virtual_network_access = true
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = true
    }
  ]

  tags = {
    Environment = "Production"
    Type        = "Spoke"
  }
}

# Peering reverso no Hub
module "hub_peering_spoke1" {
  source = "./modules/virtual_network"
  # ... (configurar peerings reversos)
}
```

## Exemplo com Subnet Delegation (PostgreSQL)

```hcl
module "virtual_network_delegation" {
  source = "./modules/virtual_network"

  name                = "myapp-vnet-db"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.3.0.0/16"]

  subnets = [
    {
      name             = "app-subnet"
      address_prefixes = ["10.3.1.0/24"]
    },
    {
      name                                          = "postgresql-subnet"
      address_prefixes                              = ["10.3.2.0/24"]
      private_endpoint_network_policies_enabled     = false
      private_link_service_network_policies_enabled = false
      service_endpoints                             = ["Microsoft.Storage"]
      
      delegations = [
        {
          name = "postgresql-delegation"
          service_delegation = {
            name = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action"
            ]
          }
        }
      ]
    }
  ]

  tags = {
    Environment = "Production"
    Database    = "PostgreSQL"
  }
}
```

## Exemplo com Flow Logs e Traffic Analytics

```hcl
module "virtual_network_monitoring" {
  source = "./modules/virtual_network"

  name                = "myapp-vnet-monitored"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.4.0.0/16"]

  subnets = [
    {
      name             = "monitored-subnet"
      address_prefixes = ["10.4.1.0/24"]
    }
  ]

  network_security_groups = [
    {
      name = "monitored-nsg"
      security_rules = [
        {
          name                       = "allow-https"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  ]

  nsg_subnet_associations = {
    "monitored-assoc" = {
      subnet_name = "monitored-subnet"
      nsg_name    = "monitored-nsg"
    }
  }

  # Network Watcher
  create_network_watcher = true
  network_watcher_name   = "nw-myapp"

  # Flow Logs
  enable_flow_logs               = true
  flow_logs_storage_account_id   = azurerm_storage_account.flowlogs.id
  flow_logs_retention_days       = 30

  # Traffic Analytics
  flow_logs_traffic_analytics = {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.main.location
    workspace_resource_id = azurerm_log_analytics_workspace.main.id
    interval_in_minutes   = 10
  }

  # Diagnostic Settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "Production"
    Monitoring  = "Full"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome da Virtual Network | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `address_space` | Blocos de endereços CIDR | `list(string)` | - | Sim |
| `dns_servers` | Servidores DNS customizados | `list(string)` | `[]` | Não |
| `subnets` | Lista de subnets | `list(object)` | `[]` | Não |
| `network_security_groups` | Lista de NSGs | `list(object)` | `[]` | Não |
| `route_tables` | Lista de Route Tables | `list(object)` | `[]` | Não |
| `vnet_peerings` | Lista de VNet Peerings | `list(object)` | `[]` | Não |
| `nat_gateways` | Lista de NAT Gateways | `list(object)` | `[]` | Não |
| `create_bastion` | Criar Azure Bastion | `bool` | `false` | Não |
| `create_vpn_gateway` | Criar VPN Gateway | `bool` | `false` | Não |
| `enable_flow_logs` | Habilitar NSG Flow Logs | `bool` | `false` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID da Virtual Network |
| `name` | Nome da Virtual Network |
| `address_space` | Blocos de endereços |
| `subnet_ids` | Map de IDs das subnets |
| `subnets` | Informações detalhadas das subnets |
| `nsg_ids` | Map de IDs dos NSGs |
| `route_table_ids` | Map de IDs das Route Tables |
| `nat_gateways` | Informações dos NAT Gateways |
| `bastion_id` | ID do Azure Bastion |
| `vpn_gateway_id` | ID do VPN Gateway |
| `vnet_summary` | Resumo das informações da VNet |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## Address Spaces Recomendados

### Ambientes Pequenos
- **10.0.0.0/24** (256 IPs) - Dev/Test
- **10.0.1.0/24** (256 IPs) - Staging
- **10.0.2.0/24** (256 IPs) - Production

### Ambientes Médios
- **10.0.0.0/16** (65,536 IPs) - Hub
- **10.1.0.0/16** (65,536 IPs) - Spoke 1
- **10.2.0.0/16** (65,536 IPs) - Spoke 2

### Ambientes Grandes
- **10.0.0.0/8** (16,777,216 IPs) - Enterprise completa

## Service Endpoints Disponíveis

- **Microsoft.Storage** - Azure Storage
- **Microsoft.Sql** - Azure SQL Database
- **Microsoft.AzureCosmosDB** - Azure Cosmos DB
- **Microsoft.KeyVault** - Azure Key Vault
- **Microsoft.ServiceBus** - Azure Service Bus
- **Microsoft.EventHub** - Azure Event Hubs
- **Microsoft.AzureActiveDirectory** - Azure AD
- **Microsoft.ContainerRegistry** - Azure Container Registry
- **Microsoft.CognitiveServices** - Azure Cognitive Services
- **Microsoft.Web** - Azure App Service

## Delegações Comuns

### Azure Database
```hcl
delegations = [{
  name = "postgresql-delegation"
  service_delegation = {
    name = "Microsoft.DBforPostgreSQL/flexibleServers"
    actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}]
```

### Azure App Service
```hcl
delegations = [{
  name = "webapp-delegation"
  service_delegation = {
    name = "Microsoft.Web/serverFarms"
    actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }
}]
```

### Azure Container Instances
```hcl
delegations = [{
  name = "aci-delegation"
  service_delegation = {
    name = "Microsoft.ContainerInstance/containerGroups"
    actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }
}]
```

## NSG Security Rules

### Regras de Exemplo

#### Allow HTTP/HTTPS
```hcl
{
  name                       = "allow-web"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = ["80", "443"]
  source_address_prefix      = "Internet"
  destination_address_prefix = "*"
}
```

#### Allow SSH from Management Subnet
```hcl
{
  name                       = "allow-ssh-mgmt"
  priority                   = 200
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "10.0.0.0/24"
  destination_address_prefix = "*"
}
```

#### Deny All Inbound (última regra)
```hcl
{
  name                       = "deny-all-inbound"
  priority                   = 4096
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

## Melhores Práticas

### Planejamento de Rede
1. **Use address spaces não-sobrepostos** - Evite conflitos de IP
2. **Reserve espaço para crescimento** - Use blocos maiores que o necessário
3. **Planeje subnets por função** - Frontend, backend, dados, management
4. **Use subnet mínima de /27** - Para permitir expansão (32 IPs)
5. **Reserve IPs para Azure** - Primeiros 4 e último IP são reservados

### Segurança
1. **Use NSGs em todas as subnets** - Defesa em profundidade
2. **Implemente regras deny-all** - Abordagem whitelist
3. **Habilite Flow Logs** - Para auditoria e troubleshooting
4. **Use Service Endpoints** - Para tráfego privado a PaaS
5. **Considere Private Endpoints** - Para isolamento total
6. **Implemente DDoS Protection** - Para ambientes críticos

### Conectividade
1. **Use Hub-Spoke para múltiplas VNets** - Centraliza conectividade
2. **Configure UDRs para firewall** - Force traffic através de NVA
3. **Use NAT Gateway** - Para saída consistente de internet
4. **Implemente Azure Bastion** - Elimina necessidade de jump boxes

### Monitoramento
1. **Habilite Network Watcher** - Em todas as regiões
2. **Configure Traffic Analytics** - Para visibilidade de tráfego
3. **Use Connection Monitor** - Para monitorar conectividade
4. **Configure alertas** - Para anomalias de tráfego

## Subnet Reservadas

Algumas subnets têm nomes reservados no Azure:

- **GatewaySubnet** - Para VPN/ExpressRoute Gateway (mínimo /27)
- **AzureFirewallSubnet** - Para Azure Firewall (mínimo /26)
- **AzureBastionSubnet** - Para Azure Bastion (mínimo /26)
- **RouteServerSubnet** - Para Azure Route Server (mínimo /27)

## VNet Peering

### Considerações
- **Sem transitivity** - A→B e B→C não significa A→C
- **Use Hub-Spoke** - Para conectividade transiente via hub
- **Global peering** - Possível entre regiões
- **Baixa latência** - Tráfego na rede Microsoft backbone
- **Sem downtime** - Configuração não afeta recursos existentes

## Troubleshooting

### Erro: "Subnet has delegations"
Remove a delegação antes de deletar a subnet ou o serviço associado.

### Erro: "Address space overlaps"
Verifique se não há sobreposição com VNets peered ou on-premises.

### Erro: "Cannot delete subnet with resources"
Delete todos os recursos (NICs, Private Endpoints) antes de deletar subnet.

### Tráfego bloqueado entre subnets
Verifique NSG rules e UDRs que possam estar bloqueando tráfego.

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure com permissões adequadas

## Limitações

- Máximo 500 VNets por subscription por região
- Máximo 3000 subnets por VNet
- Máximo 400 peerings por VNet
- Flow timeout: 4-30 minutos
- NSG: 100-4096 prioridade