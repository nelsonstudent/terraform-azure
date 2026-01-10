# Módulo Terraform - Azure NAT Gateway

Este módulo Terraform provisiona um Azure NAT Gateway com Public IPs, associações de subnets, diagnostic settings e alertas de monitoramento.

## Características

- Provisionamento de NAT Gateway com SKU Standard
- Criação automática de Public IPs
- Suporte a Public IP Prefix para blocos de IPs
- Associação com múltiplas subnets
- Availability Zones support
- Diagnostic Settings integrados
- Alertas de SNAT ports e Data Path availability
- Configuração de idle timeout
- Suporte a até 16 Public IPs por NAT Gateway

## O que é NAT Gateway?

Azure NAT Gateway é um serviço gerenciado que fornece conectividade de saída (outbound) para recursos em VNets privadas, permitindo que acessem a internet sem expor seus IPs privados.

### Benefícios

- ✅ **Alta disponibilidade** - 99.9% SLA
- ✅ **Escalabilidade** - Até 64k conexões simultâneas por IP
- ✅ **Segurança** - IPs privados não são expostos
- ✅ **Previsibilidade** - IPs públicos estáticos
- ✅ **Sem gerenciamento** - Serviço totalmente gerenciado

## Uso Básico

```hcl
module "nat_gateway" {
  source = "./modules/network/nat_gateway"

  name                = "nat-gateway-prod"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  # Criar 1 Public IP automaticamente
  public_ip_count = 1

  # Associar a subnets
  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"]
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Múltiplos Public IPs

```hcl
module "nat_gateway" {
  source = "./modules/network/nat_gateway"

  name                = "nat-gateway-prod"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  # Criar 3 Public IPs para maior capacidade
  public_ip_count = 3

  # Timeout de 10 minutos
  idle_timeout_in_minutes = 10

  # Associar a múltiplas subnets
  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"],
    module.virtual_network.subnet_ids["subnet-workers"],
    module.virtual_network.subnet_ids["subnet-batch"]
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Availability Zones

```hcl
module "nat_gateway" {
  source = "./modules/network/nat_gateway"

  name                = "nat-gateway-prod"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  # NAT Gateway em múltiplas zonas
  zones = ["1", "2", "3"]

  public_ip_count = 2

  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"]
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Public IPs Existentes

```hcl
# Public IPs já existentes
data "azurerm_public_ip" "existing" {
  for_each = toset(["pip-nat-1", "pip-nat-2"])
  
  name                = each.value
  resource_group_name = "rg-network-prod"
}

module "nat_gateway" {
  source = "./modules/network/nat_gateway"

  name                = "nat-gateway-prod"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  # Não criar novos IPs
  create_public_ips = false

  # Usar IPs existentes
  existing_public_ip_ids = [
    for ip in data.azurerm_public_ip.existing : ip.id
  ]

  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"]
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Public IP Prefix

```hcl
module "nat_gateway" {
  source = "./modules/network/nat_gateway"

  name                = "nat-gateway-prod"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  # Criar Public IP Prefix com 16 IPs (/28 = 16 IPs)
  public_ip_prefix_length = 28

  # Criar IPs a partir do prefix
  create_public_ips = true
  public_ip_count   = 4

  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"]
  ]

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Diagnostic Settings

```hcl
module "nat_gateway" {
  source = "./modules/network/nat_gateway"

  name                = "nat-gateway-prod"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  public_ip_count = 2

  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"]
  ]

  # Habilitar diagnósticos
  diagnostic_settings = {
    enabled                    = true
    name                       = "nat-diagnostics"
    log_analytics_workspace_id = module.log_analytics.id
    
    metric_categories = ["AllMetrics"]
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo com Alertas

```hcl
module "nat_gateway" {
  source = "./modules/network/nat_gateway"

  name                = "nat-gateway-prod"
  location            = "eastus"
  resource_group_name = "rg-network-prod"

  public_ip_count = 2

  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"]
  ]

  # Configurar alertas
  alerts = {
    enabled          = true
    action_group_ids = [module.action_group.id]
    
    # Alertar quando SNAT ports > 80%
    snat_port_threshold = 80
    
    # Alertar quando disponibilidade < 90%
    data_path_threshold = 90
  }

  tags = {
    Environment = "Production"
  }
}
```

## Exemplo Completo - Alta Disponibilidade

```hcl
# Resource Group
module "resource_group" {
  source   = "./modules/governance/resource_group"
  name     = "rg-network-prod"
  location = "eastus"
}

# Virtual Network
module "virtual_network" {
  source              = "./modules/network/virtual_network"
  name                = "vnet-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "subnet-app" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "subnet-data" = {
      address_prefixes = ["10.0.2.0/24"]
    }
    "subnet-workers" = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
}

# Log Analytics
module "log_analytics" {
  source              = "./modules/observability/log_analytics_workspace"
  name                = "log-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
}

# Action Group para Alertas
module "action_group" {
  source              = "./modules/observability/azure_monitor"
  name                = "ag-network-alerts"
  resource_group_name = module.resource_group.name
  short_name          = "netalerts"
  
  email_receivers = [
    {
      name          = "NetworkTeam"
      email_address = "network-team@company.com"
    }
  ]
}

# NAT Gateway com Alta Disponibilidade
module "nat_gateway" {
  source              = "./modules/network/nat_gateway"
  name                = "nat-prod"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  # Availability Zones
  zones = ["1", "2", "3"]

  # Múltiplos IPs para alta capacidade
  public_ip_count = 4

  # Timeout estendido
  idle_timeout_in_minutes = 15

  # Associar todas as subnets privadas
  subnet_ids = [
    module.virtual_network.subnet_ids["subnet-app"],
    module.virtual_network.subnet_ids["subnet-data"],
    module.virtual_network.subnet_ids["subnet-workers"]
  ]

  # Diagnósticos
  diagnostic_settings = {
    enabled                    = true
    log_analytics_workspace_id = module.log_analytics.id
    metric_categories          = ["AllMetrics"]
  }

  # Alertas
  alerts = {
    enabled             = true
    action_group_ids    = [module.action_group.id]
    snat_port_threshold = 75
    data_path_threshold = 95
  }

  tags = {
    Environment = "Production"
    CostCenter  = "Networking"
    Criticality = "High"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "nat_gateway_public_ips" {
  value       = module.nat_gateway.public_ip_addresses
  description = "IPs públicos do NAT Gateway"
}

output "nat_capacity" {
  value       = module.nat_gateway.capacity
  description = "Capacidade total do NAT Gateway"
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|:-----------:|
| name | Nome do NAT Gateway | `string` | n/a | sim |
| location | Localização | `string` | n/a | sim |
| resource_group_name | Resource Group | `string` | n/a | sim |
| sku_name | SKU do NAT Gateway | `string` | `"Standard"` | não |
| idle_timeout_in_minutes | Timeout idle (4-120 min) | `number` | `4` | não |
| zones | Availability Zones | `list(string)` | `[]` | não |
| public_ip_count | Número de Public IPs | `number` | `1` | não |
| public_ip_prefix_id | ID do IP Prefix existente | `string` | `null` | não |
| public_ip_prefix_length | Tamanho do IP Prefix | `number` | `null` | não |
| existing_public_ip_ids | IDs de IPs existentes | `list(string)` | `[]` | não |
| subnet_ids | IDs das subnets | `list(string)` | `[]` | não |
| create_public_ips | Criar Public IPs | `bool` | `true` | não |
| public_ip_sku | SKU dos Public IPs | `string` | `"Standard"` | não |
| public_ip_allocation_method | Método de alocação | `string` | `"Static"` | não |
| diagnostic_settings | Configurações de diagnóstico | `object` | ver abaixo | não |
| alerts | Configurações de alertas | `object` | ver abaixo | não |
| tags | Tags | `map(string)` | `{}` | não |

### Diagnostic Settings Padrão

```hcl
{
  enabled = false
}
```

### Alerts Padrão

```hcl
{
  enabled = false
}
```

## Outputs

| Nome | Descrição |
|------|-----------|
| id | ID do NAT Gateway |
| name | Nome do NAT Gateway |
| resource_guid | GUID do recurso |
| location | Localização |
| resource_group_name | Resource Group |
| sku_name | SKU configurado |
| idle_timeout_in_minutes | Timeout configurado |
| zones | Availability Zones |
| public_ip_prefix_id | ID do IP Prefix |
| public_ip_prefix | Objeto do IP Prefix |
| public_ip_ids | IDs dos Public IPs |
| public_ip_addresses | Endereços IP públicos |
| public_ips | Objetos dos Public IPs |
| all_public_ip_ids | Todos os IPs associados |
| subnet_associations | Associações de subnets |
| associated_subnet_ids | IDs das subnets |
| public_ip_associations | Associações de IPs |
| diagnostic_setting_id | ID do diagnostic setting |
| alert_ids | IDs dos alertas |
| capacity | Capacidade total |
| nat_gateway_summary | Resumo completo |
| resource | Objeto completo |

## Capacidade e Limites

### SNAT Ports por Public IP

- **64.512 portas SNAT** por Public IP
- **64.000 destinos** únicos por Public IP

### Cálculo de Capacidade

```
Total SNAT Ports = Número de Public IPs × 64.512

Exemplo com 4 Public IPs:
- Total de portas: 4 × 64.512 = 258.048 portas
- Destinos únicos: 4 × 64.000 = 256.000 destinos
```

### Limites do Serviço

| Item | Limite |
|------|--------|
| Public IPs por NAT Gateway | 16 |
| Subnets por NAT Gateway | 800 |
| Data throughput | 50 Gbps |
| NAT Gateways por VNet | 1 por subnet |

## Idle Timeout

### Valores Recomendados

| Cenário | Timeout | Descrição |
|---------|---------|-----------|
| HTTP/HTTPS curto | 4 min | Requisições rápidas |
| HTTP/HTTPS longo | 10 min | APIs com processamento |
| SSH/RDP | 30 min | Sessões administrativas |
| Database | 15-30 min | Conexões persistentes |
| Streaming | 60-120 min | Conexões de longa duração |

### Comportamento

- Conexões idle por mais tempo que o timeout são fechadas
- Timer é resetado a cada pacote transmitido
- Aplicações devem implementar keep-alive se necessário

## Availability Zones

### Configuração Regional

```hcl
# NAT Gateway redundante em 3 zonas
zones = ["1", "2", "3"]
```

### Benefícios

- ✅ **99.99% SLA** com zonas
- ✅ Proteção contra falhas zonais
- ✅ Public IPs também são zonais
- ✅ Sem custo adicional

### Regiões com Suporte

NAT Gateway com zonas está disponível em regiões como:
- East US, East US 2
- West US 2, West US 3
- Central US
- North Europe, West Europe
- UK South
- E outras...

## Public IP Prefix

### Quando Usar

✅ **Use Public IP Prefix quando:**
- Precisa de bloco contíguo de IPs
- Quer simplificar whitelist de firewall
- Gerencia múltiplos NAT Gateways
- Precisa de previsibilidade de IPs

### Tamanhos Disponíveis

| Prefix Length | Número de IPs | Uso |
|---------------|---------------|-----|
| /31 | 2 | Testes |
| /30 | 4 | Pequeno |
| /29 | 8 | Médio |
| /28 | 16 | Grande |

### Exemplo

```hcl
# Criar prefix de 8 IPs
public_ip_prefix_length = 29

# Criar 4 IPs do prefix
public_ip_count = 4
```

## Métricas e Monitoramento

### Métricas Disponíveis

**SNAT Connection Count**
- Número de conexões SNAT ativas
- Use para dimensionamento

**Bytes Processed**
- Volume de dados processados
- Útil para billing e capacity planning

**Packets Processed**
- Número de pacotes processados
- Identifica padrões de tráfego

**Datapath Availability**
- Disponibilidade do data path
- Critical para SLA

**Packets Dropped**
- Pacotes descartados
- Indica problemas de capacidade

### Queries Úteis (Log Analytics)

```kusto
// SNAT connections por minuto
AzureMetrics
| where ResourceProvider == "MICROSOFT.NETWORK"
| where ResourceType == "NATGATEWAYS"
| where MetricName == "SNATConnectionCount"
| summarize avg(Average) by bin(TimeGenerated, 1m)

// Availability
AzureMetrics
| where MetricName == "DatapathAvailability"
| summarize min(Minimum), avg(Average) by bin(TimeGenerated, 5m)

// Bytes processados por dia
AzureMetrics
| where MetricName == "BytesProcessedCount"
| summarize sum(Total) by bin(TimeGenerated, 1d)
```

## Troubleshooting

### Problema: SNAT Port Exhaustion

**Sintomas:**
- Conexões falhando
- Timeouts intermitentes
- Alert de SNAT ports

**Soluções:**
```hcl
# 1. Adicionar mais Public IPs
public_ip_count = 4  # Aumenta de 1 para 4

# 2. Aumentar idle timeout
idle_timeout_in_minutes = 10

# 3. Implementar connection pooling na aplicação
```

### Problema: Alta Latência

**Sintomas:**
- Latência elevada em requisições
- Conexões lentas

**Soluções:**
```hcl
# 1. Verificar se NAT Gateway está na mesma região
location = "eastus"  # Mesma região da VNet

# 2. Usar Availability Zones
zones = ["1", "2", "3"]

# 3. Verificar métricas de data path
diagnostic_settings = {
  enabled = true
  log_analytics_workspace_id = "..."
}
```

### Problema: Custo Elevado

**Sintomas:**
- Bill maior que esperado

**Soluções:**
```hcl
# 1. Reduzir número de IPs se não necessário
public_ip_count = 1

# 2. Reduzir idle timeout
idle_timeout_in_minutes = 4

# 3. Implementar cache na aplicação
# 4. Usar Private Endpoints quando possível
```

### Verificar Associações

```bash
# Ver NAT Gateway
az network nat gateway show \
  --resource-group rg-network-prod \
  --name nat-gateway-prod

# Ver Public IPs associados
az network nat gateway show \
  --resource-group rg-network-prod \
  --name nat-gateway-prod \
  --query publicIpAddresses

# Ver Subnets associadas
az network vnet subnet list \
  --resource-group rg-network-prod \
  --vnet-name vnet-prod \
  --query "[?natGateway].{Name:name,NAT:natGateway.id}"
```

## Comparação: NAT Gateway vs Alternativas

### NAT Gateway vs Public IP em VMs

| Feature | NAT Gateway | Public IP em VM |
|---------|-------------|-----------------|
| Alta disponibilidade | ✅ 99.9% SLA | ❌ Depende da VM |
| Escalabilidade | ✅ 64k conexões/IP | ⚠️ Limitado |
| Gerenciamento | ✅ Totalmente gerenciado | ❌ Manual |
| IP estático | ✅ Sim | ✅ Sim |
| Custo | 💰 Maior | 💰 Menor |
| Segurança | ✅ IPs privados ocultos | ⚠️ IP público na VM |

### NAT Gateway vs Azure Firewall

| Feature | NAT Gateway | Azure Firewall |
|---------|-------------|----------------|
| Propósito | Outbound NAT | Firewall + NAT |
| Throughput | 50 Gbps | 30 Gbps (Standard) |
| Custo | 💰 ~$45/mês | 💰 ~$1200/mês |
| Regras | ❌ Não | ✅ Sim (FQDN, etc) |
| Inspeção | ❌ Não | ✅ L7 inspection |
| Ideal para | Internet access | Segurança avançada |

## Segurança

### Best Practices

1. ✅ **Use em subnets privadas** - Não exponha recursos
2. ✅ **NSG rules** - Controle tráfego de saída
3. ✅ **Monitor SNAT** - Configure alertas
4. ✅ **Idle timeout** - Configure adequadamente
5. ✅ **Diagnostic logs** - Habilite para auditoria
6. ✅ **Availability Zones** - Use para alta disponibilidade
7. ✅ **Least privilege** - Apenas o necessário

### Exemplo de NSG com NAT Gateway

```hcl
# NSG na subnet com NAT Gateway
resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-subnet"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Permitir saída para internet via NAT Gateway
  security_rule {
    name                       = "allow-internet-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  # Bloquear entrada da internet
  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}
```

## Custo Estimado

### Componentes de Custo

**NAT Gateway** - ~$0.045/hora = ~$32.40/mês

**Public IP** - ~$0.005/hora = ~$3.60/mês por IP

**Data Processed** - ~$0.045/GB

### Cenários de Custo

**Pequeno (1 IP, 100GB/mês)**
- NAT Gateway: $32.40
- Public IP: $3.60
- Data: $4.50
- **Total: ~$40.50/mês**

**Médio (4 IPs, 1TB/mês)**
- NAT Gateway: $32.40
- Public IPs: $14.40
- Data: $45
- **Total: ~$92/mês**

**Grande (16 IPs, 10TB/mês)**
- NAT Gateway: $32.40
- Public IPs: $57.60
- Data: $450
- **Total: ~$540/mês**

## Migração de Alternativas

### De Public IPs em VMs

```hcl
# Antes: VM com Public IP
resource "azurerm_linux_virtual_machine" "main" {
  # ...
  network_interface_ids = [azurerm_network_interface.main.id]
}

resource "azurerm_public_ip" "vm" {
  # Public IP na VM
}

# Depois: VM em subnet privada com NAT Gateway
module "nat_gateway" {
  source = "./modules/network/nat_gateway"
  subnet_ids = [azurerm_subnet.app.id]
}

resource "azurerm_linux_virtual_machine" "main" {
  # Sem Public IP
  # Internet access via NAT Gateway
}
```

## Recursos Criados

- `azurerm_nat_gateway` - NAT Gateway principal
- `azurerm_public_ip` - Public IPs (se create_public_ips = true)
- `azurerm_public_ip_prefix` - IP Prefix (se configurado)
- `azurerm_nat_gateway_public_ip_association` - Associações de IPs
- `azurerm_nat_gateway_public_ip_prefix_association` - Associação de prefix
- `azurerm_subnet_nat_gateway_association` - Associações de subnets
- `azurerm_monitor_diagnostic_setting` - Diagnostic settings (opcional)
- `azurerm_monitor_metric_alert` - Alertas (opcional)

## Dependências

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Virtual Network e Subnets criadas previamente
- Log Analytics Workspace (para diagnósticos)
- Action Groups (para alertas)

## Referências

- [NAT Gateway Documentation](https://docs.microsoft.com/azure/virtual-network/nat-gateway/)
- [NAT Gateway Design](https://docs.microsoft.com/azure/virtual-network/nat-gateway/nat-gateway-resource)
- [Pricing](https://azure.microsoft.com/pricing/details/virtual-network/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway)