# Users
variable "users" {
  description = "Lista de usuários a serem criados"
  type = list(object({
    user_principal_name   = string
    display_name          = string
    mail_nickname         = optional(string)
    password              = optional(string)
    force_password_change = optional(bool, true)
    account_enabled       = optional(bool, true)
    usage_location        = optional(string)
    job_title             = optional(string)
    department            = optional(string)
    company_name          = optional(string)
    employee_id           = optional(string)
    manager_id            = optional(string)
    other_mails           = optional(list(string), [])
    street_address        = optional(string)
    city                  = optional(string)
    state                 = optional(string)
    postal_code           = optional(string)
    country               = optional(string)
    mobile_phone          = optional(string)
    business_phones       = optional(list(string), [])
  }))
  default   = []
  sensitive = true
}

# Groups
variable "groups" {
  description = "Lista de grupos a serem criados"
  type = list(object({
    display_name            = string
    mail_enabled            = optional(bool, false)
    mail_nickname           = optional(string)
    security_enabled        = optional(bool, true)
    types                   = optional(list(string), [])
    description             = optional(string)
    assignable_to_role      = optional(bool, false)
    behaviors               = optional(list(string), [])
    external_senders_allowed = optional(bool, false)
    hide_from_address_lists = optional(bool, false)
    hide_from_outlook_clients = optional(bool, false)
    visibility              = optional(string, "Private")
    theme                   = optional(string)
  }))
  default = []
}

# Group Memberships
variable "group_memberships" {
  description = "Mapeamento de membros para grupos"
  type = map(object({
    group_name  = string
    member_upns = list(string)  # User Principal Names
  }))
  default = {}
}

# Service Principals (Applications)
variable "service_principals" {
  description = "Lista de service principals/aplicações"
  type = list(object({
    display_name               = string
    description                = optional(string)
    app_role_assignment_required = optional(bool, false)
    owners                     = optional(list(string), [])
    tags                       = optional(list(string), [])
    notes                      = optional(string)
    login_url                  = optional(string)
    notification_email_addresses = optional(list(string), [])
    use_existing_application   = optional(bool, false)
    application_id             = optional(string)
  }))
  default = []
}

# Application Registrations
variable "applications" {
  description = "Lista de application registrations"
  type = list(object({
    display_name               = string
    sign_in_audience           = optional(string, "AzureADMyOrg")
    description                = optional(string)
    device_only_auth_enabled   = optional(bool, false)
    fallback_public_client_enabled = optional(bool, false)
    group_membership_claims    = optional(list(string))
    identifier_uris            = optional(list(string), [])
    oauth2_post_response_required = optional(bool, false)
    owners                     = optional(list(string), [])
    prevent_duplicate_names    = optional(bool, false)
    support_url                = optional(string)
    terms_of_service_url       = optional(string)
    privacy_statement_url      = optional(string)
    logo_image                 = optional(string)
    marketing_url              = optional(string)
    notes                      = optional(string)
    
    # API Permissions
    required_resource_access = optional(list(object({
      resource_app_id = string
      resource_access = list(object({
        id   = string
        type = string  # Scope or Role
      }))
    })), [])
    
    # App Roles
    app_roles = optional(list(object({
      allowed_member_types = list(string)
      description         = string
      display_name        = string
      id                  = string
      value               = string
      enabled             = optional(bool, true)
    })), [])
    
    # Web/SPA/Public Client
    web = optional(object({
      homepage_url  = optional(string)
      logout_url    = optional(string)
      redirect_uris = optional(list(string), [])
      implicit_grant = optional(object({
        access_token_issuance_enabled = optional(bool, false)
        id_token_issuance_enabled     = optional(bool, false)
      }))
    }))
    
    single_page_application = optional(object({
      redirect_uris = list(string)
    }))
    
    public_client = optional(object({
      redirect_uris = list(string)
    }))
  }))
  default = []
}

# Administrative Units
variable "administrative_units" {
  description = "Lista de administrative units"
  type = list(object({
    display_name              = string
    description               = optional(string)
    hidden_membership_enabled = optional(bool, false)
    members                   = optional(list(string), [])
  }))
  default = []
}

# Conditional Access Policies
variable "conditional_access_policies" {
  description = "Lista de políticas de acesso condicional"
  type = list(object({
    display_name = string
    state        = string  # enabled, disabled, enabledForReportingButNotEnforced
    
    conditions = object({
      client_app_types = list(string)
      
      applications = object({
        included_applications = list(string)
        excluded_applications = optional(list(string), [])
      })
      
      users = object({
        included_users  = optional(list(string), [])
        excluded_users  = optional(list(string), [])
        included_groups = optional(list(string), [])
        excluded_groups = optional(list(string), [])
        included_roles  = optional(list(string), [])
        excluded_roles  = optional(list(string), [])
      })
      
      locations = optional(object({
        included_locations = list(string)
        excluded_locations = optional(list(string), [])
      }))
      
      platforms = optional(object({
        included_platforms = list(string)
        excluded_platforms = optional(list(string), [])
      }))
      
      sign_in_risk_levels = optional(list(string), [])
      user_risk_levels    = optional(list(string), [])
    })
    
    grant_controls = object({
      operator          = string  # AND or OR
      built_in_controls = list(string)
      custom_authentication_factors = optional(list(string), [])
      terms_of_use      = optional(list(string), [])
    })
    
    session_controls = optional(object({
      application_enforced_restrictions_enabled = optional(bool, false)
      cloud_app_security_policy                 = optional(string)
      sign_in_frequency                         = optional(number)
      sign_in_frequency_period                  = optional(string)
      persistent_browser_mode                   = optional(string)
    }))
  }))
  default = []
}

# Custom Directory Roles
variable "custom_directory_roles" {
  description = "Lista de custom directory roles"
  type = list(object({
    display_name = string
    description  = string
    enabled      = optional(bool, true)
    version      = string
    
    permissions = list(object({
      allowed_resource_actions = list(string)
    }))
  }))
  default = []
}

# Role Assignments
variable "role_assignments" {
  description = "Atribuições de roles a usuários/grupos/service principals"
  type = list(object({
    role_definition_name = string  # Ex: Global Administrator, User Administrator
    principal_upn        = optional(string)
    principal_object_id  = optional(string)
    scope                = optional(string, "/")
  }))
  default = []
}

# Named Locations
variable "named_locations" {
  description = "Named locations para Conditional Access"
  type = list(object({
    display_name = string
    ip_ranges    = list(string)
    trusted      = optional(bool, false)
  }))
  default = []
}

# Domain Settings
variable "domains" {
  description = "Custom domains para o tenant"
  type = list(object({
    domain_name                   = string
    authentication_type           = optional(string, "Managed")
    is_default                    = optional(bool, false)
    is_initial                    = optional(bool, false)
    supported_services            = optional(list(string), [])
  }))
  default = []
}

# Password Policies
variable "password_policies" {
  description = "Políticas de senha do tenant"
  type = object({
    password_reset_enabled                       = optional(bool, true)
    self_service_password_reset_enabled          = optional(bool, false)
    require_strong_password                      = optional(bool, true)
    password_expiration_days                     = optional(number, 90)
    password_notify_days_before_expiration       = optional(number, 14)
    enforce_password_history                     = optional(number, 24)
    minimum_password_length                      = optional(number, 8)
    minimum_password_age_days                    = optional(number, 1)
  })
  default = null
}

# Guest Settings
variable "guest_settings" {
  description = "Configurações para guest users"
  type = object({
    allow_invitations                   = optional(bool, true)
    guest_invite_restriction            = optional(string, "everyone")
    guest_user_role_permissions         = optional(string, "restricted")
    enable_guest_self_service_sign_up   = optional(bool, false)
  })
  default = null
}

# Company Branding
variable "company_branding" {
  description = "Configurações de branding da empresa"
  type = object({
    background_color      = optional(string)
    background_image      = optional(string)
    banner_logo           = optional(string)
    sign_in_page_text     = optional(string)
    square_logo           = optional(string)
    username_hint_text    = optional(string)
    locale                = optional(string, "en-US")
  })
  default = null
}

# Security Defaults
variable "enable_security_defaults" {
  description = "Habilitar security defaults"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags comuns para recursos"
  type        = map(string)
  default     = {}
}