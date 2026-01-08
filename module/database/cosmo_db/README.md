# Azure Cosmos DB Terraform Module

Módulo Terraform para provisionar e gerenciar Azure Cosmos DB, banco de dados NoSQL multi-modelo globalmente distribuído, equivalente ao Google Cloud Firestore/Bigtable. Suporta múltiplas APIs (SQL/Core, MongoDB, Cassandra, Gremlin/Graph, Table), geo-replicação, consistência configurável, e throughput provisionado ou serverless.

## Funcionalidades

- ✅ Múltiplas APIs (SQL, MongoDB, Cassandra, Gremlin, Table)
- ✅ Distribuição global (multi-region)
- ✅ 5 níveis de consistência
- ✅ Throughput provisionado ou Serverless
- ✅ Autoscaling
- ✅ Analytical Storage (Synapse Link)
- ✅ Free Tier (400 RU/s + 5 GB)
- ✅ Private Endpoint
- ✅ Geo-replication automática
- ✅ Multi-region writes
- ✅ Backup automático
- ✅ TTL (Time to Live)
- ✅ Change Feed
- ✅ Zone redundancy

## Pré-requisitos

- Terraform >= 1.0
- Provider `hashicorp/azurerm` >= 3.0
- Resource Group existente
- VNet e Subnet (para Private Endpoint)

## APIs Disponíveis

### SQL API (Core API) - Recomendado
- Query SQL-like
- Schema-free JSON
- JavaScript stored procedures
- Multi-document transactions

### MongoDB API
- Wire protocol do MongoDB 4.0/4.2/5.0
- Migrate facilmente do MongoDB
- Drivers MongoDB nativos

### Cassandra API
- CQL (Cassandra Query Language)
- Column-family data model
- Ideal para IoT e time-series

### Gremlin API (Graph)
- Graph database
- Vertices e edges
- Traversal queries (Gremlin)

### Table API
- Key-value store
- Compatível com Azure Table Storage
- Premium features do Cosmos DB

## Modelos de Preço

### Throughput Provisionado
- **Preço**: ~$0.008/hora por 100 RU/s (~$6/mês)
- **Uso**: Workloads previsíveis
- **Características**: RU/s garantidos

### Autoscale
- **Preço**: ~$0.012/hora por 100 RU/s max (~$9/mês)
- **Uso**: Tráfego variável
- **Características**: Scale automático 0-max RU/s

### Serverless
- **Preço**: $0.25 por 1M RU consumidos
- **Uso**: Workloads intermitentes, dev/test
- **Limitações**: 5000 RU/s max, 50 GB max

### Free Tier
- **400 RU/s + 5 GB** grátis por conta
- Ideal para dev/test

## Uso Básico

### Cosmos DB SQL API (Core) - Simples

```hcl
module "cosmos_db" {
  source = "../../modules/database/cosmos_db"

  resource_group_name  = "rg-cosmosdb-prod"
  location             = "Brazil South"
  cosmosdb_account_name = "cosmos-prod-unique"
  
  # SQL API (Core API)
  kind = "GlobalDocumentDB"
  
  # Consistência Session (padrão recomendado)
  consistency_policy = {
    consistency_level = "Session"
  }
  
  # Geo-replication (mínimo 1 localização)
  geo_locations = [
    {
      location          = "Brazil South"
      failover_priority = 0
      zone_redundant    = true
    }
  ]
  
  # Database e Container
  sql_databases = {
    "app-database" = {
      autoscale_max_throughput = 1000  # Autoscale 100-1000 RU/s
    }
  }
  
  sql_containers = {
    "users" = {
      database_name      = "app-database"
      partition_key_path = "/userId"
      autoscale_max_throughput = 1000
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Cosmos DB Serverless

```hcl
module "cosmos_db_serverless" {
  source = "../../modules/database/cosmos_db"

  resource_group_name  = "rg-cosmosdb-dev"
  location             = "Brazil South"
  cosmosdb_account_name = "cosmos-dev-serverless"
  
  # Serverless capability
  capabilities = ["EnableServerless"]
  
  consistency_policy = {
    consistency_level = "Session"
  }
  
  geo_locations = [
    {
      location          = "Brazil South"
      failover_priority = 0
    }
  ]
  
  # Database e Container (sem throughput, serverless)
  sql_databases = {
    "app-database" = {}
  }
  
  sql_containers = {
    "items" = {
      database_name      = "app-database"
      partition_key_path = "/id"
    }
  }
  
  tags = {
    Environment = "development"
  }
}
```

### MongoDB API

```hcl
module "cosmos_db_mongo" {
  source = "../../modules/database/cosmos_db"

  resource_group_name  = "rg-cosmosdb-prod"
  location             = "East US"
  cosmosdb_account_name = "cosmos-mongo-prod"
  
  # MongoDB API
  kind = "MongoDB"
  
  # MongoDB 5.0
  capabilities = ["EnableMongo", "EnableMongoRoleBasedAccessControl"]
  
  consistency_policy = {
    consistency_level = "Session"
  }
  
  geo_locations = [
    {
      location          = "East US"
      failover_priority = 0
      zone_redundant    = true
    },
    {
      location          = "West US"
      failover_priority = 1
    }
  ]
  
  # MongoDB Database
  mongo_databases = {
    "production-db" = {
      autoscale_max_throughput = 4000
    }
  }
  
  # MongoDB Collections
  mongo_collections = {
    "orders" = {
      database_name = "production-db"
      shard_key     = "userId"
      autoscale_max_throughput = 1000
      
      indexes = [
        {
          keys   = ["userId", "createdAt"]
          unique = false
        },
        {
          keys   = ["email"]
          unique = true
        }
      ]
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

## Exemplo Completo (Production-Ready)

```hcl
module "cosmos_db" {
  source = "../../modules/database/cosmos_db"

  # Resource Group
  resource_group_name  = "rg-cosmosdb-prod"
  location             = "Brazil South"
  cosmosdb_account_name = "cosmos-prod-global"
  
  # SQL API (Core API)
  kind = "GlobalDocumentDB"
  
  # Free Tier (apenas para primeira conta)
  enable_free_tier = false
  
  # Consistency Policy - Strong para produção crítica
  consistency_policy = {
    consistency_level = "BoundedStaleness"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }
  
  # Multi-Region com failover automático
  enable_automatic_failover        = true
  enable_multiple_write_locations  = true  # Multi-master
  
  # Geo-replication (3 regiões)
  geo_locations = [
    {
      location          = "Brazil South"
      failover_priority = 0
      zone_redundant    = true
    },
    {
      location          = "East US"
      failover_priority = 1
      zone_redundant    = true
    },
    {
      location          = "West Europe"
      failover_priority = 2
      zone_redundant    = true
    }
  ]
  
  # Analytical Storage (Synapse Link)
  analytical_storage_enabled = true
  analytical_storage_schema_type = "FullFidelity"
  
  # Network Security
  public_network_access_enabled = false
  is_virtual_network_filter_enabled = true
  
  # Virtual Network Rules
  virtual_network_rules = [
    {
      id = azurerm_subnet.apps.id
    },
    {
      id = azurerm_subnet.functions.id
    }
  ]
  
  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.database.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.cosmos.id]
  private_endpoint_subresource_name = "Sql"
  
  # Managed Identity
  identity_type = "SystemAssigned"
  
  # Backup Policy (Continuous 30 days)
  backup_policy = {
    type               = "Continuous"
    storage_redundancy = "Geo"
  }
  
  # Capacity limit (prevenir gastos excessivos)
  capacity_total_throughput_limit = 10000  # 10,000 RU/s máximo
  
  # SQL Databases
  sql_databases = {
    "production-db" = {
      autoscale_max_throughput = 4000  # 400-4000 RU/s
    }
    "analytics-db" = {
      throughput = 400  # Fixed 400 RU/s
    }
  }
  
  # SQL Containers
  sql_containers = {
    "users" = {
      database_name          = "production-db"
      partition_key_path     = "/userId"
      partition_key_version  = 2  # Large partition keys
      autoscale_max_throughput = 4000
      default_ttl            = -1  # Disabled (ou segundos para auto-delete)
      analytical_storage_ttl = -1  # Habilitar analytical storage
      
      # Indexing Policy
      indexing_policy = {
        indexing_mode = "consistent"
        included_paths = ["/*"]
        excluded_paths = ["/\"_etag\"/?"]
        
        # Composite indexes para queries ordenadas
        composite_indexes = [
          [
            { path = "/lastName", order = "ascending" },
            { path = "/firstName", order = "ascending" }
          ]
        ]
        
        # Spatial indexes para geo queries
        spatial_indexes = ["/location/*"]
      }
      
      # Unique keys
      unique_keys = [
        {
          paths = ["/email"]
        }
      ]
    }
    
    "orders" = {
      database_name      = "production-db"
      partition_key_path = "/customerId"
      autoscale_max_throughput = 4000
      default_ttl        = 2592000  # 30 dias
      
      # Conflict resolution para multi-region writes
      conflict_resolution_policy = {
        mode                     = "LastWriterWins"
        conflict_resolution_path = "/_ts"  # timestamp
      }
    }
    
    "sessions" = {
      database_name      = "production-db"
      partition_key_path = "/sessionId"
      autoscale_max_throughput = 1000
      default_ttl        = 3600  # 1 hora - auto-delete
    }
  }
  
  # CORS (para web apps)
  cors_rules = [
    {
      allowed_origins    = ["https://app.example.com", "https://www.example.com"]
      allowed_methods    = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  ]
  
  # Diagnostic Settings
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  tags = {
    Environment = "production"
    Application = "webapp"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  name                  = "cosmos-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
```

## Níveis de Consistência

### Strong (Mais Forte)
```hcl
consistency_policy = {
  consistency_level = "Strong"
}
```
- Linearizability garantida
- Reads sempre retornam última write
- Latência maior
- **Uso**: Dados financeiros, inventário

### Bounded Staleness
```hcl
consistency_policy = {
  consistency_level       = "BoundedStaleness"
  max_interval_in_seconds = 5
  max_staleness_prefix    = 100
}
```
- Bounded lag (5 segundos ou 100 operações)
- Reads podem estar até N versões atrás
- **Uso**: Leaderboards, contadores

### Session (Padrão Recomendado)
```hcl
consistency_policy = {
  consistency_level = "Session"
}
```
- Consistência dentro da mesma sessão
- Read-your-writes garantido
- Melhor custo/benefício
- **Uso**: 90% dos casos

### Consistent Prefix
```hcl
consistency_policy = {
  consistency_level = "ConsistentPrefix"
}
```
- Reads nunca veem writes fora de ordem
- Pode ter lag
- **Uso**: Feeds de notícias, timelines

### Eventual (Mais Fraco)
```hcl
consistency_policy = {
  consistency_level = "Eventual"
}
```
- Menor latência
- Pode ler writes antigas
- **Uso**: Logs, telemetry, analytics

## Connection Strings

### SQL API (.NET)
```csharp
using Microsoft.Azure.Cosmos;

var client = new CosmosClient(
    accountEndpoint: "https://cosmos-prod.documents.azure.com:443/",
    authKeyOrResourceToken: "your-primary-key"
);

var database = client.GetDatabase("production-db");
var container = database.GetContainer("users");

// Query
var query = "SELECT * FROM c WHERE c.userId = @userId";
var queryDefinition = new QueryDefinition(query)
    .WithParameter("@userId", "user123");

var iterator = container.GetItemQueryIterator<User>(queryDefinition);
```

### MongoDB API (Node.js)
```javascript
const { MongoClient } = require('mongodb');

const uri = "mongodb://cosmos-mongo-prod:key@cosmos-mongo-prod.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000";

const client = new MongoClient(uri);

async function run() {
  await client.connect();
  const db = client.db("production-db");
  const collection = db.collection("orders");
  
  const docs = await collection.find({ userId: "user123" }).toArray();
  console.log(docs);
}
```

### SQL API (Python)
```python
from azure.cosmos import CosmosClient, PartitionKey

client = CosmosClient(
    "https://cosmos-prod.documents.azure.com:443/",
    credential="your-primary-key"
)

database = client.get_database_client("production-db")
container = database.get_container_client("users")

# Query
query = "SELECT * FROM c WHERE c.userId = @userId"
parameters = [{"name": "@userId", "value": "user123"}]

items = list(container.query_items(
    query=query,
    parameters=parameters,
    enable_cross_partition_query=True
))
```

## Partition Keys

### Escolha Adequada
✅ **Bom**: Alta cardinalidade, distribuição uniforme
- `/userId` para user data
- `/customerId` para orders
- `/tenantId` para multi-tenant
- `/date` + `/id` (composite)

❌ **Ruim**: Baixa cardinalidade, hot partitions
- `/country` (poucos valores)
- `/status` ("active", "inactive")
- `/type` (poucos tipos)

### Composite Partition Keys (v2)
```hcl
sql_containers = {
  "orders" = {
    partition_key_path    = "/customerId"
    partition_key_version = 2  # Suporta keys > 100 bytes
  }
}
```

## Indexing Policies

### Incluir/Excluir Paths
```hcl
indexing_policy = {
  indexing_mode = "consistent"
  included_paths = ["/*"]  # Indexar tudo
  excluded_paths = [
    "/\"largeField\"/?",   # Excluir campo específico
    "/\"_etag\"/?",        # Excluir system fields
  ]
}
```

### Composite Indexes (para ORDER BY)
```hcl
composite_indexes = [
  [
    { path = "/lastName", order = "ascending" },
    { path = "/firstName", order = "ascending" }
  ]
]
```

Query otimizada:
```sql
SELECT * FROM c ORDER BY c.lastName, c.firstName
```

## TTL (Time to Live)

```hcl
sql_containers = {
  "sessions" = {
    database_name      = "app-db"
    partition_key_path = "/id"
    default_ttl        = 3600  # 1 hora
  }
}
```

**Por item:**
```json
{
  "id": "session123",
  "data": "...",
  "ttl": 7200  // 2 horas para este item
}
```

## Change Feed

### Consumir mudanças (C#)
```csharp
var processor = container
    .GetChangeFeedProcessorBuilder<Item>("myProcessor", HandleChangesAsync)
    .WithInstanceName("consoleHost")
    .WithLeaseContainer(leaseContainer)
    .Build();

await processor.StartAsync();

static async Task HandleChangesAsync(
    ChangeFeedProcessorContext context,
    IReadOnlyCollection<Item> changes,
    CancellationToken cancellationToken)
{
    foreach (var item in changes)
    {
        Console.WriteLine($"Detected change: {item.id}");
    }
}
```

## Analytical Storage (Synapse Link)

```hcl
analytical_storage_enabled = true
analytical_storage_schema_type = "FullFidelity"

sql_containers = {
  "orders" = {
    # ...
    analytical_storage_ttl = -1  # Habilitar
  }
}
```

**Query com Synapse:**
```sql
SELECT 
    c.customerId,
    COUNT(*) as orderCount,
    SUM(c.total) as totalRevenue
FROM OPENROWSET(
    'CosmosDB',
    'Account=cosmos-prod;Database=production-db;Key=xxx',
    orders
) AS c
GROUP BY c.customerId
```

## Multi-Region Writes

```hcl
enable_multiple_write_locations = true

conflict_resolution_policy = {
  mode                     = "LastWriterWins"
  conflict_resolution_path = "/_ts"
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| resource_group_name | Nome do Resource Group | `string` | - | Sim |
| location | Localização primária | `string` | - | Sim |
| cosmosdb_account_name | Nome da conta | `string` | - | Sim |
| kind | API: GlobalDocumentDB, MongoDB, Parse | `string` | `"GlobalDocumentDB"` | Não |
| consistency_policy | Política de consistência | `object` | `Session` | Não |
| geo_locations | Localizações para replicação | `list(object)` | - | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| cosmosdb_account_endpoint | Endpoint da conta |
| cosmosdb_account_primary_key | Primary key |
| cosmosdb_account_connection_strings | Connection strings |
| sql_database_ids | IDs dos databases |
| cosmosdb_account_identity_principal_id | Principal ID da Managed Identity |

## Boas Práticas

### 1. **Partition Keys**
- ✅ Alta cardinalidade (muitos valores únicos)
- ✅ Distribuição uniforme de dados
- ✅ Queries dentro da mesma partition
- ❌ Evitar hot partitions

### 2. **Consistência**
- ✅ Use Session para 90% dos casos
- ✅ Bounded Staleness para casos críticos
- ✅ Strong apenas quando necessário

### 3. **Throughput**
- ✅ Use Autoscale para tráfego variável
- ✅ Serverless para dev/test e workloads intermitentes
- ✅ Provisioned para workloads previsíveis
- ✅ Free tier para testes

### 4. **Indexing**
- ✅ Exclua paths não usados em queries
- ✅ Use composite indexes para ORDER BY
- ✅ Monitore RU consumption

### 5. **Segurança**
- ✅ Use Private Endpoint para produção
- ✅ Habilite Managed Identity
- ✅ Disable local auth quando possível
- ✅ Use RBAC do Azure

## Troubleshooting

### RU/s alto
- Revisar indexing policy (excluir paths desnecessários)
- Otimizar queries (usar partition key)
- Aumentar throughput ou migrar para autoscale

### Hot partitions
- Revisar escolha de partition key
- Adicionar sufixo randômico à partition key
- Considerar synthetic partition keys

### Latência alta
- Usar Session consistency em vez de Strong
- Habilitar multi-region reads
- Verificar se app está na mesma região

## Referências

- [Cosmos DB Documentation](https://learn.microsoft.com/azure/cosmos-db/)
- [Cosmos DB Pricing](https://azure.microsoft.com/pricing/details/cosmos-db/)
- [Partition Keys](https://learn.microsoft.com/azure/cosmos-db/partitioning-overview)
- [Consistency Levels](https://learn.microsoft.com/azure/cosmos-db/consistency-levels)
