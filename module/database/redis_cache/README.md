# Módulo Terraform - Azure Redis Cache

Este módulo Terraform cria e gerencia uma instância do Azure Redis Cache (Azure Cache for Redis) com todas as suas funcionalidades, incluindo clustering, replicação, private endpoints e diagnósticos.

## Recursos Criados

- **Azure Redis Cache** - Instância principal do Redis
- **Patch Schedule** - Janela de manutenção para patches (opcional)
- **Firewall Rules** - Regras de firewall para controle de acesso (opcional)
- **Private Endpoint** - Endpoint privado para acesso via VNet (opcional)
- **Diagnostic Settings** - Configurações de monitoramento e logs (opcional)

## Características

✅ Suporte a todos os SKUs (Basic, Standard, Premium)  
✅ Clustering e sharding (Premium)  
✅ Replicação geográfica (Premium)  
✅ VNet injection (Premium)  
✅ Zone redundancy (Premium)  
✅ Backup e restore (RDB e AOF)  
✅ Private endpoints  
✅ Firewall rules  
✅ Managed Identity  
✅ TLS 1.2  
✅ Diagnósticos e monitoramento  

## Uso Básico

```hcl
module "redis_cache" {
  source = "./modules/redis_cache"

  name                = "my-redis-cache"
  resource_group_name = "my-resource-group"
  location            = "eastus"
  
  capacity = 1
  family   = "C"
  sku_name = "Standard"

  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo Standard com Firewall Rules

```hcl
module "redis_cache" {
  source = "./modules/redis_cache"

  name                = "myapp-redis"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  capacity = 2
  family   = "C"
  sku_name = "Standard"

  enable_non_ssl_port           = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  # Configurações do Redis
  redis_configuration = {
    enable_authentication = true
    maxmemory_policy      = "allkeys-lru"
    maxmemory_reserved    = 50
    maxmemory_delta       = 50
  }

  # Regras de Firewall
  firewall_rules = [
    {
      name             = "office-network"
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    },
    {
      name             = "app-servers"
      start_ip_address = "198.51.100.10"
      end_ip_address   = "198.51.100.20"
    }
  ]

  # Janela de Manutenção
  patch_schedule = [
    {
      day_of_week    = "Sunday"
      start_hour_utc = 3
      maintenance_window = "PT5H"
    }
  ]

  tags = {
    Environment = "Production"
    Application = "MyApp"
  }
}
```

## Exemplo Premium com Clustering e VNet

```hcl
module "redis_premium" {
  source = "./modules/redis_cache"

  name                = "myapp-redis-premium"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  capacity = 1
  family   = "P"
  sku_name = "Premium"

  # Features Premium
  shard_count          = 3
  replicas_per_primary = 2
  zones                = ["1", "2", "3"]
  
  # VNet injection
  subnet_id                 = azurerm_subnet.redis.id
  private_static_ip_address = "10.0.1.10"

  enable_non_ssl_port           = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  # Backup RDB
  redis_configuration = {
    enable_authentication       = true
    maxmemory_policy            = "volatile-lru"
    rdb_backup_enabled          = true
    rdb_backup_frequency        = 60
    rdb_backup_max_snapshot_count = 1
    rdb_storage_connection_string = azurerm_storage_account.backup.primary_connection_string
  }

  tags = {
    Environment = "Production"
    Tier        = "Premium"
  }
}
```

## Exemplo com Private Endpoint

```hcl
module "redis_private" {
  source = "./modules/redis_cache"

  name                = "myapp-redis-private"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  capacity = 1
  family   = "C"
  sku_name = "Standard"

  public_network_access_enabled = false

  # Private Endpoint
  enable_private_endpoint     = true
  private_endpoint_subnet_id  = azurerm_subnet.endpoints.id
  private_dns_zone_ids        = [azurerm_private_dns_zone.redis.id]

  tags = {
    Environment = "Production"
    Network     = "Private"
  }
}
```

## Exemplo com Diagnósticos e Monitoramento

```hcl
module "redis_monitored" {
  source = "./modules/redis_cache"

  name                = "myapp-redis"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  capacity = 2
  family   = "C"
  sku_name = "Standard"

  # Diagnósticos
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  diagnostic_logs = [
    "ConnectedClientList"
  ]
  
  diagnostic_metrics = [
    "AllMetrics"
  ]

  # Managed Identity para acesso a recursos
  identity_type = "SystemAssigned"

  tags = {
    Environment = "Production"
    Monitoring  = "Enabled"
  }
}
```

## Exemplo com AOF Backup (Premium)

```hcl
module "redis_aof" {
  source = "./modules/redis_cache"

  name                = "myapp-redis-aof"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  capacity = 1
  family   = "P"
  sku_name = "Premium"

  # AOF Backup (mais durável que RDB)
  redis_configuration = {
    enable_authentication           = true
    maxmemory_policy                = "allkeys-lru"
    aof_backup_enabled              = true
    aof_storage_connection_string_0 = azurerm_storage_account.backup1.primary_connection_string
    aof_storage_connection_string_1 = azurerm_storage_account.backup2.primary_connection_string
  }

  tags = {
    Environment = "Production"
    Backup      = "AOF"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome do Redis Cache | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `capacity` | Tamanho do cache (0-6) | `number` | - | Sim |
| `family` | Família do SKU (C ou P) | `string` | - | Sim |
| `sku_name` | SKU (Basic, Standard, Premium) | `string` | - | Sim |
| `enable_non_ssl_port` | Habilitar porta não-SSL | `bool` | `false` | Não |
| `minimum_tls_version` | Versão mínima do TLS | `string` | `"1.2"` | Não |
| `shard_count` | Número de shards (Premium) | `number` | `null` | Não |
| `replicas_per_primary` | Réplicas por primary (Premium) | `number` | `null` | Não |
| `zones` | Zonas de disponibilidade (Premium) | `list(string)` | `null` | Não |
| `subnet_id` | ID da subnet (Premium) | `string` | `null` | Não |
| `redis_configuration` | Configurações do Redis | `object` | Ver variables.tf | Não |
| `patch_schedule` | Janela de manutenção | `list(object)` | `[]` | Não |
| `firewall_rules` | Regras de firewall | `list(object)` | `[]` | Não |
| `enable_private_endpoint` | Habilitar Private Endpoint | `bool` | `false` | Não |
| `enable_diagnostic_settings` | Habilitar diagnósticos | `bool` | `false` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID do Redis Cache |
| `name` | Nome do Redis Cache |
| `hostname` | Hostname para conexão |
| `ssl_port` | Porta SSL (6380) |
| `port` | Porta não-SSL (6379) |
| `primary_access_key` | Chave de acesso primária (sensível) |
| `primary_connection_string` | Connection string primária (sensível) |
| `connection_strings` | Connection strings formatadas para diferentes bibliotecas |
| `endpoint_info` | Informações de endpoint |
| `performance_info` | Informações de capacidade e performance |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## SKUs e Capacidades

### Basic (Desenvolvimento/Teste)
- Sem SLA
- Sem replicação
- Capacidades: C0 (250MB) a C6 (26GB)

### Standard (Produção)
- SLA 99.9%
- Replicação em 2 nós
- Capacidades: C0 (250MB) a C6 (26GB)

### Premium (Enterprise)
- SLA 99.95% (até 99.99% com zones)
- Clustering e sharding
- VNet injection
- Replicação geográfica
- Zone redundancy
- Capacidades: P1 (6GB) a P5 (120GB)

## Tamanhos de Cache

| Capacity | Basic/Standard (C) | Premium (P) |
|----------|-------------------|-------------|
| 0 | 250 MB | - |
| 1 | 1 GB | 6 GB |
| 2 | 2.5 GB | 13 GB |
| 3 | 6 GB | 26 GB |
| 4 | 13 GB | 53 GB |
| 5 | 26 GB | 120 GB |
| 6 | 53 GB | - |

## Políticas de Eviction (maxmemory-policy)

- **volatile-lru**: Remove chaves com TTL usando LRU
- **allkeys-lru**: Remove qualquer chave usando LRU
- **volatile-lfu**: Remove chaves com TTL usando LFU
- **allkeys-lfu**: Remove qualquer chave usando LFU
- **volatile-random**: Remove chaves com TTL aleatoriamente
- **allkeys-random**: Remove qualquer chave aleatoriamente
- **volatile-ttl**: Remove chaves com TTL mais curto
- **noeviction**: Retorna erro quando memória cheia

## Backup e Restore

### RDB (Snapshot)
- Backup periódico completo
- Frequências: 15, 30, 60, 360, 720, 1440 minutos
- Apenas Premium SKU

### AOF (Append Only File)
- Persistência contínua
- Mais durável que RDB
- Requer 2 Storage Accounts
- Apenas Premium SKU

## Connection Strings

O módulo fornece connection strings formatadas para diferentes bibliotecas:

### StackExchange.Redis (.NET)
```csharp
var redis = ConnectionMultiplexer.Connect(
    "hostname:6380,password=key,ssl=True,abortConnect=False"
);
```

### node-redis (Node.js)
```javascript
const client = redis.createClient({
    url: 'rediss://:key@hostname:6380'
});
```

### ServiceStack.Redis
```csharp
var redisManager = new RedisManagerPool(
    "key@hostname:6380?ssl=true"
);
```

## Segurança

Este módulo implementa as seguintes práticas de segurança por padrão:

- ✅ TLS 1.2 obrigatório
- ✅ SSL habilitado (porta 6380)
- ✅ Autenticação habilitada
- ✅ Porta não-SSL desabilitada por padrão
- ✅ Suporte a Private Endpoints
- ✅ Firewall rules
- ✅ Managed Identity
- ✅ VNet injection (Premium)

## Monitoramento

Métricas importantes para monitorar:

- **CPU**: < 80% recomendado
- **Memory**: < 80% recomendado
- **Server Load**: < 80% recomendado
- **Connected Clients**: Monitorar picos
- **Cache Hits/Misses**: Taxa de hit > 80%
- **Evicted Keys**: Indicador de pressão de memória
- **Network Bandwidth**: Verificar limites do SKU

## Melhores Práticas

1. **Use Standard ou Premium em produção** - Basic não tem SLA
2. **Habilite apenas SSL** - Desabilite porta não-SSL
3. **Configure patch schedule** - Evite patches durante horário de pico
4. **Use clustering (Premium)** - Para datasets grandes (>26GB)
5. **Configure backups (Premium)** - Use RDB ou AOF
6. **Use Private Endpoints** - Para segurança máxima
7. **Monitore métricas** - CPU, memória e taxa de hit
8. **Implemente retry logic** - Para lidar com failovers
9. **Use connection pooling** - Reutilize conexões
10. **Configure timeouts apropriados** - Evite conexões penduradas

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure com permissões adequadas

## Limitações

- Basic SKU não suporta replicação ou persistence
- VNet injection apenas em Premium
- Clustering apenas em Premium
- AOF backup apenas em Premium
- Zone redundancy apenas em Premium
- Capacidade máxima: 53GB (Standard) ou 120GB (Premium single node)

## Troubleshooting

### Erro: "Cannot change SKU"
Não é possível alterar o SKU de uma instância existente. Você precisa criar uma nova instância.

### Erro: "Subnet already in use"
Cada Redis Cache Premium precisa de sua própria subnet dedicada.

### Conexão lenta
Verifique se você está usando a porta SSL (6380) e se está na mesma região.