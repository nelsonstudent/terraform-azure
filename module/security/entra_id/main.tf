terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# Data sources
data "azuread_client_config" "current" {}

# Users
resource "azuread_user" "users" {
  for_each = { for user in var.users : user.user_principal_name => user }

  user_principal_name   = each.value.user_principal_name
  display_name          = each.value.display_name
  mail_nickname         = each.value.mail_nickname != null ? each.value.mail_nickname : split("@", each.value.user_principal_name)[0]
  password              = each.value.password
  force_password_change = each.value.force_password_change
  account_enabled       = each.value.account_enabled
  usage_location        = each.value.usage_location
  
  job_title     = each.value.job_title
  department    = each.value.department
  company_name  = each.value.company_name
  employee_id   = each.value.employee_id
  manager_id    = each.value.manager_id
  other_mails   = each.value.other_mails
  
  street_address = each.value.street_address
  city           = each.value.city
  state          = each.value.state
  postal_code    = each.value.postal_code
  country        = each.value.country
  
  mobile_phone    = each.value.mobile_phone
  business_phones = each.value.business_phones

  lifecycle {
    ignore_changes = [password]
  }
}

# Groups
resource "azuread_group" "groups" {
  for_each = { for group in var.groups : group.display_name => group }

  display_name            = each.value.display_name
  mail_enabled            = each.value.mail_enabled
  mail_nickname           = each.value.mail_nickname
  security_enabled        = each.value.security_enabled
  types                   = each.value.types
  description             = each.value.description
  assignable_to_role      = each.value.assignable_to_role
  behaviors               = each.value.behaviors
  external_senders_allowed = each.value.external_senders_allowed
  hide_from_address_lists = each.value.hide_from_address_lists
  hide_from_outlook_clients = each.value.hide_from_outlook_clients
  visibility              = each.value.visibility
  theme                   = each.value.theme

  lifecycle {
    prevent_destroy = false
  }
}

# Group Memberships
resource "azuread_group_member" "memberships" {
  for_each = merge([
    for membership_key, membership in var.group_memberships : {
      for upn in membership.member_upns :
      "${membership_key}-${upn}" => {
        group_name = membership.group_name
        member_upn = upn
      }
    }
  ]...)

  group_object_id  = azuread_group.groups[each.value.group_name].id
  member_object_id = azuread_user.users[each.value.member_upn].id
}

# Applications
resource "azuread_application" "apps" {
  for_each = { for app in var.applications : app.display_name => app }

  display_name                   = each.value.display_name
  sign_in_audience               = each.value.sign_in_audience
  description                    = each.value.description
  device_only_auth_enabled       = each.value.device_only_auth_enabled
  fallback_public_client_enabled = each.value.fallback_public_client_enabled
  group_membership_claims        = each.value.group_membership_claims
  identifier_uris                = each.value.identifier_uris
  oauth2_post_response_required  = each.value.oauth2_post_response_required
  owners                         = each.value.owners
  prevent_duplicate_names        = each.value.prevent_duplicate_names
  
  support_url           = each.value.support_url
  terms_of_service_url  = each.value.terms_of_service_url
  privacy_statement_url = each.value.privacy_statement_url
  logo_image            = each.value.logo_image
  marketing_url         = each.value.marketing_url
  notes                 = each.value.notes

  # Required Resource Access (API Permissions)
  dynamic "required_resource_access" {
    for_each = each.value.required_resource_access
    content {
      resource_app_id = required_resource_access.value.resource_app_id
      
      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  # App Roles
  dynamic "app_role" {
    for_each = each.value.app_roles
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      id                   = app_role.value.id
      value                = app_role.value.value
      enabled              = app_role.value.enabled
    }
  }

  # Web Configuration
  dynamic "web" {
    for_each = each.value.web != null ? [each.value.web] : []
    content {
      homepage_url  = web.value.homepage_url
      logout_url    = web.value.logout_url
      redirect_uris = web.value.redirect_uris

      dynamic "implicit_grant" {
        for_each = web.value.implicit_grant != null ? [web.value.implicit_grant] : []
        content {
          access_token_issuance_enabled = implicit_grant.value.access_token_issuance_enabled
          id_token_issuance_enabled     = implicit_grant.value.id_token_issuance_enabled
        }
      }
    }
  }

  # Single Page Application
  dynamic "single_page_application" {
    for_each = each.value.single_page_application != null ? [each.value.single_page_application] : []
    content {
      redirect_uris = single_page_application.value.redirect_uris
    }
  }

  # Public Client
  dynamic "public_client" {
    for_each = each.value.public_client != null ? [each.value.public_client] : []
    content {
      redirect_uris = public_client.value.redirect_uris
    }
  }
}

# Service Principals
resource "azuread_service_principal" "sps" {
  for_each = { for sp in var.service_principals : sp.display_name => sp }

  client_id                    = each.value.use_existing_application ? each.value.application_id : azuread_application.apps[each.value.display_name].application_id
  app_role_assignment_required = each.value.app_role_assignment_required
  description                  = each.value.description
  owners                       = each.value.owners
  tags                         = each.value.tags
  notes                        = each.value.notes
  login_url                    = each.value.login_url
  notification_email_addresses = each.value.notification_email_addresses
}

# Administrative Units
resource "azuread_administrative_unit" "units" {
  for_each = { for unit in var.administrative_units : unit.display_name => unit }

  display_name              = each.value.display_name
  description               = each.value.description
  hidden_membership_enabled = each.value.hidden_membership_enabled
}

# Administrative Unit Members
resource "azuread_administrative_unit_member" "members" {
  for_each = merge([
    for unit in var.administrative_units : {
      for member_upn in unit.members :
      "${unit.display_name}-${member_upn}" => {
        unit_name  = unit.display_name
        member_upn = member_upn
      }
    }
  ]...)

  administrative_unit_object_id = azuread_administrative_unit.units[each.value.unit_name].id
  member_object_id              = azuread_user.users[each.value.member_upn].id
}

# Conditional Access Policies
resource "azuread_conditional_access_policy" "policies" {
  for_each = { for policy in var.conditional_access_policies : policy.display_name => policy }

  display_name = each.value.display_name
  state        = each.value.state

  conditions {
    client_app_types = each.value.conditions.client_app_types

    applications {
      included_applications = each.value.conditions.applications.included_applications
      excluded_applications = each.value.conditions.applications.excluded_applications
    }

    users {
      included_users  = each.value.conditions.users.included_users
      excluded_users  = each.value.conditions.users.excluded_users
      included_groups = each.value.conditions.users.included_groups
      excluded_groups = each.value.conditions.users.excluded_groups
      included_roles  = each.value.conditions.users.included_roles
      excluded_roles  = each.value.conditions.users.excluded_roles
    }

    dynamic "locations" {
      for_each = each.value.conditions.locations != null ? [each.value.conditions.locations] : []
      content {
        included_locations = locations.value.included_locations
        excluded_locations = locations.value.excluded_locations
      }
    }

    dynamic "platforms" {
      for_each = each.value.conditions.platforms != null ? [each.value.conditions.platforms] : []
      content {
        included_platforms = platforms.value.included_platforms
        excluded_platforms = platforms.value.excluded_platforms
      }
    }

    sign_in_risk_levels = each.value.conditions.sign_in_risk_levels
    user_risk_levels    = each.value.conditions.user_risk_levels
  }

  grant_controls {
    operator                      = each.value.grant_controls.operator
    built_in_controls             = each.value.grant_controls.built_in_controls
    custom_authentication_factors = each.value.grant_controls.custom_authentication_factors
    terms_of_use                  = each.value.grant_controls.terms_of_use
  }

  dynamic "session_controls" {
    for_each = each.value.session_controls != null ? [each.value.session_controls] : []
    content {
      application_enforced_restrictions_enabled = session_controls.value.application_enforced_restrictions_enabled
      cloud_app_security_policy                 = session_controls.value.cloud_app_security_policy
      sign_in_frequency                         = session_controls.value.sign_in_frequency
      sign_in_frequency_period                  = session_controls.value.sign_in_frequency_period
      persistent_browser_mode                   = session_controls.value.persistent_browser_mode
    }
  }
}

# Named Locations
resource "azuread_named_location" "locations" {
  for_each = { for location in var.named_locations : location.display_name => location }

  display_name = each.value.display_name

  ip {
    ip_ranges = each.value.ip_ranges
    trusted   = each.value.trusted
  }
}

# Custom Directory Roles
resource "azuread_custom_directory_role" "roles" {
  for_each = { for role in var.custom_directory_roles : role.display_name => role }

  display_name = each.value.display_name
  description  = each.value.description
  enabled      = each.value.enabled
  version      = each.value.version

  dynamic "permissions" {
    for_each = each.value.permissions
    content {
      allowed_resource_actions = permissions.value.allowed_resource_actions
    }
  }
}

# Locals
locals {
  # Map user UPNs to object IDs
  user_object_ids = {
    for upn, user in azuread_user.users : upn => user.id
  }
  
  # Map group names to object IDs
  group_object_ids = {
    for name, group in azuread_group.groups : name => group.id
  }
  
  # Map app names to application IDs
  app_ids = {
    for name, app in azuread_application.apps : name => app.application_id
  }
  
  # Map service principal names to object IDs
  sp_object_ids = {
    for name, sp in azuread_service_principal.sps : name => sp.id
  }
}
