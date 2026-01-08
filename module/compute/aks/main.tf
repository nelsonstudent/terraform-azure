terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "main" {
  name                              = var.cluster_name
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  dns_prefix                          = var.dns_prefix
  dns_prefix_private_cluster          = var.dns_prefix_private_cluster
  kubernetes_version                  = var.kubernetes_version
  automatic_upgrade_channel           = var.automatic_upgrade_channel
  sku_tier                            = var.sku_tier
  private_cluster_enabled             = var.private_cluster_enabled
  private_dns_zone_id                 = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  node_resource_group                 = var.node_resource_group
  role_based_access_control_enabled   = var.role_based_access_control_enabled
  local_account_disabled              = var.local_account_disabled
  run_command_enabled                 = var.run_command_enabled
  azure_policy_enabled                = var.azure_policy_enabled
  http_application_routing_enabled    = var.http_application_routing_enabled
  oidc_issuer_enabled                 = var.oidc_issuer_enabled
  workload_identity_enabled           = var.workload_identity_enabled
  open_service_mesh_enabled           = var.open_service_mesh_enabled
  image_cleaner_enabled               = var.image_cleaner_enabled
  image_cleaner_interval_hours        = var.image_cleaner_interval_hours

  # Default Node Pool
  default_node_pool {
    name                         = var.default_node_pool_name
    vm_size                      = var.default_node_pool_vm_size
    node_count                   = var.default_node_pool_enable_auto_scaling ? null : var.default_node_pool_node_count
    auto_scaling_enabled         = var.default_node_pool_enable_auto_scaling
    min_count                    = var.default_node_pool_enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count                    = var.default_node_pool_enable_auto_scaling ? var.default_node_pool_max_count : null
    max_pods                     = var.default_node_pool_max_pods
    os_disk_size_gb              = var.default_node_pool_os_disk_size_gb
    os_disk_type                 = var.default_node_pool_os_disk_type
    vnet_subnet_id               = var.default_node_pool_vnet_subnet_id
    pod_subnet_id                = var.default_node_pool_pod_subnet_id
    host_encryption_enabled      = var.default_node_pool_enable_host_encryption
    node_public_ip_enabled       = var.default_node_pool_enable_node_public_ip
    zones                        = var.default_node_pool_availability_zones
    only_critical_addons_enabled = var.default_node_pool_only_critical_addons
    orchestrator_version         = var.default_node_pool_orchestrator_version
    os_sku                       = var.default_node_pool_os_sku
    type                         = "VirtualMachineScaleSets"
    tags                         = merge(var.tags, var.default_node_pool_tags)

    dynamic "kubelet_config" {
      for_each = var.default_node_pool_kubelet_config != null ? [var.default_node_pool_kubelet_config] : []
      content {
        cpu_manager_policy        = lookup(kubelet_config.value, "cpu_manager_policy", null)
        cpu_cfs_quota_enabled     = lookup(kubelet_config.value, "cpu_cfs_quota_enabled", null)
        cpu_cfs_quota_period      = lookup(kubelet_config.value, "cpu_cfs_quota_period", null)
        image_gc_high_threshold   = lookup(kubelet_config.value, "image_gc_high_threshold", null)
        image_gc_low_threshold    = lookup(kubelet_config.value, "image_gc_low_threshold", null)
        topology_manager_policy   = lookup(kubelet_config.value, "topology_manager_policy", null)
        allowed_unsafe_sysctls    = lookup(kubelet_config.value, "allowed_unsafe_sysctls", null)
        container_log_max_size_mb = lookup(kubelet_config.value, "container_log_max_size_mb", null)
        container_log_max_line    = lookup(kubelet_config.value, "container_log_max_line", null)
        pod_max_pid               = lookup(kubelet_config.value, "pod_max_pid", null)
      }
    }

    dynamic "linux_os_config" {
      for_each = var.default_node_pool_linux_os_config != null ? [var.default_node_pool_linux_os_config] : []
      content {
        swap_file_size_mb = lookup(linux_os_config.value, "swap_file_size_mb", null)

        dynamic "sysctl_config" {
          for_each = lookup(linux_os_config.value, "sysctl_config", null) != null ? [linux_os_config.value.sysctl_config] : []
          content {
            fs_aio_max_nr                      = lookup(sysctl_config.value, "fs_aio_max_nr", null)
            fs_file_max                        = lookup(sysctl_config.value, "fs_file_max", null)
            fs_inotify_max_user_watches        = lookup(sysctl_config.value, "fs_inotify_max_user_watches", null)
            fs_nr_open                         = lookup(sysctl_config.value, "fs_nr_open", null)
            kernel_threads_max                 = lookup(sysctl_config.value, "kernel_threads_max", null)
            net_core_netdev_max_backlog        = lookup(sysctl_config.value, "net_core_netdev_max_backlog", null)
            net_core_optmem_max                = lookup(sysctl_config.value, "net_core_optmem_max", null)
            net_core_rmem_default              = lookup(sysctl_config.value, "net_core_rmem_default", null)
            net_core_rmem_max                  = lookup(sysctl_config.value, "net_core_rmem_max", null)
            net_core_somaxconn                 = lookup(sysctl_config.value, "net_core_somaxconn", null)
            net_core_wmem_default              = lookup(sysctl_config.value, "net_core_wmem_default", null)
            net_core_wmem_max                  = lookup(sysctl_config.value, "net_core_wmem_max", null)
            net_ipv4_ip_local_port_range_max   = lookup(sysctl_config.value, "net_ipv4_ip_local_port_range_max", null)
            net_ipv4_ip_local_port_range_min   = lookup(sysctl_config.value, "net_ipv4_ip_local_port_range_min", null)
            net_ipv4_neigh_default_gc_thresh1  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh1", null)
            net_ipv4_neigh_default_gc_thresh2  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh2", null)
            net_ipv4_neigh_default_gc_thresh3  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh3", null)
            net_ipv4_tcp_fin_timeout           = lookup(sysctl_config.value, "net_ipv4_tcp_fin_timeout", null)
            net_ipv4_tcp_keepalive_intvl       = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_intvl", null)
            net_ipv4_tcp_keepalive_probes      = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_probes", null)
            net_ipv4_tcp_keepalive_time        = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_time", null)
            net_ipv4_tcp_max_syn_backlog       = lookup(sysctl_config.value, "net_ipv4_tcp_max_syn_backlog", null)
            net_ipv4_tcp_max_tw_buckets        = lookup(sysctl_config.value, "net_ipv4_tcp_max_tw_buckets", null)
            net_ipv4_tcp_tw_reuse              = lookup(sysctl_config.value, "net_ipv4_tcp_tw_reuse", null)
            net_netfilter_nf_conntrack_buckets = lookup(sysctl_config.value, "net_netfilter_nf_conntrack_buckets", null)
            net_netfilter_nf_conntrack_max     = lookup(sysctl_config.value, "net_netfilter_nf_conntrack_max", null)
            vm_max_map_count                   = lookup(sysctl_config.value, "vm_max_map_count", null)
            vm_swappiness                      = lookup(sysctl_config.value, "vm_swappiness", null)
            vm_vfs_cache_pressure              = lookup(sysctl_config.value, "vm_vfs_cache_pressure", null)
          }
        }
      }
    }

    dynamic "upgrade_settings" {
      for_each = var.default_node_pool_upgrade_settings != null ? [var.default_node_pool_upgrade_settings] : []
      content {
        max_surge = upgrade_settings.value.max_surge
      }
    }
  }

  # Network Profile
  network_profile {
    network_plugin      = var.network_plugin
    network_mode        = var.network_mode
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    pod_cidr            = var.pod_cidr
    outbound_type       = var.outbound_type
    load_balancer_sku   = var.load_balancer_sku
    network_plugin_mode = var.network_plugin_mode

    dynamic "load_balancer_profile" {
      for_each = var.load_balancer_profile != null ? [var.load_balancer_profile] : []
      content {
        managed_outbound_ip_count   = lookup(load_balancer_profile.value, "managed_outbound_ip_count", null)
        outbound_ip_address_ids     = lookup(load_balancer_profile.value, "outbound_ip_address_ids", null)
        outbound_ip_prefix_ids      = lookup(load_balancer_profile.value, "outbound_ip_prefix_ids", null)
        outbound_ports_allocated    = lookup(load_balancer_profile.value, "outbound_ports_allocated", null)
        idle_timeout_in_minutes     = lookup(load_balancer_profile.value, "idle_timeout_in_minutes", null)
      }
    }
  }

  # Identity
  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
  }

  # Azure Active Directory (Entra ID) Integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_ad_rbac_enabled ? [1] : []
    content {
      tenant_id              = var.azure_ad_rbac_tenant_id
      admin_group_object_ids = var.azure_ad_rbac_admin_group_object_ids
      azure_rbac_enabled     = var.azure_ad_rbac_azure_rbac_enabled
    }
  }

  # API Server Access Profile

  dynamic "api_server_access_profile" {
    for_each = var.api_server_authorized_ip_ranges != null ? [1] : []
    content {
      authorized_ip_ranges     = var.api_server_authorized_ip_ranges
    }
  }

  # Auto Scaler Profile
  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []
    content {
      balance_similar_node_groups      = lookup(auto_scaler_profile.value, "balance_similar_node_groups", null)
      expander                         = lookup(auto_scaler_profile.value, "expander", null)
      max_graceful_termination_sec     = lookup(auto_scaler_profile.value, "max_graceful_termination_sec", null)
      max_node_provisioning_time       = lookup(auto_scaler_profile.value, "max_node_provisioning_time", null)
      max_unready_nodes                = lookup(auto_scaler_profile.value, "max_unready_nodes", null)
      max_unready_percentage           = lookup(auto_scaler_profile.value, "max_unready_percentage", null)
      new_pod_scale_up_delay           = lookup(auto_scaler_profile.value, "new_pod_scale_up_delay", null)
      scale_down_delay_after_add       = lookup(auto_scaler_profile.value, "scale_down_delay_after_add", null)
      scale_down_delay_after_delete    = lookup(auto_scaler_profile.value, "scale_down_delay_after_delete", null)
      scale_down_delay_after_failure   = lookup(auto_scaler_profile.value, "scale_down_delay_after_failure", null)
      scan_interval                    = lookup(auto_scaler_profile.value, "scan_interval", null)
      scale_down_unneeded              = lookup(auto_scaler_profile.value, "scale_down_unneeded", null)
      scale_down_unready               = lookup(auto_scaler_profile.value, "scale_down_unready", null)
      scale_down_utilization_threshold = lookup(auto_scaler_profile.value, "scale_down_utilization_threshold", null)
      empty_bulk_delete_max            = lookup(auto_scaler_profile.value, "empty_bulk_delete_max", null)
      skip_nodes_with_local_storage    = lookup(auto_scaler_profile.value, "skip_nodes_with_local_storage", null)
      skip_nodes_with_system_pods      = lookup(auto_scaler_profile.value, "skip_nodes_with_system_pods", null)
    }
  }

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []
    content {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  # Microsoft Defender
  dynamic "microsoft_defender" {
    for_each = var.microsoft_defender_enabled ? [1] : []
    content {
      log_analytics_workspace_id = var.microsoft_defender_log_analytics_workspace_id
    }
  }

  # OMS Agent (Azure Monitor)
  dynamic "oms_agent" {
    for_each = var.oms_agent_enabled ? [1] : []
    content {
      log_analytics_workspace_id      = var.oms_agent_log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = var.oms_agent_msi_auth_enabled
    }
  }

  # Ingress Application Gateway
  dynamic "ingress_application_gateway" {
    for_each = var.ingress_application_gateway_enabled ? [1] : []
    content {
      gateway_id   = var.ingress_application_gateway_id
      gateway_name = var.ingress_application_gateway_name
      subnet_cidr  = var.ingress_application_gateway_subnet_cidr
      subnet_id    = var.ingress_application_gateway_subnet_id
    }
  }

  # Kubelet Identity
  dynamic "kubelet_identity" {
    for_each = var.kubelet_identity != null ? [var.kubelet_identity] : []
    content {
      client_id                 = lookup(kubelet_identity.value, "client_id", null)
      object_id                 = lookup(kubelet_identity.value, "object_id", null)
      user_assigned_identity_id = lookup(kubelet_identity.value, "user_assigned_identity_id", null)
    }
  }

  # Linux Profile
  dynamic "linux_profile" {
    for_each = var.linux_profile != null ? [var.linux_profile] : []
    content {
      admin_username = linux_profile.value.admin_username

      ssh_key {
        key_data = linux_profile.value.ssh_key
      }
    }
  }

  # Windows Profile
  dynamic "windows_profile" {
    for_each = var.windows_profile != null ? [var.windows_profile] : []
    content {
      admin_username = windows_profile.value.admin_username
      admin_password = windows_profile.value.admin_password
      license        = lookup(windows_profile.value, "license", null)

      dynamic "gmsa" {
        for_each = lookup(windows_profile.value, "gmsa", null) != null ? [windows_profile.value.gmsa] : []
        content {
          dns_server  = gmsa.value.dns_server
          root_domain = gmsa.value.root_domain
        }
      }
    }
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = lookup(maintenance_window.value, "allowed", [])
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }

      dynamic "not_allowed" {
        for_each = lookup(maintenance_window.value, "not_allowed", [])
        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  # Maintenance Window Auto Upgrade
  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window_auto_upgrade != null ? [var.maintenance_window_auto_upgrade] : []
    content {
      frequency    = maintenance_window_auto_upgrade.value.frequency
      interval     = maintenance_window_auto_upgrade.value.interval
      duration     = maintenance_window_auto_upgrade.value.duration
      day_of_week  = lookup(maintenance_window_auto_upgrade.value, "day_of_week", null)
      day_of_month = lookup(maintenance_window_auto_upgrade.value, "day_of_month", null)
      week_index   = lookup(maintenance_window_auto_upgrade.value, "week_index", null)
      start_time   = lookup(maintenance_window_auto_upgrade.value, "start_time", null)
      utc_offset   = lookup(maintenance_window_auto_upgrade.value, "utc_offset", null)
      start_date   = lookup(maintenance_window_auto_upgrade.value, "start_date", null)

      dynamic "not_allowed" {
        for_each = lookup(maintenance_window_auto_upgrade.value, "not_allowed", [])
        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  # Storage Profile
  dynamic "storage_profile" {
    for_each = var.storage_profile != null ? [var.storage_profile] : []
    content {
      blob_driver_enabled         = lookup(storage_profile.value, "blob_driver_enabled", null)
      disk_driver_enabled         = lookup(storage_profile.value, "disk_driver_enabled", null)
      file_driver_enabled         = lookup(storage_profile.value, "file_driver_enabled", null)
      snapshot_controller_enabled = lookup(storage_profile.value, "snapshot_controller_enabled", null)
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                   = each.key
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.main.id
  vm_size                = each.value.vm_size
  node_count             = each.value.enable_auto_scaling ? null : each.value.node_count
  auto_scaling_enabled   = each.value.enable_auto_scaling
  min_count              = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count              = each.value.enable_auto_scaling ? each.value.max_count : null
  max_pods               = lookup(each.value, "max_pods", null)
  os_disk_size_gb        = lookup(each.value, "os_disk_size_gb", null)
  os_disk_type           = lookup(each.value, "os_disk_type", "Managed")
  os_type                = lookup(each.value, "os_type", "Linux")
  os_sku                 = lookup(each.value, "os_sku", null)
  vnet_subnet_id         = lookup(each.value, "vnet_subnet_id", null)
  pod_subnet_id          = lookup(each.value, "pod_subnet_id", null)
  host_encryption_enabled = lookup(each.value, "enable_host_encryption", false)
  node_public_ip_enabled  = lookup(each.value, "enable_node_public_ip", false)
  zones                  = lookup(each.value, "availability_zones", null)
  orchestrator_version   = lookup(each.value, "orchestrator_version", null)
  mode                   = lookup(each.value, "mode", "User")
  priority               = lookup(each.value, "priority", "Regular")
  spot_max_price         = lookup(each.value, "spot_max_price", null)
  eviction_policy        = lookup(each.value, "eviction_policy", null)
  node_labels            = lookup(each.value, "node_labels", null)
  node_taints            = lookup(each.value, "node_taints", null)
  tags                   = merge(var.tags, lookup(each.value, "tags", {}))

  dynamic "kubelet_config" {
    for_each = lookup(each.value, "kubelet_config", null) != null ? [each.value.kubelet_config] : []
    content {
      cpu_manager_policy        = lookup(kubelet_config.value, "cpu_manager_policy", null)
      cpu_cfs_quota_enabled     = lookup(kubelet_config.value, "cpu_cfs_quota_enabled", null)
      cpu_cfs_quota_period      = lookup(kubelet_config.value, "cpu_cfs_quota_period", null)
      image_gc_high_threshold   = lookup(kubelet_config.value, "image_gc_high_threshold", null)
      image_gc_low_threshold    = lookup(kubelet_config.value, "image_gc_low_threshold", null)
      topology_manager_policy   = lookup(kubelet_config.value, "topology_manager_policy", null)
      allowed_unsafe_sysctls    = lookup(kubelet_config.value, "allowed_unsafe_sysctls", null)
      container_log_max_size_mb = lookup(kubelet_config.value, "container_log_max_size_mb", null)
      container_log_max_line   = lookup(kubelet_config.value, "container_log_max_line", null)
      pod_max_pid               = lookup(kubelet_config.value, "pod_max_pid", null)
    }
  }

  dynamic "linux_os_config" {
    for_each = lookup(each.value, "linux_os_config", null) != null ? [each.value.linux_os_config] : []
    content {
      swap_file_size_mb = lookup(linux_os_config.value, "swap_file_size_mb", null)

      dynamic "sysctl_config" {
        for_each = lookup(linux_os_config.value, "sysctl_config", null) != null ? [linux_os_config.value.sysctl_config] : []
        content {
          fs_aio_max_nr                      = lookup(sysctl_config.value, "fs_aio_max_nr", null)
          fs_file_max                        = lookup(sysctl_config.value, "fs_file_max", null)
          fs_inotify_max_user_watches        = lookup(sysctl_config.value, "fs_inotify_max_user_watches", null)
          fs_nr_open                         = lookup(sysctl_config.value, "fs_nr_open", null)
          kernel_threads_max                 = lookup(sysctl_config.value, "kernel_threads_max", null)
          net_core_netdev_max_backlog        = lookup(sysctl_config.value, "net_core_netdev_max_backlog", null)
          net_core_optmem_max                = lookup(sysctl_config.value, "net_core_optmem_max", null)
          net_core_rmem_default              = lookup(sysctl_config.value, "net_core_rmem_default", null)
          net_core_rmem_max                  = lookup(sysctl_config.value, "net_core_rmem_max", null)
          net_core_somaxconn                 = lookup(sysctl_config.value, "net_core_somaxconn", null)
          net_core_wmem_default              = lookup(sysctl_config.value, "net_core_wmem_default", null)
          net_core_wmem_max                  = lookup(sysctl_config.value, "net_core_wmem_max", null)
          net_ipv4_ip_local_port_range_max   = lookup(sysctl_config.value, "net_ipv4_ip_local_port_range_max", null)
          net_ipv4_ip_local_port_range_min   = lookup(sysctl_config.value, "net_ipv4_ip_local_port_range_min", null)
          net_ipv4_neigh_default_gc_thresh1  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh1", null)
          net_ipv4_neigh_default_gc_thresh2  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh2", null)
          net_ipv4_neigh_default_gc_thresh3  = lookup(sysctl_config.value, "net_ipv4_neigh_default_gc_thresh3", null)
          net_ipv4_tcp_fin_timeout           = lookup(sysctl_config.value, "net_ipv4_tcp_fin_timeout", null)
          net_ipv4_tcp_keepalive_intvl       = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_intvl", null)
          net_ipv4_tcp_keepalive_probes      = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_probes", null)
          net_ipv4_tcp_keepalive_time        = lookup(sysctl_config.value, "net_ipv4_tcp_keepalive_time", null)
          net_ipv4_tcp_max_syn_backlog       = lookup(sysctl_config.value, "net_ipv4_tcp_max_syn_backlog", null)
          net_ipv4_tcp_max_tw_buckets        = lookup(sysctl_config.value, "net_ipv4_tcp_max_tw_buckets", null)
          net_ipv4_tcp_tw_reuse              = lookup(sysctl_config.value, "net_ipv4_tcp_tw_reuse", null)
          net_netfilter_nf_conntrack_buckets = lookup(sysctl_config.value, "net_netfilter_nf_conntrack_buckets", null)
          net_netfilter_nf_conntrack_max     = lookup(sysctl_config.value, "net_netfilter_nf_conntrack_max", null)
          vm_max_map_count                   = lookup(sysctl_config.value, "vm_max_map_count", null)
          vm_swappiness                      = lookup(sysctl_config.value, "vm_swappiness", null)
          vm_vfs_cache_pressure              = lookup(sysctl_config.value, "vm_vfs_cache_pressure", null)
        }
      }
    }
  }

  dynamic "upgrade_settings" {
    for_each = lookup(each.value, "upgrade_settings", null) != null ? [each.value.upgrade_settings] : []
    content {
      max_surge = upgrade_settings.value.max_surge
    }
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
