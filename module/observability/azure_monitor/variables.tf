# Log Analytics Workspace
variable "create_log_analytics_workspace" {
  description = "Criar Log Analytics Workspace"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "Nome do Log Analytics Workspace"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização do Azure"
  type        = string
}

variable "log_analytics_sku" {
  description = "SKU do Log Analytics (Free, PerGB2018, PerNode, Premium, Standalone, Unlimited)"
  type        = string
  default     = "PerGB2018"
  
  validation {
    condition     = contains(["Free", "PerGB2018", "PerNode", "Premium", "Standalone", "Unlimited"], var.log_analytics_sku)
    error_message = "SKU deve ser um dos valores válidos."
  }
}

variable "log_analytics_retention_days" {
  description = "Dias de retenção de logs (30-730)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retenção deve estar entre 30 e 730 dias."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Quota diária em GB (-1 para ilimitado)"
  type        = number
  default     = -1
}

variable "log_analytics_internet_ingestion_enabled" {
  description = "Habilitar ingestão via internet"
  type        = bool
  default     = true
}

variable "log_analytics_internet_query_enabled" {
  description = "Habilitar queries via internet"
  type        = bool
  default     = true
}

variable "log_analytics_reservation_capacity_in_gb_per_day" {
  description = "Capacidade de reserva em GB por dia"
  type        = number
  default     = null
}

# Application Insights
variable "create_application_insights" {
  description = "Criar Application Insights"
  type        = bool
  default     = false
}

variable "application_insights" {
  description = "Lista de Application Insights a serem criados"
  type = list(object({
    name                                  = string
    application_type                      = string  # web, other, java, MobileCenter, Node.JS, phone, store, ios
    sampling_percentage                   = optional(number, 100)
    disable_ip_masking                    = optional(bool, false)
    local_authentication_disabled         = optional(bool, false)
    internet_ingestion_enabled            = optional(bool, true)
    internet_query_enabled                = optional(bool, true)
    force_customer_storage_for_profiler   = optional(bool, false)
  }))
  default = []
}

# Action Groups
variable "action_groups" {
  description = "Lista de Action Groups para alertas"
  type = list(object({
    name       = string
    short_name = string
    enabled    = optional(bool, true)
    
    email_receiver = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), [])
    
    sms_receiver = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    
    webhook_receiver = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
    })), [])
    
    azure_app_push_receiver = optional(list(object({
      name          = string
      email_address = string
    })), [])
    
    azure_function_receiver = optional(list(object({
      name                     = string
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
      use_common_alert_schema  = optional(bool, true)
    })), [])
    
    logic_app_receiver = optional(list(object({
      name                    = string
      resource_id             = string
      callback_url            = string
      use_common_alert_schema = optional(bool, true)
    })), [])
  }))
  default = []
}

# Metric Alerts
variable "metric_alerts" {
  description = "Lista de Metric Alerts"
  type = list(object({
    name                = string
    description         = optional(string)
    enabled             = optional(bool, true)
    auto_mitigate       = optional(bool, true)
    severity            = optional(number, 3)
    frequency           = optional(string, "PT5M")
    window_size         = optional(string, "PT5M")
    scopes              = list(string)
    target_resource_type = optional(string)
    
    criteria = list(object({
      metric_namespace = string
      metric_name      = string
      aggregation      = string
      operator         = string
      threshold        = number
      
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])
    }))
    
    dynamic_criteria = optional(list(object({
      metric_namespace         = string
      metric_name              = string
      aggregation              = string
      operator                 = string
      alert_sensitivity        = string
      evaluation_total_count   = optional(number, 4)
      evaluation_failure_count = optional(number, 4)
      
      dimension = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])
    })), [])
    
    action_group_ids = list(string)
  }))
  default = []
}

# Log Analytics Queries (Scheduled Query Rules)
variable "scheduled_query_rules" {
  description = "Lista de Scheduled Query Rules"
  type = list(object({
    name                = string
    description         = optional(string)
    enabled             = optional(bool, true)
    severity            = optional(number, 3)
    frequency           = string
    time_window         = string
    query               = string
    
    trigger = object({
      operator  = string
      threshold = number
      
      metric_trigger = optional(object({
        operator            = string
        threshold           = number
        metric_trigger_type = string
        metric_column       = string
      }))
    })
    
    action_group_ids = list(string)
  }))
  default = []
}

# Activity Log Alerts
variable "activity_log_alerts" {
  description = "Lista de Activity Log Alerts"
  type = list(object({
    name        = string
    description = optional(string)
    enabled     = optional(bool, true)
    scopes      = list(string)
    
    criteria = object({
      category        = string
      operation_name  = optional(string)
      resource_group  = optional(string)
      resource_type   = optional(string)
      resource_id     = optional(string)
      caller          = optional(string)
      level           = optional(string)
      status          = optional(string)
      sub_status      = optional(string)
    })
    
    action_group_ids = list(string)
  }))
  default = []
}

# Data Collection Rules
variable "data_collection_rules" {
  description = "Lista de Data Collection Rules"
  type = list(object({
    name        = string
    description = optional(string)
    
    destinations = object({
      log_analytics = optional(list(object({
        workspace_resource_id = string
        name                  = string
      })), [])
      
      azure_monitor_metrics = optional(object({
        name = string
      }))
    })
    
    data_flow = list(object({
      streams      = list(string)
      destinations = list(string)
    }))
    
    data_sources = object({
      performance_counter = optional(list(object({
        name                          = string
        streams                       = list(string)
        sampling_frequency_in_seconds = number
        counter_specifiers            = list(string)
      })), [])
      
      windows_event_log = optional(list(object({
        name           = string
        streams        = list(string)
        x_path_queries = list(string)
      })), [])
      
      syslog = optional(list(object({
        name           = string
        streams        = list(string)
        facility_names = list(string)
        log_levels     = list(string)
      })), [])
    })
  }))
  default = []
}

# Workbooks
variable "workbooks" {
  description = "Lista de Workbooks"
  type = list(object({
    name         = string
    display_name = string
    description  = optional(string)
    category     = optional(string, "workbook")
    
    serialized_data = string
    
    source_id = optional(string)
  }))
  default = []
}

# Diagnostic Settings for Resources
variable "diagnostic_settings" {
  description = "Lista de Diagnostic Settings para recursos"
  type = list(object({
    name               = string
    target_resource_id = string
    
    enabled_log = optional(list(object({
      category = string
    })), [])
    
    metric = optional(list(object({
      category = string
      enabled  = optional(bool, true)
    })), [])
  }))
  default = []
}

# Smart Detection Rules (Application Insights)
variable "smart_detection_rules" {
  description = "Configuração de Smart Detection Rules"
  type = list(object({
    application_insights_name = string
    name                      = string
    enabled                   = bool
    send_emails_to_subscription_owners = optional(bool, true)
    additional_email_recipients = optional(list(string), [])
  }))
  default = []
}

# Autoscale Settings
variable "autoscale_settings" {
  description = "Lista de Autoscale Settings"
  type = list(object({
    name               = string
    target_resource_id = string
    enabled            = optional(bool, true)
    
    profile = list(object({
      name = string
      
      capacity = object({
        default = number
        minimum = number
        maximum = number
      })
      
      rule = optional(list(object({
        metric_trigger = object({
          metric_name        = string
          metric_resource_id = string
          time_grain         = string
          statistic          = string
          time_window        = string
          time_aggregation   = string
          operator           = string
          threshold          = number
        })
        
        scale_action = object({
          direction = string
          type      = string
          value     = string
          cooldown  = string
        })
      })), [])
      
      fixed_date = optional(object({
        timezone = string
        start    = string
        end      = string
      }))
      
      recurrence = optional(object({
        timezone = string
        days     = list(string)
        hours    = list(number)
        minutes  = list(number)
      }))
    }))
    
    notification = optional(object({
      email = optional(object({
        send_to_subscription_administrator    = optional(bool, false)
        send_to_subscription_co_administrator = optional(bool, false)
        custom_emails                         = optional(list(string), [])
      }))
      
      webhook = optional(list(object({
        service_uri = string
        properties  = optional(map(string), {})
      })), [])
    }))
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}