terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Public IP (opcional)
resource "azurerm_public_ip" "main" {
  count = var.create_public_ip ? 1 : 0

  name                = var.public_ip_name != null ? var.public_ip_name : "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  zones               = var.availability_zones

  tags = var.tags
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = var.network_interface_name != null ? var.network_interface_name : "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.main[0].id : null
  }

  accelerated_networking_enabled = var.accelerated_networking_enabled
  ip_forwarding_enabled          = var.ip_forwarding_enabled

  tags = var.tags
}

# Network Security Group (opcional)
resource "azurerm_network_security_group" "main" {
  count = var.create_network_security_group ? 1 : 0

  name                = var.network_security_group_name != null ? var.network_security_group_name : "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# NSG Rules
resource "azurerm_network_security_rule" "main" {
  for_each = var.create_network_security_group ? var.network_security_rules : {}

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = lookup(each.value, "source_port_range", null)
  destination_port_range      = lookup(each.value, "destination_port_range", null)
  source_port_ranges          = lookup(each.value, "source_port_ranges", null)
  destination_port_ranges     = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix       = lookup(each.value, "source_address_prefix", null)
  destination_address_prefix  = lookup(each.value, "destination_address_prefix", null)
  source_address_prefixes     = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

# NSG Association
resource "azurerm_network_interface_security_group_association" "main" {
  count = var.create_network_security_group ? 1 : 0

  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  count = var.os_type == "Linux" ? 1 : 0

  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = var.disable_password_authentication
  admin_password                  = var.disable_password_authentication ? null : var.admin_password
  network_interface_ids           = [azurerm_network_interface.main.id]
  zone                            = var.availability_zone
  availability_set_id             = var.availability_set_id
  proximity_placement_group_id    = var.proximity_placement_group_id
  priority                        = var.priority
  eviction_policy                 = var.eviction_policy
  max_bid_price                   = var.max_bid_price
  patch_mode                      = var.patch_mode
  patch_assessment_mode           = var.patch_assessment_mode
  provision_vm_agent              = var.provision_vm_agent
  encryption_at_host_enabled      = var.encryption_at_host_enabled
  secure_boot_enabled             = var.secure_boot_enabled
  vtpm_enabled                    = var.vtpm_enabled

  os_disk {
    name                      = var.os_disk_name != null ? var.os_disk_name : "${var.vm_name}-osdisk"
    caching                   = var.os_disk_caching
    storage_account_type      = var.os_disk_storage_account_type
    disk_size_gb              = var.os_disk_size_gb
    write_accelerator_enabled = var.os_disk_write_accelerator_enabled
    disk_encryption_set_id    = var.disk_encryption_set_id

    dynamic "diff_disk_settings" {
      for_each = var.os_disk_diff_disk_settings != null ? [var.os_disk_diff_disk_settings] : []
      content {
        option    = diff_disk_settings.value.option
        placement = lookup(diff_disk_settings.value, "placement", null)
      }
    }
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication ? var.admin_ssh_keys : []
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  dynamic "plan" {
    for_each = var.plan != null ? [var.plan] : []
    content {
      name      = plan.value.name
      product   = plan.value.product
      publisher = plan.value.publisher
    }
  }

  custom_data = var.custom_data

  tags = var.tags

  lifecycle {
    ignore_changes = [
      admin_password,
      custom_data
    ]
  }
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  count = var.os_type == "Windows" ? 1 : 0

  name                     = var.vm_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  size                     = var.vm_size
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  network_interface_ids    = [azurerm_network_interface.main.id]
  zone                     = var.availability_zone
  availability_set_id      = var.availability_set_id
  proximity_placement_group_id = var.proximity_placement_group_id
  priority                 = var.priority
  eviction_policy          = var.eviction_policy
  max_bid_price            = var.max_bid_price
  patch_mode               = var.patch_mode
  patch_assessment_mode    = var.patch_assessment_mode
  provision_vm_agent       = var.provision_vm_agent
  enable_automatic_updates = var.enable_automatic_updates
  timezone                 = var.timezone
  license_type             = var.license_type
  encryption_at_host_enabled = var.encryption_at_host_enabled
  secure_boot_enabled      = var.secure_boot_enabled
  vtpm_enabled             = var.vtpm_enabled

  os_disk {
    name                      = var.os_disk_name != null ? var.os_disk_name : "${var.vm_name}-osdisk"
    caching                   = var.os_disk_caching
    storage_account_type      = var.os_disk_storage_account_type
    disk_size_gb              = var.os_disk_size_gb
    write_accelerator_enabled = var.os_disk_write_accelerator_enabled
    disk_encryption_set_id    = var.disk_encryption_set_id

    dynamic "diff_disk_settings" {
      for_each = var.os_disk_diff_disk_settings != null ? [var.os_disk_diff_disk_settings] : []
      content {
        option    = diff_disk_settings.value.option
        placement = lookup(diff_disk_settings.value, "placement", null)
      }
    }
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  dynamic "plan" {
    for_each = var.plan != null ? [var.plan] : []
    content {
      name      = plan.value.name
      product   = plan.value.product
      publisher = plan.value.publisher
    }
  }

  dynamic "winrm_listener" {
    for_each = var.winrm_listeners
    content {
      protocol        = winrm_listener.value.protocol
      certificate_url = lookup(winrm_listener.value, "certificate_url", null)
    }
  }

  dynamic "additional_unattend_content" {
    for_each = var.additional_unattend_content
    content {
      content = additional_unattend_content.value.content
      setting = additional_unattend_content.value.setting
    }
  }

  custom_data = var.custom_data

  tags = var.tags

  lifecycle {
    ignore_changes = [
      admin_password,
      custom_data
    ]
  }
}

# Data Disks
resource "azurerm_managed_disk" "data" {
  for_each = var.data_disks

  name                 = each.key
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb
  zone                 = var.availability_zone
  disk_encryption_set_id = var.disk_encryption_set_id

  tags = var.tags
}

# Data Disk Attachments
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = var.data_disks

  managed_disk_id           = azurerm_managed_disk.data[each.key].id
  virtual_machine_id        = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].id : azurerm_windows_virtual_machine.main[0].id
  lun                       = each.value.lun
  caching                   = each.value.caching
  write_accelerator_enabled = lookup(each.value, "write_accelerator_enabled", false)
}

# VM Extensions
resource "azurerm_virtual_machine_extension" "main" {
  for_each = var.vm_extensions

  name                       = each.key
  virtual_machine_id         = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].id : azurerm_windows_virtual_machine.main[0].id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.type_handler_version
  auto_upgrade_minor_version = lookup(each.value, "auto_upgrade_minor_version", true)
  automatic_upgrade_enabled  = lookup(each.value, "automatic_upgrade_enabled", false)
  settings                   = lookup(each.value, "settings", null)
  protected_settings         = lookup(each.value, "protected_settings", null)

  tags = var.tags
}

# Backup (Azure Backup)
resource "azurerm_backup_protected_vm" "main" {
  count = var.enable_backup ? 1 : 0

  resource_group_name = var.backup_recovery_vault_resource_group_name
  recovery_vault_name = var.backup_recovery_vault_name
  source_vm_id        = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].id : azurerm_windows_virtual_machine.main[0].id
  backup_policy_id    = var.backup_policy_id
}

# Azure Monitor Agent Extension (Linux)
resource "azurerm_virtual_machine_extension" "azure_monitor_linux" {
  count = var.os_type == "Linux" && var.enable_azure_monitor_agent ? 1 : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  tags = var.tags
}

# Azure Monitor Agent Extension (Windows)
resource "azurerm_virtual_machine_extension" "azure_monitor_windows" {
  count = var.os_type == "Windows" && var.enable_azure_monitor_agent ? 1 : 0

  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.main[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  tags = var.tags
}
