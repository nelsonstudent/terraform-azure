terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_application_insights" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_type
  workspace_id        = var.workspace_id

  retention_in_days                     = var.retention_in_days
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  sampling_percentage                   = var.sampling_percentage
  disable_ip_masking                    = var.disable_ip_masking
  local_authentication_disabled         = var.local_authentication_disabled
  internet_ingestion_enabled            = var.internet_ingestion_enabled
  internet_query_enabled                = var.internet_query_enabled

  tags = var.tags
}

# Smart Detection Rules - Failure Anomalies
resource "azurerm_application_insights_smart_detection_rule" "failure_anomalies" {
  count = var.enable_smart_detection ? 1 : 0

  name                    = "Failure Anomalies - ${var.name}"
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = true

  dynamic "action_group" {
    for_each = var.action_group_ids
    content {
      action_group_id = action_group.value
    }
  }
}

# Smart Detection Rules - Slow Page Load Time
resource "azurerm_application_insights_smart_detection_rule" "slow_page_load" {
  count = var.enable_smart_detection ? 1 : 0

  name                    = "Slow page load time"
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = true

  dynamic "action_group" {
    for_each = var.action_group_ids
    content {
      action_group_id = action_group.value
    }
  }
}

# Smart Detection Rules - Slow Server Response Time
resource "azurerm_application_insights_smart_detection_rule" "slow_server_response" {
  count = var.enable_smart_detection ? 1 : 0

  name                    = "Slow server response time"
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = true

  dynamic "action_group" {
    for_each = var.action_group_ids
    content {
      action_group_id = action_group.value
    }
  }
}

# Smart Detection Rules - Degradation in Server Response Time
resource "azurerm_application_insights_smart_detection_rule" "degradation_server_response" {
  count = var.enable_smart_detection ? 1 : 0

  name                    = "Degradation in server response time"
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = true

  dynamic "action_group" {
    for_each = var.action_group_ids
    content {
      action_group_id = action_group.value
    }
  }
}

# Smart Detection Rules - Potential Memory Leak
resource "azurerm_application_insights_smart_detection_rule" "memory_leak" {
  count = var.enable_smart_detection ? 1 : 0

  name                    = "Potential memory leak detected"
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = true

  dynamic "action_group" {
    for_each = var.action_group_ids
    content {
      action_group_id = action_group.value
    }
  }
}

# Smart Detection Rules - Abnormal Rise in Exception Volume
resource "azurerm_application_insights_smart_detection_rule" "exception_volume" {
  count = var.enable_smart_detection ? 1 : 0

  name                    = "Abnormal rise in exception volume"
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = true

  dynamic "action_group" {
    for_each = var.action_group_ids
    content {
      action_group_id = action_group.value
    }
  }
}

# Smart Detection Rules - Potential Security Issue
resource "azurerm_application_insights_smart_detection_rule" "security_issue" {
  count = var.enable_smart_detection ? 1 : 0

  name                    = "Potential security issue detected"
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = true

  dynamic "action_group" {
    for_each = var.action_group_ids
    content {
      action_group_id = action_group.value
    }
  }
}
