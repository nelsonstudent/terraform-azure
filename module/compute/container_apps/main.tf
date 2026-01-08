terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Log Analytics Workspace (necessário para Container Apps Environment)
resource "azurerm_log_analytics_workspace" "main" {
  count = var.create_log_analytics_workspace ? 1 : 0

  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = var.tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                           = var.environment_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.zone_redundancy_enabled

  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = lookup(workload_profile.value, "minimum_count", null)
      maximum_count         = lookup(workload_profile.value, "maximum_count", null)
    }
  }

  tags = var.tags
}

# Container App
resource "azurerm_container_app" "main" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode
  workload_profile_name        = var.workload_profile_name

  template {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    revision_suffix = var.revision_suffix

    dynamic "container" {
      for_each = var.containers
      content {
        name    = container.value.name
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        args    = lookup(container.value, "args", null)
        command = lookup(container.value, "command", null)

        dynamic "env" {
          for_each = lookup(container.value, "env", [])
          content {
            name        = env.value.name
            value       = lookup(env.value, "value", null)
            secret_name = lookup(env.value, "secret_name", null)
          }
        }

        dynamic "liveness_probe" {
          for_each = lookup(container.value, "liveness_probe", null) != null ? [container.value.liveness_probe] : []
          content {
            transport                        = liveness_probe.value.transport
            port                             = liveness_probe.value.port
            path                             = lookup(liveness_probe.value, "path", null)
            host                             = lookup(liveness_probe.value, "host", null)
            interval_seconds                 = lookup(liveness_probe.value, "interval_seconds", 10)
            timeout                          = lookup(liveness_probe.value, "timeout", 1)
            failure_count_threshold          = lookup(liveness_probe.value, "failure_count_threshold", 3)
            
            dynamic "header" {
              for_each = lookup(liveness_probe.value, "headers", [])
              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }

        dynamic "readiness_probe" {
          for_each = lookup(container.value, "readiness_probe", null) != null ? [container.value.readiness_probe] : []
          content {
            transport                        = readiness_probe.value.transport
            port                             = readiness_probe.value.port
            path                             = lookup(readiness_probe.value, "path", null)
            host                             = lookup(readiness_probe.value, "host", null)
            interval_seconds                 = lookup(readiness_probe.value, "interval_seconds", 10)
            timeout                          = lookup(readiness_probe.value, "timeout", 1)
            failure_count_threshold          = lookup(readiness_probe.value, "failure_count_threshold", 3)
            success_count_threshold          = lookup(readiness_probe.value, "success_count_threshold", 1)
            
            dynamic "header" {
              for_each = lookup(readiness_probe.value, "headers", [])
              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = lookup(container.value, "startup_probe", null) != null ? [container.value.startup_probe] : []
          content {
            transport                        = startup_probe.value.transport
            port                             = startup_probe.value.port
            path                             = lookup(startup_probe.value, "path", null)
            host                             = lookup(startup_probe.value, "host", null)
            interval_seconds                 = lookup(startup_probe.value, "interval_seconds", 10)
            timeout                          = lookup(startup_probe.value, "timeout", 1)
            failure_count_threshold          = lookup(startup_probe.value, "failure_count_threshold", 3)
            
            dynamic "header" {
              for_each = lookup(startup_probe.value, "headers", [])
              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }

        dynamic "volume_mounts" {
          for_each = lookup(container.value, "volume_mounts", [])
          content {
            name = volume_mounts.value.name
            path = volume_mounts.value.path
          }
        }
      }
    }

    dynamic "volume" {
      for_each = var.volumes
      content {
        name         = volume.value.name
        storage_type = volume.value.storage_type
        storage_name = lookup(volume.value, "storage_name", null)
      }
    }

    dynamic "azure_queue_scale_rule" {
      for_each = var.azure_queue_scale_rules
      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.queue_name
        queue_length = azure_queue_scale_rule.value.queue_length

        authentication {
          secret_name       = azure_queue_scale_rule.value.authentication.secret_name
          trigger_parameter = azure_queue_scale_rule.value.authentication.trigger_parameter
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = var.custom_scale_rules
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = lookup(custom_scale_rule.value, "authentication", [])
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.http_scale_rules
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests
      }
    }

    dynamic "tcp_scale_rule" {
      for_each = var.tcp_scale_rules
      content {
        name                = tcp_scale_rule.value.name
        concurrent_requests = tcp_scale_rule.value.concurrent_requests
      }
    }

    dynamic "init_container" {
      for_each = var.init_containers
      content {
        name    = init_container.value.name
        image   = init_container.value.image
        cpu     = lookup(init_container.value, "cpu", 0.25)
        memory  = lookup(init_container.value, "memory", "0.5Gi")
        args    = lookup(init_container.value, "args", null)
        command = lookup(init_container.value, "command", null)

        dynamic "env" {
          for_each = lookup(init_container.value, "env", [])
          content {
            name        = env.value.name
            value       = lookup(env.value, "value", null)
            secret_name = lookup(env.value, "secret_name", null)
          }
        }

        dynamic "volume_mounts" {
          for_each = lookup(init_container.value, "volume_mounts", [])
          content {
            name = volume_mounts.value.name
            path = volume_mounts.value.path
          }
        }
      }
    }
  }

  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      external_enabled           = var.ingress_external_enabled
      target_port                = var.ingress_target_port
      transport                  = var.ingress_transport
      allow_insecure_connections = var.ingress_allow_insecure_connections
      exposed_port               = var.ingress_exposed_port

      dynamic "traffic_weight" {
        for_each = var.ingress_traffic_weights
        content {
          percentage      = traffic_weight.value.percentage
          latest_revision = lookup(traffic_weight.value, "latest_revision", null)
          revision_suffix = lookup(traffic_weight.value, "revision_suffix", null)
          label           = lookup(traffic_weight.value, "label", null)
        }
      }

      dynamic "custom_domain" {
        for_each = var.custom_domains
        content {
          name                     = custom_domain.value.name
          certificate_binding_type = lookup(custom_domain.value, "certificate_binding_type", "SniEnabled")
          certificate_id           = lookup(custom_domain.value, "certificate_id", null)
        }
      }

      dynamic "ip_security_restriction" {
        for_each = var.ip_security_restrictions
        content {
          name             = ip_security_restriction.value.name
          ip_address_range = ip_security_restriction.value.ip_address_range
          action           = ip_security_restriction.value.action
          description      = lookup(ip_security_restriction.value, "description", null)
        }
      }
    }
  }

  dynamic "dapr" {
    for_each = var.dapr_enabled ? [1] : []
    content {
      app_id       = var.dapr_app_id
      app_port     = var.dapr_app_port
      app_protocol = var.dapr_app_protocol
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "registry" {
    for_each = var.registries
    content {
      server               = registry.value.server
      username             = lookup(registry.value, "username", null)
      password_secret_name = lookup(registry.value, "password_secret_name", null)
      identity             = lookup(registry.value, "identity", null)
    }
  }

  tags = var.tags
}

# Container App Environment Storage (para volumes persistentes)
resource "azurerm_container_app_environment_storage" "main" {
  for_each = nonsensitive(var.environment_storages)

  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.main.id
  account_name                 = each.value.account_name
  access_key                   = each.value.access_key
  share_name                   = each.value.share_name
  access_mode                  = each.value.access_mode
}

# Container App Environment Certificate (para custom domains)
resource "azurerm_container_app_environment_certificate" "main" {
  for_each = nonsensitive(var.certificates)

  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.main.id
  certificate_blob_base64      = each.value.certificate_blob_base64
  certificate_password         = lookup(each.value, "certificate_password", null)

  tags = var.tags
}

# Dapr Component (Service Bus, State Store, Pub/Sub, etc)
resource "azurerm_container_app_environment_dapr_component" "main" {
  for_each = var.dapr_components

  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.main.id
  component_type               = each.value.component_type
  version                      = each.value.version
  ignore_errors                = lookup(each.value, "ignore_errors", false)
  init_timeout                 = lookup(each.value, "init_timeout", "5s")
  scopes                       = lookup(each.value, "scopes", null)

  dynamic "metadata" {
    for_each = lookup(each.value, "metadata", [])
    content {
      name        = metadata.value.name
      value       = lookup(metadata.value, "value", null)
      secret_name = lookup(metadata.value, "secret_name", null)
    }
  }

  dynamic "secret" {
    for_each = lookup(each.value, "secrets", [])
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }
}
