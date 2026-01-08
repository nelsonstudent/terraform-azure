# Azure Kubernetes Service (AKS) Terraform Module

Módulo Terraform para provisionar e gerenciar Azure Kubernetes Service (AKS). Suporta múltiplos node pools, auto-scaling, Azure AD integration, private clusters, network policies e todas as features avançadas do AKS.

## Funcionalidades

- ✅ Cluster Kubernetes gerenciado
- ✅ Múltiplos node pools com auto-scaling
- ✅ Azure CNI e Kubenet networking
- ✅ Private clusters com Private Link
- ✅ Azure AD (Entra ID) integration e RBAC
- ✅ Workload Identity e OIDC
- ✅ Azure Policy e Defender
- ✅ Application Gateway Ingress Controller (AGIC)
- ✅ Key Vault Secrets Provider (CSI Driver)
- ✅ Azure Monitor e Container Insights
- ✅ Spot instances para economia
- ✅ Windows e Linux node pools
- ✅ Availability zones

## Pré-requisitos

- Terraform >= 1.0
- Provider `hashicorp/azurerm` >= 3.0
- Resource Group existente
- VNet e subnets (para Azure CNI)
- Azure CLI instalado (para kubectl)

## SKU Tiers

### Free Tier
- **Custo**: Gratuito
- **SLA**: Sem SLA de uptime
- **API Server**: Compartilhado
- **Uso**: Dev/Test

### Standard Tier (Recomendado)
- **Custo**: ~$0.10/hora (~$73/mês)
- **SLA**: 99.95% (single zone), 99.99% (multi-zone)
- **API Server**: Melhor performance
- **Features**: Uptime SLA, maior escala
- **Uso**: Produção

### Premium Tier
- **Custo**: ~$0.60/hora (~$438/mês)
- **SLA**: 99.95% (single zone), 99.99% (multi-zone)
- **Features**: Maior escala, melhor isolamento
- **Uso**: Cargas críticas enterprise

## Tamanhos de VM Comuns

### General Purpose
- **Standard_D2s_v3**: 2 vCPU, 8 GB RAM (~$96/mês)
- **Standard_D4s_v3**: 4 vCPU, 16 GB RAM (~$193/mês)
- **Standard_D8s_v3**: 8 vCPU, 32 GB RAM (~$385/mês)

### Compute Optimized
- **Standard_F4s_v2**: 4 vCPU, 8 GB RAM (~$145/mês)
- **Standard_F8s_v2**: 8 vCPU, 16 GB RAM (~$291/mês)

### Memory Optimized
- **Standard_E4s_v3**: 4 vCPU, 32 GB RAM (~$243/mês)
- **Standard_E8s_v3**: 8 vCPU, 64 GB RAM (~$486/mês)

## Uso Básico

### Cluster AKS Simples

```hcl
module "aks" {
  source = "../../modules/compute/aks"

  resource_group_name = "rg-aks-prod"
  location            = "Brazil South"
  
  cluster_name = "aks-prod"
  dns_prefix   = "aks-prod"
  
  kubernetes_version = "1.29"
  sku_tier           = "Standard"
  
  # Default Node Pool
  default_node_pool_name              = "system"
  default_node_pool_vm_size           = "Standard_D2s_v3"
  default_node_pool_enable_auto_scaling = true
  default_node_pool_min_count         = 2
  default_node_pool_max_count         = 5
  default_node_pool_availability_zones = ["1", "2", "3"]
  
  # Network
  network_plugin = "azure"
  network_policy = "azure"
  
  tags = {
    Environment = "production"
  }
}
```

### Cluster com Azure CNI e VNet Integration

```hcl
module "aks" {
  source = "../../modules/compute/aks"

  resource_group_name = "rg-aks-prod"
  location            = "East US"
  
  cluster_name = "aks-prod-eastus"
  dns_prefix   = "aks-prod"
  
  kubernetes_version = "1.29"
  sku_tier           = "Standard"
  
  # Default Node Pool
  default_node_pool_name              = "system"
  default_node_pool_vm_size           = "Standard_D4s_v3"
  default_node_pool_vnet_subnet_id    = azurerm_subnet.aks_nodes.id
  default_node_pool_enable_auto_scaling = true
  default_node_pool_min_count         = 3
  default_node_pool_max_count         = 10
  default_node_pool_max_pods          = 50
  default_node_pool_availability_zones = ["1", "2", "3"]
  
  # Network Profile
  network_plugin = "azure"
  network_policy = "azure"
  service_cidr   = "10.0.0.0/16"
  dns_service_ip = "10.0.0.10"
  
  # Identity
  identity_type = "SystemAssigned"
  
  tags = {
    Environment = "production"
  }
}
```

### Private Cluster

```hcl
module "aks" {
  source = "../../modules/compute/aks"

  resource_group_name = "rg-aks-prod"
  location            = "Brazil South"
  
  cluster_name = "aks-private-prod"
  dns_prefix   = "aks-private"
  
  # Private Cluster
  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.aks.id
  
  # API Server Access
  api_server_authorized_ip_ranges = [
    "203.0.113.0/24"  # Office network
  ]
  
  # Default Node Pool
  default_node_pool_name           = "system"
  default_node_pool_vm_size        = "Standard_D2s_v3"
  default_node_pool_vnet_subnet_id = azurerm_subnet.aks_nodes.id
  default_node_pool_min_count      = 2
  default_node_pool_max_count      = 5
  default_node_pool_enable_auto_scaling = true
  
  network_plugin = "azure"
  
  tags = {
    Environment = "production"
  }
}
```

## Exemplo Completo (Production-Ready)

```hcl
module "aks" {
  source = "../../modules/compute/aks"

  # Resource Group
  resource_group_name = "rg-aks-prod"
  location            = "Brazil South"
  
  # Cluster Configuration
  cluster_name              = "aks-prod-brazilsouth"
  dns_prefix                = "aks-prod"
  kubernetes_version        = "1.29"
  automatic_channel_upgrade = "stable"
  sku_tier                  = "Standard"
  node_resource_group       = "rg-aks-prod-nodes"
  
  # Security
  role_based_access_control_enabled = true
  local_account_disabled            = true  # Force Azure AD only
  azure_policy_enabled              = true
  
  # OIDC & Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  
  # Default Node Pool (System)
  default_node_pool_name                = "system"
  default_node_pool_vm_size             = "Standard_D4s_v3"
  default_node_pool_vnet_subnet_id      = azurerm_subnet.aks_nodes.id
  default_node_pool_enable_auto_scaling = true
  default_node_pool_min_count           = 3
  default_node_pool_max_count           = 6
  default_node_pool_max_pods            = 50
  default_node_pool_os_disk_size_gb     = 128
  default_node_pool_os_disk_type        = "Ephemeral"
  default_node_pool_availability_zones  = ["1", "2", "3"]
  default_node_pool_only_critical_addons = true
  
  default_node_pool_upgrade_settings = {
    max_surge = "33%"
  }
  
  # Network Profile
  network_plugin = "azure"
  network_policy = "azure"
  service_cidr   = "10.0.0.0/16"
  dns_service_ip = "10.0.0.10"
  outbound_type  = "loadBalancer"
  
  load_balancer_profile = {
    managed_outbound_ip_count = 2
    idle_timeout_in_minutes   = 30
  }
  
  # Azure AD Integration
  azure_ad_rbac_enabled              = true
  azure_ad_rbac_managed              = true
  azure_ad_rbac_admin_group_object_ids = [
    "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"  # Admin group
  ]
  azure_ad_rbac_azure_rbac_enabled = true
  
  # API Server Access
  api_server_authorized_ip_ranges = [
    "203.0.113.0/24",  # Office
    "198.51.100.0/24"  # VPN
  ]
  
  # Auto Scaler Profile
  auto_scaler_profile = {
    balance_similar_node_groups      = true
    expander                         = "least-waste"
    max_graceful_termination_sec     = 600
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = 0.5
    skip_nodes_with_system_pods      = true
  }
  
  # Key Vault Secrets Provider
  key_vault_secrets_provider_enabled = true
  secret_rotation_enabled            = true
  secret_rotation_interval           = "2m"
  
  # Azure Monitor
  oms_agent_enabled                  = true
  oms_agent_log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  oms_agent_msi_auth_enabled         = true
  
  # Microsoft Defender
  microsoft_defender_enabled                 = true
  microsoft_defender_log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  # Linux SSH Profile
  linux_profile = {
    admin_username = "azureuser"
    ssh_key        = file("~/.ssh/id_rsa.pub")
  }
  
  # Maintenance Window
  maintenance_window_auto_upgrade = {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "-03:00"
  }
  
  # Storage Profile
  storage_profile = {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }
  
  # Additional Node Pools
  additional_node_pools = {
    # User workload pool
    "user" = {
      vm_size             = "Standard_D8s_v3"
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 20
      max_pods            = 50
      os_disk_size_gb     = 128
      os_disk_type        = "Ephemeral"
      availability_zones  = ["1", "2", "3"]
      mode                = "User"
      node_labels = {
        "workload" = "general"
      }
      upgrade_settings = {
        max_surge = "33%"
      }
    }
    
    # Memory intensive pool
    "memory" = {
      vm_size             = "Standard_E8s_v3"
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 10
      availability_zones  = ["1", "2", "3"]
      mode                = "User"
      node_labels = {
        "workload" = "memory-intensive"
      }
      node_taints = [
        "workload=memory-intensive:NoSchedule"
      ]
    }
    
    # Spot instances pool (economia)
    "spot" = {
      vm_size             = "Standard_D4s_v3"
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 10
      mode                = "User"
      priority            = "Spot"
      eviction_policy     = "Delete"
      spot_max_price      = -1  # Pay up to on-demand price
      node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
      }
      node_taints = [
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]
    }
  }
  
  # Identity
  identity_type = "SystemAssigned"
  
  tags = {
    Environment = "production"
    Project     = "platform"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Role Assignments
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.cluster_identity_principal_id
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}
```

## Azure CNI vs Kubenet

### Azure CNI (Recomendado)
```hcl
network_plugin = "azure"

default_node_pool_vnet_subnet_id = azurerm_subnet.aks_nodes.id
service_cidr   = "10.0.0.0/16"
dns_service_ip = "10.0.0.10"
```

**Vantagens:**
- Pods recebem IPs da VNet diretamente
- Comunicação nativa com recursos Azure
- Melhor performance
- Suporte a Network Policies (Azure ou Calico)

**Desvantagens:**
- Consome mais IPs da VNet
- Planejamento de IP necessário

### Azure CNI Overlay (Novo)
```hcl
network_plugin      = "azure"
network_plugin_mode = "overlay"
pod_cidr            = "10.244.0.0/16"
```

**Vantagens:**
- Pods em subnet separada (overlay)
- Economiza IPs da VNet
- Até 250 nodes por cluster

### Kubenet
```hcl
network_plugin = "kubenet"
pod_cidr       = "10.244.0.0/16"
```

**Vantagens:**
- Simples e econômico em IPs
- Pods em rede overlay

**Desvantagens:**
- Comunicação com Azure resources requer UDR
- Sem suporte a Windows nodes
- Sem suporte a Virtual Nodes

## Azure AD (Entra ID) Integration

### Azure AD Managed (Recomendado)
```hcl
azure_ad_rbac_enabled = true
azure_ad_rbac_managed = true

azure_ad_rbac_admin_group_object_ids = [
  "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
]

azure_ad_rbac_azure_rbac_enabled = true
```

**Conectar ao cluster:**
```bash
az aks get-credentials --resource-group rg-aks-prod --name aks-prod

# Login com Azure AD
kubectl get nodes
```

### RBAC com Azure Roles
```bash
# Cluster Admin
az role assignment create \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --assignee user@example.com \
  --scope /subscriptions/{subscription-id}/resourceGroups/rg-aks-prod/providers/Microsoft.ContainerService/managedClusters/aks-prod

# Namespace Admin
az role assignment create \
  --role "Azure Kubernetes Service RBAC Writer" \
  --assignee user@example.com \
  --scope /subscriptions/{subscription-id}/resourceGroups/rg-aks-prod/providers/Microsoft.ContainerService/managedClusters/aks-prod/namespaces/production
```

## Workload Identity

```hcl
oidc_issuer_enabled       = true
workload_identity_enabled = true
```

**Criar identidade para aplicação:**
```bash
# User Assigned Identity
az identity create \
  --name id-app-storage \
  --resource-group rg-aks-prod

# Get identity info
IDENTITY_CLIENT_ID=$(az identity show --name id-app-storage --resource-group rg-aks-prod --query clientId -o tsv)

# Create federated credential
az identity federated-credential create \
  --name app-storage-credential \
  --identity-name id-app-storage \
  --resource-group rg-aks-prod \
  --issuer ${module.aks.oidc_issuer_url} \
  --subject system:serviceaccount:default:app-sa
```

**Kubernetes ServiceAccount:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: ${IDENTITY_CLIENT_ID}
---
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: default
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: myapp:latest
```

## Key Vault Secrets Provider

```hcl
key_vault_secrets_provider_enabled = true
secret_rotation_enabled            = true
secret_rotation_interval           = "2m"
```

**Dar permissões:**
```bash
az keyvault set-policy \
  --name kv-prod \
  --object-id ${module.aks.key_vault_secrets_provider.secret_identity_object_id} \
  --secret-permissions get list
```

**SecretProviderClass:**
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kv-sync
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: ${module.aks.key_vault_secrets_provider.secret_identity_client_id}
    keyvaultName: kv-prod
    cloudName: ""
    objects: |
      array:
        - |
          objectName: database-password
          objectType: secret
        - |
          objectName: api-key
          objectType: secret
    tenantId: ${data.azurerm_client_config.current.tenant_id}
```

**Pod usando secrets:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: secrets-store
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-kv-sync
```

## Application Gateway Ingress Controller (AGIC)

```hcl
ingress_application_gateway_enabled = true
ingress_application_gateway_subnet_id = azurerm_subnet.appgw.id
ingress_application_gateway_name    = "appgw-aks"
```

**Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
```

## Node Pools

### System Node Pool
- Hospeda componentes críticos do sistema (CoreDNS, metrics-server)
- Deve ter `mode = "System"`
- Recomendado: mínimo 2 nodes, máximo 3-5

### User Node Pools
- Hospeda workloads de aplicação
- `mode = "User"`
- Pode ser scaled to zero
- Pode usar Spot instances

### Spot Instances
```hcl
additional_node_pools = {
  "spot" = {
    vm_size             = "Standard_D4s_v3"
    enable_auto_scaling = true
    min_count           = 0
    max_count           = 10
    priority            = "Spot"
    eviction_policy     = "Delete"
    spot_max_price      = -1
    node_taints = [
      "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
    ]
  }
}
```

**Pod tolerating spot:**
```yaml
spec:
  tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
```

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| resource_group_name | Nome do Resource Group | `string` | - | Sim |
| location | Localização Azure | `string` | - | Sim |
| cluster_name | Nome do cluster AKS | `string` | - | Sim |
| dns_prefix | DNS prefix | `string` | - | Sim |
| kubernetes_version | Versão do Kubernetes | `string` | `null` | Não |
| sku_tier | SKU: Free, Standard, Premium | `string` | `"Free"` | Não |
| default_node_pool_vm_size | Tamanho da VM | `string` | `"Standard_D2s_v3"` | Não |
| network_plugin | Plugin: azure, kubenet | `string` | `"azure"` | Não |
| identity_type | SystemAssigned ou UserAssigned | `string` | `"SystemAssigned"` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| cluster_id | ID do cluster |
| cluster_name | Nome do cluster |
| kube_config_raw | Kubeconfig raw |
| cluster_identity_principal_id | Principal ID da identidade |
| oidc_issuer_url | URL do OIDC Issuer |

## Boas Práticas

### 1. **Segurança**
- ✅ Use `sku_tier = "Standard"` para produção
- ✅ Habilite Azure AD integration
- ✅ Use `local_account_disabled = true`
- ✅ Configure `api_server_authorized_ip_ranges`
- ✅ Habilite Azure Policy
- ✅ Use Workload Identity em vez de Service Principal
- ✅ Habilite Microsoft Defender

### 2. **Networking**
- ✅ Use Azure CNI para melhor integração
- ✅ Planeje CIDRs adequadamente
- ✅ Use Network Policies (Azure ou Calico)
- ✅ Private clusters para workloads sensíveis

### 3. **Alta Disponibilidade**
- ✅ Use `availability_zones = ["1", "2", "3"]`
- ✅ Múltiplos nodes no system pool (min 3)
- ✅ Configure PodDisruptionBudgets
- ✅ Use `automatic_channel_upgrade = "stable"`

### 4. **Performance**
- ✅ Use Ephemeral OS disks
- ✅ Configure `max_pods` apropriadamente
- ✅ Tune auto scaler profile
- ✅ Use node pools específicos para workloads

### 5. **Custo**
- ✅ Use Spot instances para workloads tolerantes
- ✅ Configure auto-scaling com limites
- ✅ Use Free tier para dev/test
- ✅ Monitore com Azure Cost Management

## Troubleshooting

### Nodes não estão prontos
```bash
kubectl get nodes
kubectl describe node <node-name>
```

### Pods não conseguem pull de imagem do ACR
```bash
# Verificar role assignment
az role assignment list --assignee ${module.aks.kubelet_identity_object_id} --scope ${azurerm_container_registry.main.id}
```

### Workload Identity não funciona
```bash
# Verificar OIDC issuer
echo ${module.aks.oidc_issuer_url}

# Verificar federated credential
az identity federated-credential list --identity-name id-app --resource-group rg-aks-prod
```

### Key Vault Secrets Provider erro
```bash
# Verificar logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver

# Verificar permissões
az keyvault show --name kv-prod --query properties.accessPolicies
```

## Referências

- [AKS Documentation](https://learn.microsoft.com/azure/aks/)
- [AKS Best Practices](https://learn.microsoft.com/azure/aks/best-practices)
- [Azure CNI Overlay](https://learn.microsoft.com/azure/aks/azure-cni-overlay)
- [Workload Identity](https://learn.microsoft.com/azure/aks/workload-identity-overview)
- [AKS Pricing](https://azure.microsoft.com/pricing/details/kubernetes-service/)