output "tenant_id" {
  description = "ID do tenant Azure AD"
  value       = data.azuread_client_config.current.tenant_id
}

output "client_id" {
  description = "Client ID atual"
  value       = data.azuread_client_config.current.client_id
}

output "object_id" {
  description = "Object ID do principal atual"
  value       = data.azuread_client_config.current.object_id
}

# Users
output "users" {
  description = "Informações dos usuários criados"
  value = {
    for upn, user in azuread_user.users : upn => {
      id                  = user.id
      object_id           = user.object_id
      user_principal_name = user.user_principal_name
      display_name        = user.display_name
      mail                = user.mail
      mail_nickname       = user.mail_nickname
      account_enabled     = user.account_enabled
      employee_id         = user.employee_id
      job_title           = user.job_title
      department          = user.department
      usage_location      = user.usage_location
    }
  }
}

output "user_object_ids" {
  description = "Map de UPNs para Object IDs"
  value       = local.user_object_ids
}

output "user_principal_names" {
  description = "Lista de User Principal Names"
  value       = [for user in azuread_user.users : user.user_principal_name]
}

# Groups
output "groups" {
  description = "Informações dos grupos criados"
  value = {
    for name, group in azuread_group.groups : name => {
      id                  = group.id
      object_id           = group.object_id
      display_name        = group.display_name
      mail                = group.mail
      mail_enabled        = group.mail_enabled
      security_enabled    = group.security_enabled
      types               = group.types
      assignable_to_role  = group.assignable_to_role
    }
  }
}

output "group_object_ids" {
  description = "Map de nomes de grupos para Object IDs"
  value       = local.group_object_ids
}

output "group_names" {
  description = "Lista de nomes de grupos"
  value       = [for group in azuread_group.groups : group.display_name]
}

# Applications
output "applications" {
  description = "Informações das aplicações criadas"
  value = {
    for name, app in azuread_application.apps : name => {
      id                    = app.id
      object_id             = app.object_id
      application_id        = app.application_id
      client_id             = app.application_id
      display_name          = app.display_name
      sign_in_audience      = app.sign_in_audience
      identifier_uris       = app.identifier_uris
      oauth2_permission_scope_ids = app.oauth2_permission_scope_ids
      app_role_ids          = app.app_role_ids
    }
  }
}

output "application_ids" {
  description = "Map de nomes de aplicações para Application IDs (Client IDs)"
  value       = local.app_ids
  sensitive   = true
}

output "application_object_ids" {
  description = "Map de nomes de aplicações para Object IDs"
  value = {
    for name, app in azuread_application.apps : name => app.object_id
  }
}

# Service Principals
output "service_principals" {
  description = "Informações dos service principals criados"
  value = {
    for name, sp in azuread_service_principal.sps : name => {
      id                           = sp.id
      object_id                    = sp.object_id
      application_id               = sp.application_id
      client_id                    = sp.application_id
      display_name                 = sp.display_name
      app_role_assignment_required = sp.app_role_assignment_required
      sign_in_audience             = sp.sign_in_audience
      service_principal_names      = sp.service_principal_names
      app_role_ids                 = sp.app_role_ids
      oauth2_permission_scope_ids  = sp.oauth2_permission_scope_ids
    }
  }
}

output "service_principal_object_ids" {
  description = "Map de nomes de service principals para Object IDs"
  value       = local.sp_object_ids
}

output "service_principal_application_ids" {
  description = "Map de nomes de service principals para Application IDs"
  value = {
    for name, sp in azuread_service_principal.sps : name => sp.application_id
  }
  sensitive = true
}

# Administrative Units
output "administrative_units" {
  description = "Informações das administrative units criadas"
  value = {
    for name, unit in azuread_administrative_unit.units : name => {
      id                        = unit.id
      object_id                 = unit.object_id
      display_name              = unit.display_name
      description               = unit.description
      hidden_membership_enabled = unit.hidden_membership_enabled
    }
  }
}

output "administrative_unit_object_ids" {
  description = "Map de nomes de administrative units para Object IDs"
  value = {
    for name, unit in azuread_administrative_unit.units : name => unit.object_id
  }
}

# Conditional Access Policies
output "conditional_access_policies" {
  description = "Informações das políticas de acesso condicional"
  value = {
    for name, policy in azuread_conditional_access_policy.policies : name => {
      id           = policy.id
      display_name = policy.display_name
      state        = policy.state
    }
  }
}

output "conditional_access_policy_ids" {
  description = "Map de nomes de políticas para IDs"
  value = {
    for name, policy in azuread_conditional_access_policy.policies : name => policy.id
  }
}

# Named Locations
output "named_locations" {
  description = "Informações dos named locations"
  value = {
    for name, location in azuread_named_location.locations : name => {
      id           = location.id
      display_name = location.display_name
    }
  }
}

output "named_location_ids" {
  description = "Map de nomes de locations para IDs"
  value = {
    for name, location in azuread_named_location.locations : name => location.id
  }
}

# Custom Directory Roles
output "custom_directory_roles" {
  description = "Informações dos custom directory roles"
  value = {
    for name, role in azuread_custom_directory_role.roles : name => {
      id           = role.id
      object_id    = role.object_id
      display_name = role.display_name
      description  = role.description
      enabled      = role.enabled
      template_id  = role.template_id
    }
  }
}

output "custom_directory_role_ids" {
  description = "Map de nomes de roles para Object IDs"
  value = {
    for name, role in azuread_custom_directory_role.roles : name => role.object_id
  }
}

# Summary
output "summary" {
  description = "Resumo dos recursos criados"
  value = {
    tenant_id                      = data.azuread_client_config.current.tenant_id
    users_count                    = length(azuread_user.users)
    groups_count                   = length(azuread_group.groups)
    applications_count             = length(azuread_application.apps)
    service_principals_count       = length(azuread_service_principal.sps)
    administrative_units_count     = length(azuread_administrative_unit.units)
    conditional_access_policies_count = length(azuread_conditional_access_policy.policies)
    named_locations_count          = length(azuread_named_location.locations)
    custom_directory_roles_count   = length(azuread_custom_directory_role.roles)
  }
}

# Group Memberships Summary
output "group_memberships_summary" {
  description = "Resumo das associações de grupos"
  value = {
    for membership_key, membership in var.group_memberships : membership_key => {
      group_name   = membership.group_name
      group_id     = azuread_group.groups[membership.group_name].object_id
      members_count = length(membership.member_upns)
      member_upns  = membership.member_upns
    }
  }
}

# Lists for easy reference
output "user_upn_list" {
  description = "Lista simples de User Principal Names"
  value       = keys(azuread_user.users)
}

output "group_name_list" {
  description = "Lista simples de nomes de grupos"
  value       = keys(azuread_group.groups)
}

output "application_name_list" {
  description = "Lista simples de nomes de aplicações"
  value       = keys(azuread_application.apps)
}

output "service_principal_name_list" {
  description = "Lista simples de nomes de service principals"
  value       = keys(azuread_service_principal.sps)
}