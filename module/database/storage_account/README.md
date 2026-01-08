# Módulo Terraform - Azure Storage Account

Este módulo Terraform cria e gerencia uma Azure Storage Account com todas as suas funcionalidades e recursos associados (containers, file shares, queues e tables).

## Recursos Criados

- **Azure Storage Account** - Conta de armazenamento principal
- **Blob Containers** - Containers para armazenamento de blobs (opcional)
- **File Shares** - Compartilhamentos de arquivos (opcional)
- **Storage Queues** - Filas de mensagens (opcional)
- **Storage Tables** - Armazenamento NoSQL (opcional)

## Características

✅ Suporte completo a todos os tipos de Storage Account (StorageV2, BlobStorage, BlockBlobStorage, FileStorage)  
✅ Configuração de replicação (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)  
✅ Network rules e private endpoints  
✅ Blob properties (versionamento, soft delete, change feed)  
✅ Managed Identity (SystemAssigned e UserAssigned)  
✅ Data Lake Storage Gen2 (Hierarchical Namespace)  
✅ NFSv3 support  
✅ Segurança (HTTPS only, TLS version, OAuth)  
✅ Tags personalizadas  

## Uso Básico

```hcl
module "storage_account" {
  source = "./modules/storage_account"

  name                = "mystorageaccount001"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Containers e File Shares

```hcl
module "storage_account" {
  source = "./modules/storage_account"

  name                = "mystorageaccount001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Habilitar features de segurança
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  shared_access_key_enabled = true

  # Containers
  containers = [
    {
      name                  = "documents"
      container_access_type = "private"
    },
    {
      name                  = "public-files"
      container_access_type = "blob"
    }
  ]

  # File Shares
  file_shares = [
    {
      name  = "appdata"
      quota = 100
    },
    {
      name  = "backups"
      quota = 500
    }
  ]

  # Queues
  queues = ["processing-queue", "notifications-queue"]

  # Tables
  tables = ["users", "logs"]

  tags = {
    Environment = "Production"
    Project     = "MyApp"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo com Data Lake Gen2 e Network Rules

```hcl
module "datalake_storage" {
  source = "./modules/storage_account"

  name                = "mydatalake001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Habilitar Data Lake Gen2
  is_hns_enabled = true

  # Network Rules
  public_network_access_enabled = false
  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [
      azurerm_subnet.private.id
    ]
  }

  # Blob Properties
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    last_access_time_enabled        = true
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }

  # Managed Identity
  identity_type = "SystemAssigned"

  tags = {
    Environment = "Production"
    DataClass   = "Confidential"
  }
}
```

## Exemplo com Premium Storage

```hcl
module "premium_storage" {
  source = "./modules/storage_account"

  name                = "premiumstorage001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "BlockBlobStorage"

  # Premium storage não suporta access_tier
  # access_tier não é especificado

  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  containers = [
    {
      name                  = "high-performance"
      container_access_type = "private"
    }
  ]

  tags = {
    Environment = "Production"
    Performance = "Premium"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|---------|-------------|
| `name` | Nome da Storage Account (3-24 caracteres, apenas letras minúsculas e números) | `string` | - | Sim |
| `resource_group_name` | Nome do Resource Group | `string` | - | Sim |
| `location` | Localização do Azure | `string` | - | Sim |
| `account_tier` | Tier da conta (Standard ou Premium) | `string` | `"Standard"` | Não |
| `account_replication_type` | Tipo de replicação (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS) | `string` | `"LRS"` | Não |
| `account_kind` | Tipo da conta (StorageV2, BlobStorage, etc) | `string` | `"StorageV2"` | Não |
| `access_tier` | Access tier (Hot ou Cool) | `string` | `"Hot"` | Não |
| `enable_https_traffic_only` | Habilitar apenas tráfego HTTPS | `bool` | `true` | Não |
| `min_tls_version` | Versão mínima do TLS | `string` | `"TLS1_2"` | Não |
| `is_hns_enabled` | Habilitar Hierarchical Namespace (Data Lake Gen2) | `bool` | `false` | Não |
| `containers` | Lista de containers a criar | `list(object)` | `[]` | Não |
| `file_shares` | Lista de file shares a criar | `list(object)` | `[]` | Não |
| `queues` | Lista de queues a criar | `list(string)` | `[]` | Não |
| `tables` | Lista de tables a criar | `list(string)` | `[]` | Não |
| `network_rules` | Regras de rede | `object` | Ver variables.tf | Não |
| `blob_properties` | Propriedades de blob | `object` | Ver variables.tf | Não |
| `identity_type` | Tipo de identidade gerenciada | `string` | `null` | Não |
| `tags` | Tags para os recursos | `map(string)` | `{}` | Não |

Para ver todos os inputs disponíveis, consulte o arquivo `variables.tf`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `id` | ID da Storage Account |
| `name` | Nome da Storage Account |
| `primary_blob_endpoint` | Endpoint primário para Blob Storage |
| `primary_queue_endpoint` | Endpoint primário para Queue Storage |
| `primary_table_endpoint` | Endpoint primário para Table Storage |
| `primary_file_endpoint` | Endpoint primário para File Storage |
| `primary_access_key` | Chave de acesso primária (sensível) |
| `primary_connection_string` | Connection string primária (sensível) |
| `identity` | Informações da identidade gerenciada |
| `containers` | Informações dos containers criados |
| `file_shares` | Informações dos file shares criados |

Para ver todos os outputs disponíveis, consulte o arquivo `outputs.tf`.

## Notas Importantes

### Nomenclatura da Storage Account

- O nome deve ser **globalmente único** no Azure
- Apenas letras minúsculas e números
- Entre 3 e 24 caracteres
- Não pode conter hífens, underscores ou caracteres especiais

### Tipos de Replicação

- **LRS** (Locally Redundant Storage) - 3 cópias na mesma região
- **ZRS** (Zone Redundant Storage) - 3 cópias em zonas diferentes
- **GRS** (Geo-Redundant Storage) - 6 cópias (3 local + 3 região secundária)
- **RAGRS** (Read-Access GRS) - GRS com leitura na região secundária
- **GZRS** (Geo-Zone Redundant Storage) - ZRS + GRS
- **RAGZRS** (Read-Access GZRS) - GZRS com leitura na região secundária

### Tiers e Performance

- **Standard Tier**: HDD, custo-benefício para armazenamento em geral
- **Premium Tier**: SSD, alto desempenho, baixa latência

### Container Access Types

- **private**: Sem acesso público
- **blob**: Acesso público apenas aos blobs
- **container**: Acesso público ao container e blobs

## Segurança

Este módulo implementa as seguintes práticas de segurança por padrão:

- ✅ HTTPS obrigatório
- ✅ TLS 1.2 como mínimo
- ✅ Acesso público a itens aninhados desabilitado
- ✅ Soft delete habilitado para blobs e containers
- ✅ Suporte a Managed Identity
- ✅ Suporte a Private Endpoints via network rules

## Requisitos

- Terraform >= 1.0
- Provider AzureRM ~> 3.0
- Subscription do Azure com permissões adequadas