terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  count = var.create_log_analytics_workspace ? 1 : 0

  name                               = var.log_analytics_workspace_name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  sku                                = var.log_analytics_sku
  retention_in_days                  = var.log_analytics_retention_days
  daily_quota_gb                     = var.log_analytics_daily_quota_gb
  internet_ingestion_enabled         = var.log_analytics_internet_ingestion_enabled
  internet_query_enabled             = var.log_analytics_internet_query_enabled
  reservation_capacity_in_gb_per_day = var.log_analytics_reservation_capacity_in_gb_per_day

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Application Insights
resource "azurerm_application_insights" "apps" {
  for_each = { for app in var.application_insights : app.name => app }

  name                                  = each.value.name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  workspace_id                          = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : null
  application_type                      = each.value.application_type
  sampling_percentage                   = each.value.sampling_percentage
  disable_ip_masking                    = each.value.disable_ip_masking
  local_authentication_disabled         = each.value.local_authentication_disabled
  internet_ingestion_enabled            = each.value.internet_ingestion_enabled
  internet_query_enabled                = each.value.internet_query_enabled
  force_customer_storage_for_profiler   = each.value.force_customer_storage_for_profiler

  tags = var.tags
}

# Action Groups
resource "azurerm_monitor_action_group" "groups" {
  for_each = { for ag in var.action_groups : ag.name => ag }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  short_name          = each.value.short_name
  enabled             = each.value.enabled

  # Email Receivers
  dynamic "email_receiver" {
    for_each = each.value.email_receiver
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  # SMS Receivers
  dynamic "sms_receiver" {
    for_each = each.value.sms_receiver
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  # Webhook Receivers
  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receiver
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
  }

  # Azure App Push Receivers
  dynamic "azure_app_push_receiver" {
    for_each = each.value.azure_app_push_receiver
    content {
      name          = azure_app_push_receiver.value.name
      email_address = azure_app_push_receiver.value.email_address
    }
  }

  # Azure Function Receivers
  dynamic "azure_function_receiver" {
    for_each = each.value.azure_function_receiver
    content {
      name                     = azure_function_receiver.value.name
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name            = azure_function_receiver.value.function_name
      http_trigger_url         = azure_function_receiver.value.http_trigger_url
      use_common_alert_schema  = azure_function_receiver.value.use_common_alert_schema
    }
  }

  # Logic App Receivers
  dynamic "logic_app_receiver" {
    for_each = each.value.logic_app_receiver
    content {
      name                    = logic_app_receiver.value.name
      resource_id             = logic_app_receiver.value.resource_id
      callback_url            = logic_app_receiver.value.callback_url
      use_common_alert_schema = logic_app_receiver.value.use_common_alert_schema
    }
  }

  tags = var.tags
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "alerts" {
  for_each = { for alert in var.metric_alerts : alert.name => alert }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  description         = each.value.description
  enabled             = each.value.enabled
  auto_mitigate       = each.value.auto_mitigate
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  scopes              = each.value.scopes
  target_resource_type = each.value.target_resource_type

  # Static Criteria
  dynamic "criteria" {
    for_each = each.value.criteria
    content {
      metric_namespace = criteria.value.metric_namespace
      metric_name      = criteria.value.metric_name
      aggregation      = criteria.value.aggregation
      operator         = criteria.value.operator
      threshold        = criteria.value.threshold

      dynamic "dimension" {
        for_each = criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  # Dynamic Criteria
  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criteria
    content {
      metric_namespace         = dynamic_criteria.value.metric_namespace
      metric_name              = dynamic_criteria.value.metric_name
      aggregation              = dynamic_criteria.value.aggregation
      operator                 = dynamic_criteria.value.operator
      alert_sensitivity        = dynamic_criteria.value.alert_sensitivity
      evaluation_total_count   = dynamic_criteria.value.evaluation_total_count
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count

      dynamic "dimension" {
        for_each = dynamic_criteria.value.dimension
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Scheduled Query Rules (Log Analytics Alerts)
resource "azurerm_monitor_scheduled_query_rules_alert" "queries" {
  for_each = { for query in var.scheduled_query_rules : query.name => query }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  description         = each.value.description
  enabled             = each.value.enabled
  severity            = each.value.severity
  frequency           = each.value.frequency
  time_window         = each.value.time_window
  query               = each.value.query
  data_source_id      = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : null

  trigger {
    operator  = each.value.trigger.operator
    threshold = each.value.trigger.threshold

    dynamic "metric_trigger" {
      for_each = each.value.trigger.metric_trigger != null ? [each.value.trigger.metric_trigger] : []
      content {
        operator            = metric_trigger.value.operator
        threshold           = metric_trigger.value.threshold
        metric_trigger_type = metric_trigger.value.metric_trigger_type
        metric_column       = metric_trigger.value.metric_column
      }
    }
  }

  action {
    action_group = each.value.action_group_ids
  }

  tags = var.tags
}

# Activity Log Alerts
resource "azurerm_monitor_activity_log_alert" "activity_alerts" {
  for_each = { for alert in var.activity_log_alerts : alert.name => alert }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  description         = each.value.description
  enabled             = each.value.enabled
  scopes              = each.value.scopes

  criteria {
    category        = each.value.criteria.category
    operation_name  = each.value.criteria.operation_name
    resource_group  = each.value.criteria.resource_group
    resource_type   = each.value.criteria.resource_type
    resource_id     = each.value.criteria.resource_id
    caller          = each.value.criteria.caller
    level           = each.value.criteria.level
    status          = each.value.criteria.status
    sub_status      = each.value.criteria.sub_status
  }

  dynamic "action" {
    for_each = each.value.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Data Collection Rules
resource "azurerm_monitor_data_collection_rule" "rules" {
  for_each = { for rule in var.data_collection_rules : rule.name => rule }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = each.value.description

  destinations {
    dynamic "log_analytics" {
      for_each = each.value.destinations.log_analytics
      content {
        workspace_resource_id = log_analytics.value.workspace_resource_id
        name                  = log_analytics.value.name
      }
    }

    dynamic "azure_monitor_metrics" {
      for_each = each.value.destinations.azure_monitor_metrics != null ? [each.value.destinations.azure_monitor_metrics] : []
      content {
        name = azure_monitor_metrics.value.name
      }
    }
  }

  dynamic "data_flow" {
    for_each = each.value.data_flow
    content {
      streams      = data_flow.value.streams
      destinations = data_flow.value.destinations
    }
  }

  data_sources {
    dynamic "performance_counter" {
      for_each = each.value.data_sources.performance_counter
      content {
        name                          = performance_counter.value.name
        streams                       = performance_counter.value.streams
        sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
        counter_specifiers            = performance_counter.value.counter_specifiers
      }
    }

    dynamic "windows_event_log" {
      for_each = each.value.data_sources.windows_event_log
      content {
        name           = windows_event_log.value.name
        streams        = windows_event_log.value.streams
        x_path_queries = windows_event_log.value.x_path_queries
      }
    }

    dynamic "syslog" {
      for_each = each.value.data_sources.syslog
      content {
        name           = syslog.value.name
        streams        = syslog.value.streams
        facility_names = syslog.value.facility_names
        log_levels     = syslog.value.log_levels
      }
    }
  }

  tags = var.tags
}

# Workbooks
resource "azurerm_application_insights_workbook" "workbooks" {
  for_each = { for wb in var.workbooks : wb.name => wb }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = each.value.display_name
  data_json           = each.value.serialized_data
  description         = each.value.description
  source_id           = each.value.source_id != null ? each.value.source_id : var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : null

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "settings" {
  for_each = { for ds in var.diagnostic_settings : ds.name => ds }

  name                       = each.value.name
  target_resource_id         = each.value.target_resource_id
  log_analytics_workspace_id = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : null

  dynamic "enabled_log" {
    for_each = each.value.enabled_log
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = each.value.metric
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}

# Smart Detection Rules
resource "azurerm_application_insights_smart_detection_rule" "rules" {
  for_each = { for rule in var.smart_detection_rules : "${rule.application_insights_name}-${rule.name}" => rule }

  name                               = each.value.name
  application_insights_id            = azurerm_application_insights.apps[each.value.application_insights_name].id
  enabled                            = each.value.enabled
  send_emails_to_subscription_owners = each.value.send_emails_to_subscription_owners
  additional_email_recipients        = each.value.additional_email_recipients
}

# Autoscale Settings
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  for_each = { for as in var.autoscale_settings : as.name => as }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = each.value.target_resource_id
  enabled             = each.value.enabled

  dynamic "profile" {
    for_each = each.value.profile
    content {
      name = profile.value.name

      capacity {
        default = profile.value.capacity.default
        minimum = profile.value.capacity.minimum
        maximum = profile.value.capacity.maximum
      }

      dynamic "rule" {
        for_each = profile.value.rule
        content {
          metric_trigger {
            metric_name        = rule.value.metric_trigger.metric_name
            metric_resource_id = rule.value.metric_trigger.metric_resource_id
            time_grain         = rule.value.metric_trigger.time_grain
            statistic          = rule.value.metric_trigger.statistic
            time_window        = rule.value.metric_trigger.time_window
            time_aggregation   = rule.value.metric_trigger.time_aggregation
            operator           = rule.value.metric_trigger.operator
            threshold          = rule.value.metric_trigger.threshold
          }

          scale_action {
            direction = rule.value.scale_action.direction
            type      = rule.value.scale_action.type
            value     = rule.value.scale_action.value
            cooldown  = rule.value.scale_action.cooldown
          }
        }
      }

      dynamic "fixed_date" {
        for_each = profile.value.fixed_date != null ? [profile.value.fixed_date] : []
        content {
          timezone = fixed_date.value.timezone
          start    = fixed_date.value.start
          end      = fixed_date.value.end
        }
      }

      dynamic "recurrence" {
        for_each = profile.value.recurrence != null ? [profile.value.recurrence] : []
        content {
          timezone = recurrence.value.timezone
          days     = recurrence.value.days
          hours    = recurrence.value.hours
          minutes  = recurrence.value.minutes
        }
      }
    }
  }

  dynamic "notification" {
    for_each = each.value.notification != null ? [each.value.notification] : []
    content {
      dynamic "email" {
        for_each = notification.value.email != null ? [notification.value.email] : []
        content {
          send_to_subscription_administrator    = email.value.send_to_subscription_administrator
          send_to_subscription_co_administrator = email.value.send_to_subscription_co_administrator
          custom_emails                         = email.value.custom_emails
        }
      }

      dynamic "webhook" {
        for_each = notification.value.webhook
        content {
          service_uri = webhook.value.service_uri
          properties  = webhook.value.properties
        }
      }
    }
  }

  tags = var.tags
}

# Locals
locals {
  log_analytics_workspace_id = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : null
  
  action_group_ids = {
    for name, ag in azurerm_monitor_action_group.groups : name => ag.id
  }
  
  application_insights_ids = {
    for name, app in azurerm_application_insights.apps : name => app.id
  }
}
