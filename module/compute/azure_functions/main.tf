terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Storage Account (necessário para Azure Functions)
resource "azurerm_storage_account" "function" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled       = true
  allow_nested_items_to_be_public = false

  network_rules {
    default_action             = var.storage_default_action
    bypass                     = ["AzureServices"]
    ip_rules                   = var.storage_ip_rules
    virtual_network_subnet_ids = var.storage_subnet_ids
  }

  tags = var.tags
}

# Service Plan for Functions
resource "azurerm_service_plan" "function" {
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

# Linux Function App
resource "azurerm_linux_function_app" "main" {
  count = var.os_type == "Linux" ? 1 : 0

  name                          = var.function_app_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.function.id
  storage_account_name          = azurerm_storage_account.function.name
  storage_account_access_key    = var.use_storage_access_key ? azurerm_storage_account.function.primary_access_key : null
  https_only                    = var.https_only
  enabled                       = var.enabled
  builtin_logging_enabled       = var.builtin_logging_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  public_network_access_enabled = var.public_network_access_enabled
  functions_extension_version   = var.functions_extension_version

  site_config {
    always_on                              = var.always_on
    api_definition_url                     = var.api_definition_url
    api_management_api_id                  = var.api_management_api_id
    app_command_line                       = var.app_command_line
    app_scale_limit                        = var.app_scale_limit
    application_insights_connection_string = var.application_insights_connection_string
    application_insights_key               = var.application_insights_key
    ftps_state                             = var.ftps_state
    health_check_path                      = var.health_check_path
    health_check_eviction_time_in_min      = var.health_check_eviction_time
    http2_enabled                          = var.http2_enabled
    minimum_tls_version                    = var.minimum_tls_version
    pre_warmed_instance_count              = var.pre_warmed_instance_count
    remote_debugging_enabled               = var.remote_debugging_enabled
    remote_debugging_version               = var.remote_debugging_version
    runtime_scale_monitoring_enabled       = var.runtime_scale_monitoring_enabled
    scm_minimum_tls_version                = var.minimum_tls_version
    use_32_bit_worker                      = var.use_32_bit_worker
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    websockets_enabled                     = var.websockets_enabled
    elastic_instance_minimum               = var.elastic_instance_minimum
    worker_count                           = var.site_config_worker_count

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = lookup(application_stack.value, "dotnet_version", null)
        use_dotnet_isolated_runtime = lookup(application_stack.value, "use_dotnet_isolated_runtime", null)
        java_version                = lookup(application_stack.value, "java_version", null)
        node_version                = lookup(application_stack.value, "node_version", null)
        python_version              = lookup(application_stack.value, "python_version", null)
        powershell_core_version     = lookup(application_stack.value, "powershell_core_version", null)
        use_custom_runtime          = lookup(application_stack.value, "use_custom_runtime", null)

        dynamic "docker" {
          for_each = lookup(application_stack.value, "docker", null) != null ? [application_stack.value.docker] : []
          content {
            registry_url      = docker.value.registry_url
            image_name        = docker.value.image_name
            image_tag         = docker.value.image_tag
            registry_username = lookup(docker.value, "registry_username", null)
            registry_password = lookup(docker.value, "registry_password", null)
          }
        }
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
        headers                   = lookup(ip_restriction.value, "headers", null)
      }
    }

    dynamic "app_service_logs" {
      for_each = var.app_service_logs != null ? [var.app_service_logs] : []
      content {
        disk_quota_mb         = lookup(app_service_logs.value, "disk_quota_mb", 35)
        retention_period_days = lookup(app_service_logs.value, "retention_period_days", null)
      }
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME"     = var.functions_worker_runtime
      "WEBSITE_RUN_FROM_PACKAGE"     = var.run_from_package_url != null ? var.run_from_package_url : "1"
      "FUNCTIONS_EXTENSION_VERSION"  = var.functions_extension_version
    }
  )

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

  dynamic "sticky_settings" {
    for_each = var.sticky_settings != null ? [var.sticky_settings] : []
    content {
      app_setting_names       = lookup(sticky_settings.value, "app_setting_names", null)
      connection_string_names = lookup(sticky_settings.value, "connection_string_names", null)
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
    ]
  }
}

# Windows Function App
resource "azurerm_windows_function_app" "main" {
  count = var.os_type == "Windows" ? 1 : 0

  name                          = var.function_app_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.function.id
  storage_account_name          = azurerm_storage_account.function.name
  storage_account_access_key    = var.use_storage_access_key ? azurerm_storage_account.function.primary_access_key : null
  https_only                    = var.https_only
  enabled                       = var.enabled
  builtin_logging_enabled       = var.builtin_logging_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  public_network_access_enabled = var.public_network_access_enabled
  functions_extension_version   = var.functions_extension_version

  site_config {
    always_on                              = var.always_on
    api_definition_url                     = var.api_definition_url
    api_management_api_id                  = var.api_management_api_id
    app_command_line                       = var.app_command_line
    app_scale_limit                        = var.app_scale_limit
    application_insights_connection_string = var.application_insights_connection_string
    application_insights_key               = var.application_insights_key
    ftps_state                             = var.ftps_state
    health_check_path                      = var.health_check_path
    health_check_eviction_time_in_min      = var.health_check_eviction_time
    http2_enabled                          = var.http2_enabled
    minimum_tls_version                    = var.minimum_tls_version
    pre_warmed_instance_count              = var.pre_warmed_instance_count
    remote_debugging_enabled               = var.remote_debugging_enabled
    remote_debugging_version               = var.remote_debugging_version
    runtime_scale_monitoring_enabled       = var.runtime_scale_monitoring_enabled
    scm_minimum_tls_version                = var.minimum_tls_version
    use_32_bit_worker                      = var.use_32_bit_worker
    vnet_route_all_enabled                 = var.vnet_route_all_enabled
    websockets_enabled                     = var.websockets_enabled
    elastic_instance_minimum               = var.elastic_instance_minimum
    worker_count                           = var.site_config_worker_count

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = lookup(application_stack.value, "dotnet_version", null)
        use_dotnet_isolated_runtime = lookup(application_stack.value, "use_dotnet_isolated_runtime", null)
        java_version                = lookup(application_stack.value, "java_version", null)
        node_version                = lookup(application_stack.value, "node_version", null)
        powershell_core_version     = lookup(application_stack.value, "powershell_core_version", null)
        use_custom_runtime          = lookup(application_stack.value, "use_custom_runtime", null)
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

  app_settings = merge(
    var.app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME"     = var.functions_worker_runtime
      "WEBSITE_RUN_FROM_PACKAGE"     = var.run_from_package_url != null ? var.run_from_package_url : "1"
      "FUNCTIONS_EXTENSION_VERSION"  = var.functions_extension_version
    }
  )

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
    ]
  }
}

# Function App Slot (Staging)
resource "azurerm_linux_function_app_slot" "main" {
  for_each = var.os_type == "Linux" && var.deployment_slots != null ? var.deployment_slots : {}

  name                       = each.key
  function_app_id            = azurerm_linux_function_app.main[0].id
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = var.use_storage_access_key ? azurerm_storage_account.function.primary_access_key : null
  https_only                 = var.https_only

  site_config {
    always_on                              = var.always_on
    application_insights_connection_string = var.application_insights_connection_string
    application_insights_key               = var.application_insights_key
  }

  app_settings = merge(
    var.app_settings,
    lookup(each.value, "app_settings", {}),
    {
      "FUNCTIONS_WORKER_RUNTIME"     = var.functions_worker_runtime
      "FUNCTIONS_EXTENSION_VERSION"  = var.functions_extension_version
    }
  )

  tags = var.tags
}

# VNet Integration
resource "azurerm_app_service_virtual_network_swift_connection" "function" {
  count = var.vnet_integration_subnet_id != null ? 1 : 0

  app_service_id = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
  subnet_id      = var.vnet_integration_subnet_id
}

# Application Insights (opcional, mas recomendado)
resource "azurerm_application_insights" "function" {
  count = var.create_application_insights ? 1 : 0

  name                = "${var.function_app_name}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_insights_type
  retention_in_days   = var.application_insights_retention_days
  sampling_percentage = var.application_insights_sampling_percentage

  tags = var.tags
}

# Storage Queue (se necessário para triggers)
resource "azurerm_storage_queue" "triggers" {
  for_each = var.storage_queues

  name                 = each.key
  storage_account_name = azurerm_storage_account.function.name
}

# Storage Container (para blobs)
resource "azurerm_storage_container" "triggers" {
  for_each = var.storage_containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.function.name
  container_access_type = lookup(each.value, "access_type", "private")
}
