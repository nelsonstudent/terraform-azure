output "id" {
  description = "ID do Key Vault"
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "Nome do Key Vault"
  value       = azurerm_key_vault.main.name
}

output "vault_uri" {
  description = "URI do Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "location" {
  description = "Localização do Key Vault"
  value       = azurerm_key_vault.main.location
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_key_vault.main.resource_group_name
}

output "tenant_id" {
  description = "Tenant ID do Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "sku_name" {
  description = "SKU do Key Vault"
  value       = azurerm_key_vault.main.sku_name
}

output "purge_protection_enabled" {
  description = "Status da proteção contra purge"
  value       = azurerm_key_vault.main.purge_protection_enabled
}

output "soft_delete_retention_days" {
  description = "Dias de retenção do soft delete"
  value       = azurerm_key_vault.main.soft_delete_retention_days
}

output "enable_rbac_authorization" {
  description = "Status da autorização RBAC"
  value       = azurerm_key_vault.main.enable_rbac_authorization
}

output "secrets" {
  description = "Map de secrets criados"
  value = {
    for k, v in azurerm_key_vault_secret.secrets : k => {
      id           = v.id
      name         = v.name
      version      = v.version
      versionless_id = v.versionless_id
    }
  }
}

output "secret_ids" {
  description = "IDs dos secrets criados"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_versions" {
  description = "Versões dos secrets criados"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.version }
}

output "keys" {
  description = "Map de keys criadas"
  value = {
    for k, v in azurerm_key_vault_key.keys : k => {
      id           = v.id
      name         = v.name
      version      = v.version
      versionless_id = v.versionless_id
      key_type     = v.key_type
      key_size     = v.key_size
    }
  }
}

output "key_ids" {
  description = "IDs das keys criadas"
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.id }
}

output "certificates" {
  description = "Map de certificados criados"
  value = {
    for k, v in azurerm_key_vault_certificate.certificates : k => {
      id             = v.id
      name           = v.name
      version        = v.version
      versionless_id = v.versionless_id
      thumbprint     = v.thumbprint
      secret_id      = v.secret_id
    }
  }
}

output "certificate_ids" {
  description = "IDs dos certificados criados"
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.id }
}

output "certificate_thumbprints" {
  description = "Thumbprints dos certificados"
  value       = { for k, v in azurerm_key_vault_certificate.certificates : k => v.thumbprint }
}

output "private_endpoint_id" {
  description = "ID do Private Endpoint"
  value       = try(azurerm_private_endpoint.main[0].id, null)
}

output "private_endpoint_ip" {
  description = "IP privado do Private Endpoint"
  value       = try(azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address, null)
}

output "diagnostic_setting_id" {
  description = "ID do Diagnostic Setting"
  value       = try(azurerm_monitor_diagnostic_setting.main[0].id, null)
}

output "network_acls" {
  description = "Configurações de Network ACLs"
  value = {
    bypass         = var.network_acls.bypass
    default_action = var.network_acls.default_action
    ip_rules       = var.network_acls.ip_rules
    subnet_ids     = var.network_acls.virtual_network_subnet_ids
  }
}

output "resource" {
  description = "Objeto completo do recurso Key Vault"
  value       = azurerm_key_vault.main
  sensitive   = true
}