# Resource Group
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização do cluster AKS"
  type        = string
}

# Cluster Configuration
variable "cluster_name" {
  description = "Nome do cluster AKS"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix para o cluster"
  type        = string
}

variable "dns_prefix_private_cluster" {
  description = "DNS prefix para private cluster"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = null
}

variable "automatic_upgrade_channel" {
  description = "Canal de upgrade automático: patch, rapid, node-image, stable, none"
  type        = string
  default     = null

  validation {
    condition     = var.automatic_upgrade_channel == null || contains(["patch", "rapid", "node-image", "stable", "none"], var.automatic_upgrade_channel)
    error_message = "automatic_upgrade_channel deve ser 'patch', 'rapid', 'node-image', 'stable' ou 'none'"
  }
}

variable "sku_tier" {
  description = "SKU Tier do cluster: Free, Standard, Premium"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier deve ser 'Free', 'Standard' ou 'Premium'"
  }
}

variable "private_cluster_enabled" {
  description = "Habilitar private cluster"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "ID da Private DNS Zone"
  type        = string
  default     = null
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Habilitar FQDN público em private cluster"
  type        = bool
  default     = false
}

variable "node_resource_group" {
  description = "Nome do resource group dos nodes"
  type        = string
  default     = null
}

variable "role_based_access_control_enabled" {
  description = "Habilitar RBAC"
  type        = bool
  default     = true
}

variable "local_account_disabled" {
  description = "Desabilitar contas locais (força apenas Azure AD)"
  type        = bool
  default     = false
}

variable "run_command_enabled" {
  description = "Habilitar comando run (kubectl via portal)"
  type        = bool
  default     = true
}

variable "azure_policy_enabled" {
  description = "Habilitar Azure Policy"
  type        = bool
  default     = false
}

variable "http_application_routing_enabled" {
  description = "Habilitar HTTP Application Routing (não recomendado para produção)"
  type        = bool
  default     = false
}

variable "oidc_issuer_enabled" {
  description = "Habilitar OIDC Issuer (para Workload Identity)"
  type        = bool
  default     = false
}

variable "workload_identity_enabled" {
  description = "Habilitar Workload Identity"
  type        = bool
  default     = false
}

variable "open_service_mesh_enabled" {
  description = "Habilitar Open Service Mesh"
  type        = bool
  default     = false
}

variable "image_cleaner_enabled" {
  description = "Habilitar limpeza automática de imagens"
  type        = bool
  default     = false
}

variable "image_cleaner_interval_hours" {
  description = "Intervalo de limpeza de imagens (horas)"
  type        = number
  default     = 168
}

# Default Node Pool
variable "default_node_pool_name" {
  description = "Nome do node pool padrão"
  type        = string
  default     = "default"
}

variable "default_node_pool_vm_size" {
  description = "Tamanho da VM do node pool padrão"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "default_node_pool_node_count" {
  description = "Número de nodes (usado quando auto_scaling está desabilitado)"
  type        = number
  default     = 3
}

variable "default_node_pool_enable_auto_scaling" {
  description = "Habilitar auto scaling"
  type        = bool
  default     = true
}

variable "default_node_pool_min_count" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
}

variable "default_node_pool_max_count" {
  description = "Número máximo de nodes"
  type        = number
  default     = 10
}

variable "default_node_pool_max_pods" {
  description = "Máximo de pods por node"
  type        = number
  default     = 30
}

variable "default_node_pool_os_disk_size_gb" {
  description = "Tamanho do disco do OS em GB"
  type        = number
  default     = 128
}

variable "default_node_pool_os_disk_type" {
  description = "Tipo de disco: Managed, Ephemeral"
  type        = string
  default     = "Managed"

  validation {
    condition     = contains(["Managed", "Ephemeral"], var.default_node_pool_os_disk_type)
    error_message = "os_disk_type deve ser 'Managed' ou 'Ephemeral'"
  }
}

variable "default_node_pool_vnet_subnet_id" {
  description = "ID da subnet para os nodes"
  type        = string
  default     = null
}

variable "default_node_pool_pod_subnet_id" {
  description = "ID da subnet para os pods (Azure CNI Overlay)"
  type        = string
  default     = null
}

variable "default_node_pool_enable_host_encryption" {
  description = "Habilitar criptografia em host"
  type        = bool
  default     = false
}

variable "default_node_pool_enable_node_public_ip" {
  description = "Habilitar IP público nos nodes"
  type        = bool
  default     = false
}

variable "default_node_pool_availability_zones" {
  description = "Availability zones para os nodes"
  type        = list(string)
  default     = null
}

variable "default_node_pool_only_critical_addons" {
  description = "Apenas addons críticos no node pool padrão"
  type        = bool
  default     = false
}

variable "default_node_pool_orchestrator_version" {
  description = "Versão do Kubernetes para o node pool"
  type        = string
  default     = null
}

variable "default_node_pool_os_sku" {
  description = "SKU do OS: Ubuntu, AzureLinux, Windows2019, Windows2022"
  type        = string
  default     = null
}

variable "default_node_pool_tags" {
  description = "Tags específicas do node pool padrão"
  type        = map(string)
  default     = {}
}

variable "default_node_pool_kubelet_config" {
  description = "Configuração do Kubelet"
  type        = any
  default     = null
}

variable "default_node_pool_linux_os_config" {
  description = "Configuração do OS Linux"
  type        = any
  default     = null
}

variable "default_node_pool_upgrade_settings" {
  description = "Configurações de upgrade"
  type = object({
    max_surge = string
  })
  default = null
}

# Network Profile
variable "network_plugin" {
  description = "Plugin de rede: azure, kubenet, none"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "network_plugin deve ser 'azure', 'kubenet' ou 'none'"
  }
}

variable "network_mode" {
  description = "Modo de rede: transparent, bridge"
  type        = string
  default     = null
}

variable "network_policy" {
  description = "Network policy: azure, calico"
  type        = string
  default     = null

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico"], var.network_policy)
    error_message = "network_policy deve ser 'azure' ou 'calico'"
  }
}

variable "dns_service_ip" {
  description = "IP do serviço DNS do cluster"
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "CIDR para serviços do Kubernetes"
  type        = string
  default     = null
}

variable "pod_cidr" {
  description = "CIDR para pods (apenas com kubenet)"
  type        = string
  default     = null
}

variable "outbound_type" {
  description = "Tipo de saída: loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway"
  type        = string
  default     = "loadBalancer"
}

variable "load_balancer_sku" {
  description = "SKU do Load Balancer: basic, standard"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["basic", "standard"], var.load_balancer_sku)
    error_message = "load_balancer_sku deve ser 'basic' ou 'standard'"
  }
}

variable "network_plugin_mode" {
  description = "Modo do plugin: overlay (Azure CNI Overlay)"
  type        = string
  default     = null
}

variable "load_balancer_profile" {
  description = "Configuração do Load Balancer"
  type        = any
  default     = null
}

# Identity
variable "identity_type" {
  description = "Tipo de identidade: SystemAssigned, UserAssigned"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "identity_type deve ser 'SystemAssigned' ou 'UserAssigned'"
  }
}

variable "identity_ids" {
  description = "IDs das User Assigned Identities"
  type        = list(string)
  default     = null
}

# Azure AD (Entra ID) RBAC
variable "azure_ad_rbac_enabled" {
  description = "Habilitar integração com Azure AD"
  type        = bool
  default     = false
}

variable "azure_ad_rbac_managed" {
  description = "Azure AD gerenciado pelo AKS"
  type        = bool
  default     = true
}

variable "azure_ad_rbac_tenant_id" {
  description = "Tenant ID do Azure AD"
  type        = string
  default     = null
}

variable "azure_ad_rbac_admin_group_object_ids" {
  description = "Object IDs dos grupos admin do Azure AD"
  type        = list(string)
  default     = null
}

variable "azure_ad_rbac_azure_rbac_enabled" {
  description = "Habilitar Azure RBAC para autorização do Kubernetes"
  type        = bool
  default     = false
}

variable "azure_ad_rbac_client_app_id" {
  description = "Client App ID (para Azure AD não gerenciado)"
  type        = string
  default     = null
}

variable "azure_ad_rbac_server_app_id" {
  description = "Server App ID (para Azure AD não gerenciado)"
  type        = string
  default     = null
}

variable "azure_ad_rbac_server_app_secret" {
  description = "Server App Secret (para Azure AD não gerenciado)"
  type        = string
  default     = null
  sensitive   = true
}

# API Server Access Profile
variable "api_server_authorized_ip_ranges" {
  description = "IPs autorizados a acessar o API server"
  type        = list(string)
  default     = null
}

variable "api_server_vnet_integration_enabled" {
  description = "Habilitar VNet integration do API server"
  type        = bool
  default     = false
}

variable "api_server_subnet_id" {
  description = "Subnet ID para o API server"
  type        = string
  default     = null
}

# Auto Scaler Profile
variable "auto_scaler_profile" {
  description = "Configurações do cluster autoscaler"
  type        = any
  default     = null
}

# Key Vault Secrets Provider
variable "key_vault_secrets_provider_enabled" {
  description = "Habilitar Key Vault Secrets Provider"
  type        = bool
  default     = false
}

variable "secret_rotation_enabled" {
  description = "Habilitar rotação automática de secrets"
  type        = bool
  default     = true
}

variable "secret_rotation_interval" {
  description = "Intervalo de rotação de secrets"
  type        = string
  default     = "2m"
}

# Microsoft Defender
variable "microsoft_defender_enabled" {
  description = "Habilitar Microsoft Defender para Containers"
  type        = bool
  default     = false
}

variable "microsoft_defender_log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID para o Defender"
  type        = string
  default     = null
}

# OMS Agent (Azure Monitor)
variable "oms_agent_enabled" {
  description = "Habilitar OMS Agent (Azure Monitor)"
  type        = bool
  default     = false
}

variable "oms_agent_log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID para o OMS Agent"
  type        = string
  default     = null
}

variable "oms_agent_msi_auth_enabled" {
  description = "Usar Managed Identity para autenticação do OMS Agent"
  type        = bool
  default     = true
}

# Ingress Application Gateway
variable "ingress_application_gateway_enabled" {
  description = "Habilitar Application Gateway Ingress Controller"
  type        = bool
  default     = false
}

variable "ingress_application_gateway_id" {
  description = "ID do Application Gateway existente"
  type        = string
  default     = null
}

variable "ingress_application_gateway_name" {
  description = "Nome do Application Gateway a criar"
  type        = string
  default     = null
}

variable "ingress_application_gateway_subnet_cidr" {
  description = "CIDR da subnet do Application Gateway"
  type        = string
  default     = null
}

variable "ingress_application_gateway_subnet_id" {
  description = "ID da subnet do Application Gateway"
  type        = string
  default     = null
}

# Kubelet Identity
variable "kubelet_identity" {
  description = "Identidade customizada para o Kubelet"
  type        = any
  default     = null
}

# Linux Profile
variable "linux_profile" {
  description = "Perfil Linux para SSH"
  type = object({
    admin_username = string
    ssh_key        = string
  })
  default = null
}

# Windows Profile
variable "windows_profile" {
  description = "Perfil Windows para nodes Windows"
  type        = any
  default     = null
  sensitive   = true
}

# Maintenance Window
variable "maintenance_window" {
  description = "Janela de manutenção do cluster"
  type        = any
  default     = null
}

variable "maintenance_window_auto_upgrade" {
  description = "Janela de manutenção para auto upgrade"
  type        = any
  default     = null
}

# Storage Profile
variable "storage_profile" {
  description = "Configuração de storage drivers"
  type        = any
  default     = null
}

# Additional Node Pools
variable "additional_node_pools" {
  description = "Node pools adicionais"
  type = map(object({
    vm_size             = string
    node_count          = optional(number)
    enable_auto_scaling = optional(bool)
    min_count           = optional(number)
    max_count           = optional(number)
    max_pods            = optional(number)
    os_disk_size_gb     = optional(number)
    os_disk_type        = optional(string)
    os_type             = optional(string)
    os_sku              = optional(string)
    vnet_subnet_id      = optional(string)
    pod_subnet_id       = optional(string)
    enable_host_encryption = optional(bool)
    enable_node_public_ip  = optional(bool)
    availability_zones     = optional(list(string))
    orchestrator_version   = optional(string)
    mode                   = optional(string)
    priority               = optional(string)
    spot_max_price         = optional(number)
    eviction_policy        = optional(string)
    node_labels            = optional(map(string))
    node_taints            = optional(list(string))
    kubelet_config         = optional(any)
    linux_os_config        = optional(any)
    upgrade_settings       = optional(any)
    tags                   = optional(map(string))
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}