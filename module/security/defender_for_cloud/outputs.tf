output "subscription_id" {
  description = "ID da subscription protegida"
  value       = local.subscription_id
}

output "pricing_tiers" {
  description = "Tiers de preços configurados por tipo de recurso"
  value = {
    for k, v in azurerm_security_center_subscription_pricing.main : k => {
      tier          = v.tier
      resource_type = v.resource_type
      subplan       = v.subplan
    }
  }
}

output "pricing_ids" {
  description = "IDs dos recursos de pricing"
  value       = { for k, v in azurerm_security_center_subscription_pricing.main : k => v.id }
}

output "security_contacts" {
  description = "Contatos de segurança configurados"
  value = {
    for k, v in azurerm_security_center_contact.main : k => {
      email               = v.email
      phone               = v.phone
      alert_notifications = v.alert_notifications
      alerts_to_admins    = v.alerts_to_admins
    }
  }
  sensitive = true
}

output "security_contact_ids" {
  description = "IDs dos contatos de segurança"
  value       = { for k, v in azurerm_security_center_contact.main : k => v.id }
}

output "auto_provisioning_enabled" {
  description = "Status do auto-provisioning"
  value       = var.auto_provisioning.enabled
}

output "auto_provisioning_id" {
  description = "ID do auto-provisioning"
  value       = try(azurerm_security_center_auto_provisioning.main[0].id, null)
}

output "workspace_id" {
  description = "ID do Log Analytics Workspace configurado"
  value       = var.log_analytics_workspace_id
}

output "workspace_integration_id" {
  description = "ID da integração com workspace"
  value       = try(azurerm_security_center_workspace.main[0].id, null)
}

output "assessment_policies" {
  description = "Políticas de assessment customizadas"
  value = {
    for k, v in azurerm_security_center_assessment_policy.main : k => {
      id           = v.id
      name         = v.name
      display_name = v.display_name
    }
  }
}

output "workflow_automations" {
  description = "Workflow automations configuradas"
  value = {
    for k, v in azurerm_security_center_automation.main : k => {
      id      = v.id
      name    = v.name
      enabled = v.enabled
    }
  }
}

output "workflow_automation_ids" {
  description = "IDs das workflow automations"
  value       = { for k, v in azurerm_security_center_automation.main : k => v.id }
}

output "jit_policies" {
  description = "Políticas JIT configuradas"
  value = {
    for k, v in azurerm_security_center_jit_network_access_policy.main : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "jit_policy_ids" {
  description = "IDs das políticas JIT"
  value       = { for k, v in azurerm_security_center_jit_network_access_policy.main : k => v.id }
}

output "advanced_threat_protection" {
  description = "Configurações de Advanced Threat Protection"
  value = {
    for k, v in azurerm_advanced_threat_protection.main : k => {
      id                 = v.id
      target_resource_id = v.target_resource_id
      enabled            = v.enabled
    }
  }
}

output "advanced_threat_protection_ids" {
  description = "IDs das configurações de ATP"
  value       = { for k, v in azurerm_advanced_threat_protection.main : k => v.id }
}

output "mcas_setting_id" {
  description = "ID da configuração MCAS"
  value       = azurerm_security_center_setting.mcas.id
}

output "wdatp_setting_id" {
  description = "ID da configuração WDATP"
  value       = azurerm_security_center_setting.wdatp.id
}

output "sentinel_setting_id" {
  description = "ID da configuração Sentinel"
  value       = try(azurerm_security_center_setting.sentinel[0].id, null)
}

output "defender_plans_summary" {
  description = "Resumo dos planos Defender habilitados"
  value = {
    enabled_plans = [
      for k, v in azurerm_security_center_subscription_pricing.main :
      k if v.tier == "Standard"
    ]
    free_plans = [
      for k, v in azurerm_security_center_subscription_pricing.main :
      k if v.tier == "Free"
    ]
    total_plans = length(azurerm_security_center_subscription_pricing.main)
  }
}

output "security_posture" {
  description = "Informações sobre postura de segurança"
  value = {
    auto_provisioning_enabled  = var.auto_provisioning.enabled
    workspace_integrated       = var.log_analytics_workspace_id != null
    contacts_configured        = length(local.security_contacts) > 0
    jit_policies_count         = length(var.jit_policies)
    workflow_automations_count = length(var.workflow_automations)
    atp_resources_count        = length(var.advanced_threat_protection)
  }
}