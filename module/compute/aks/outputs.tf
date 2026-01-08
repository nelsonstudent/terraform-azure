# Cluster Outputs
output "cluster_id" {
  description = "ID do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Nome do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "FQDN privado do cluster"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "cluster_portal_fqdn" {
  description = "FQDN do portal do cluster"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "kube_config_raw" {
  description = "Kubeconfig raw do cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Objeto kubeconfig estruturado"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Kubeconfig admin raw (quando Azure AD está habilitado)"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Objeto kubeconfig admin estruturado"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config
  sensitive   = true
}

output "client_certificate" {
  description = "Certificado de cliente base64"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Chave do cliente base64"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificado CA do cluster base64"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "host" {
  description = "Endpoint do API server"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "username" {
  description = "Username para autenticação"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].username
  sensitive   = true
}

output "password" {
  description = "Password para autenticação"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].password
  sensitive   = true
}

# Identity Outputs
output "cluster_identity_principal_id" {
  description = "Principal ID da identidade do cluster"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "cluster_identity_tenant_id" {
  description = "Tenant ID da identidade do cluster"
  value       = azurerm_kubernetes_cluster.main.identity[0].tenant_id
}

output "kubelet_identity_object_id" {
  description = "Object ID da identidade do Kubelet"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "Client ID da identidade do Kubelet"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
}

output "kubelet_identity_user_assigned_identity_id" {
  description = "ID da User Assigned Identity do Kubelet"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].user_assigned_identity_id
}

# Network Outputs
output "node_resource_group" {
  description = "Nome do resource group dos nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "network_profile" {
  description = "Perfil de rede do cluster"
  value = {
    network_plugin      = azurerm_kubernetes_cluster.main.network_profile[0].network_plugin
    network_policy      = azurerm_kubernetes_cluster.main.network_profile[0].network_policy
    dns_service_ip      = azurerm_kubernetes_cluster.main.network_profile[0].dns_service_ip
    service_cidr        = azurerm_kubernetes_cluster.main.network_profile[0].service_cidr
    pod_cidr            = azurerm_kubernetes_cluster.main.network_profile[0].pod_cidr
    load_balancer_sku   = azurerm_kubernetes_cluster.main.network_profile[0].load_balancer_sku
  }
}

# OIDC Issuer
output "oidc_issuer_url" {
  description = "URL do OIDC Issuer"
  value       = var.oidc_issuer_enabled ? azurerm_kubernetes_cluster.main.oidc_issuer_url : null
}

# Key Vault Secrets Provider
output "key_vault_secrets_provider" {
  description = "Configuração do Key Vault Secrets Provider"
  value = var.key_vault_secrets_provider_enabled ? {
    secret_identity_client_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
    secret_identity_object_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  } : null
}

# Ingress Application Gateway
output "ingress_application_gateway" {
  description = "Configuração do Application Gateway Ingress"
  value = var.ingress_application_gateway_enabled ? {
    gateway_id                    = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].gateway_id
    effective_gateway_id          = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].effective_gateway_id
    ingress_application_gateway_identity_client_id = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].ingress_application_gateway_identity[0].client_id
    ingress_application_gateway_identity_object_id = azurerm_kubernetes_cluster.main.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  } : null
}

# OMS Agent
output "oms_agent_identity" {
  description = "Identidade do OMS Agent"
  value = var.oms_agent_enabled ? {
    client_id = azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].object_id
  } : null
}

# Additional Node Pools
output "additional_node_pool_ids" {
  description = "IDs dos node pools adicionais"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => v.id }
}

output "additional_node_pool_names" {
  description = "Nomes dos node pools adicionais"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => v.name }
}

# Complete Cluster Info
output "cluster_info" {
  description = "Informações completas do cluster"
  value = {
    id                       = azurerm_kubernetes_cluster.main.id
    name                     = azurerm_kubernetes_cluster.main.name
    location                 = azurerm_kubernetes_cluster.main.location
    resource_group           = azurerm_kubernetes_cluster.main.resource_group_name
    kubernetes_version       = azurerm_kubernetes_cluster.main.kubernetes_version
    fqdn                     = azurerm_kubernetes_cluster.main.fqdn
    private_cluster          = var.private_cluster_enabled
    sku_tier                 = var.sku_tier
    node_resource_group      = azurerm_kubernetes_cluster.main.node_resource_group
    network_plugin           = azurerm_kubernetes_cluster.main.network_profile[0].network_plugin
    rbac_enabled             = var.role_based_access_control_enabled
    azure_ad_enabled         = var.azure_ad_rbac_enabled
    oidc_issuer_enabled      = var.oidc_issuer_enabled
    workload_identity_enabled = var.workload_identity_enabled
  }
}

# Connection Info (para kubectl)
output "kubectl_config_command" {
  description = "Comando para configurar kubectl"
  value       = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.cluster_name}"
}

# Portal URL
output "portal_url" {
  description = "URL do portal do cluster"
  value       = "https://portal.azure.com/#@/resource${azurerm_kubernetes_cluster.main.id}/overview"
}

# Current Kubernetes Version
output "current_kubernetes_version" {
  description = "Versão atual do Kubernetes no cluster"
  value       = azurerm_kubernetes_cluster.main.current_kubernetes_version
}