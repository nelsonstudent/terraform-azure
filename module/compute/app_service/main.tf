terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Service Plan (App Service Plan)
resource "azurerm_service_plan" "main" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  maximum_elastic_worker_count = var.maximum_elastic_worker_count
  worker_count                 = var.worker_count
  per_site_scaling_enabled     = var.per_site_scaling_enabled
  zone_balancing_enabled       = var.zone_balancing_enabled

  tags = var.tags
}

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  count = var.os_type == "Linux" ? 1 : 0

  name                          = var.app_service_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.main.id
  https_only                    = var.https_only
  client_affinity_enabled       = var.client_affinity_enabled
  enabled                       = var.enabled
  public_network_access_enabled = var.public_network_access_enabled

  site_config {
    always_on                               = var.always_on
    ftps_state                              = var.ftps_state
    health_check_path                       = var.health_check_path
    health_check_eviction_time_in_min       = var.health_check_eviction_time
    http2_enabled                           = var.http2_enabled
    minimum_tls_version                     = var.minimum_tls_version
    remote_debugging_enabled                = var.remote_debugging_enabled
    remote_debugging_version                = var.remote_debugging_version
    scm_minimum_tls_version                 = var.minimum_tls_version
    use_32_bit_worker                       = var.use_32_bit_worker
    websockets_enabled                      = var.websockets_enabled
    vnet_route_all_enabled                  = var.vnet_route_all_enabled
    container_registry_use_managed_identity = var.container_registry_use_managed_identity

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        docker_image_name        = lookup(application_stack.value, "docker_image_name", null)
        docker_registry_url      = lookup(application_stack.value, "docker_registry_url", null)
        docker_registry_username = lookup(application_stack.value, "docker_registry_username", null)
        docker_registry_password = lookup(application_stack.value, "docker_registry_password", null)
        dotnet_version           = lookup(application_stack.value, "dotnet_version", null)
        go_version               = lookup(application_stack.value, "go_version", null)
        java_server              = lookup(application_stack.value, "java_server", null)
        java_server_version      = lookup(application_stack.value, "java_server_version", null)
        java_version             = lookup(application_stack.value, "java_version", null)
        node_version             = lookup(application_stack.value, "node_version", null)
        php_version              = lookup(application_stack.value, "php_version", null)
        python_version           = lookup(application_stack.value, "python_version", null)
        ruby_version             = lookup(application_stack.value, "ruby_version", null)
      }
    }

    dynamic "cors" {
      for_each = var.cors_settings != null ? [var.cors_settings] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = lookup(cors.value, "support_credentials", false)
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = lookup(ip_restriction.value, "name", null)
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        action                    = lookup(ip_restriction.value, "action", "Allow")
        priority                  = lookup(ip_restriction.value, "priority", 65000)
      }
    }
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "auth_settings_v2" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      auth_enabled           = auth_settings_v2.value.auth_enabled
      require_authentication = lookup(auth_settings_v2.value, "require_authentication", true)
      require_https          = lookup(auth_settings_v2.value, "require_https", true)
      runtime_version        = lookup(auth_settings_v2.value, "runtime_version", "~1")

      dynamic "login" {
        for_each = lookup(auth_settings_v2.value, "login", null) != null ? [auth_settings_v2.value.login] : []
        content {
          token_store_enabled = lookup(login.value, "token_store_enabled", false)
        }
      }
    }
  }

  dynamic "backup" {
    for_each = var.backup_settings != null ? [var.backup_settings] : []
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url
      enabled             = lookup(backup.value, "enabled", true)

      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = lookup(backup.value.schedule, "keep_at_least_one_backup", true)
        retention_period_days    = lookup(backup.value.schedule, "retention_period_days", 30)
      }
    }
  }

  dynamic "logs" {
    for_each = var.enable_logs ? [1] : []
    content {
      detailed_error_messages = var.detailed_error_messages
      failed_request_tracing  = var.failed_request_tracing

      dynamic "application_logs" {
        for_each = var.application_logs != null ? [var.application_logs] : []
        content {
          file_system_level = application_logs.value.file_system_level

          dynamic "azure_blob_storage" {
            for_each = lookup(application_logs.value, "azure_blob_storage", null) != null ? [application_logs.value.azure_blob_storage] : []
            content {
              level             = azure_blob_storage.value.level
              sas_url           = azure_blob_storage.value.sas_url
              retention_in_days = azure_blob_storage.value.retention_in_days
            }
          }
        }
      }

      dynamic "http_logs" {
        for_each = var.http_logs != null ? [var.http_logs] : []
        content {
          dynamic "file_system" {
            for_each = lookup(http_logs.value, "file_system", null) != null ? [http_logs.value.file_system] : []
            content {
              retention_in_days = file_system.value.retention_in_days
              retention_in_mb   = file_system.value.retention_in_mb
            }
          }

          dynamic "azure_blob_storage" {
            for_each = lookup(http_logs.value, "azure_blob_storage", null) != null ? [http_logs.value.azure_blob_storage] : []
            content {
              sas_url           = azure_blob_storage.value.sas_url
              retention_in_days = azure_blob_storage.value.retention_in_days
            }
          }
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Windows Web App
resource "azurerm_windows_web_app" "main" {
  count = var.os_type == "Windows" ? 1 : 0

  name                          = var.app_service_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.main.id
  https_only                    = var.https_only
  client_affinity_enabled       = var.client_affinity_enabled
  enabled                       = var.enabled
  public_network_access_enabled = var.public_network_access_enabled

  site_config {
    always_on                         = var.always_on
    ftps_state                        = var.ftps_state
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time
    http2_enabled                     = var.http2_enabled
    minimum_tls_version               = var.minimum_tls_version
    remote_debugging_enabled          = var.remote_debugging_enabled
    remote_debugging_version          = var.remote_debugging_version
    scm_minimum_tls_version           = var.minimum_tls_version
    use_32_bit_worker                 = var.use_32_bit_worker
    websockets_enabled                = var.websockets_enabled
    vnet_route_all_enabled            = var.vnet_route_all_enabled

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        current_stack                = lookup(application_stack.value, "current_stack", null)
        dotnet_version               = lookup(application_stack.value, "dotnet_version", null)
        dotnet_core_version          = lookup(application_stack.value, "dotnet_core_version", null)
        tomcat_version               = lookup(application_stack.value, "tomcat_version", null)
        java_embedded_server_enabled = lookup(application_stack.value, "java_embedded_server_enabled", null)
        java_version                 = lookup(application_stack.value, "java_version", null)
        node_version                 = lookup(application_stack.value, "node_version", null)
        php_version                  = lookup(application_stack.value, "php_version", null)
        python                       = lookup(application_stack.value, "python", null)
      }
    }

    dynamic "cors" {
      for_each = var.cors_settings != null ? [var.cors_settings] : []
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = lookup(cors.value, "support_credentials", false)
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = lookup(ip_restriction.value, "name", null)
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        action                    = lookup(ip_restriction.value, "action", "Allow")
        priority                  = lookup(ip_restriction.value, "priority", 65000)
      }
    }
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Custom Domain (optional)
resource "azurerm_app_service_custom_hostname_binding" "main" {
  for_each = var.custom_domains

  hostname            = each.value.hostname
  app_service_name    = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
  resource_group_name = var.resource_group_name
  ssl_state           = lookup(each.value, "ssl_state", "Disabled")
  thumbprint          = lookup(each.value, "thumbprint", null)
}

# Deployment Slot
resource "azurerm_linux_web_app_slot" "main" {
  for_each = var.os_type == "Linux" && var.deployment_slots != null ? var.deployment_slots : {}

  name           = each.key
  app_service_id = azurerm_linux_web_app.main[0].id
  https_only     = var.https_only

  site_config {
    always_on = var.always_on
  }

  app_settings = merge(var.app_settings, lookup(each.value, "app_settings", {}))

  tags = var.tags
}

# VNet Integration
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  count = var.vnet_integration_subnet_id != null ? 1 : 0

  app_service_id = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
  subnet_id      = var.vnet_integration_subnet_id
}
