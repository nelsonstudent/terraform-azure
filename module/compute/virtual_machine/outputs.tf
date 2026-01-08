# VM Outputs
output "vm_id" {
  description = "ID da Virtual Machine"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].id : azurerm_windows_virtual_machine.main[0].id
}

output "vm_name" {
  description = "Nome da Virtual Machine"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].name : azurerm_windows_virtual_machine.main[0].name
}

output "vm_private_ip_address" {
  description = "Endereço IP privado da VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vm_private_ip_addresses" {
  description = "Lista de endereços IP privados"
  value       = azurerm_network_interface.main.private_ip_addresses
}

output "vm_public_ip_address" {
  description = "Endereço IP público da VM"
  value       = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "vm_public_ip_id" {
  description = "ID do Public IP"
  value       = var.create_public_ip ? azurerm_public_ip.main[0].id : null
}

output "vm_public_ip_fqdn" {
  description = "FQDN do Public IP"
  value       = var.create_public_ip ? azurerm_public_ip.main[0].fqdn : null
}

# Network Interface Outputs
output "network_interface_id" {
  description = "ID da Network Interface"
  value       = azurerm_network_interface.main.id
}

output "network_interface_name" {
  description = "Nome da Network Interface"
  value       = azurerm_network_interface.main.name
}

output "network_interface_private_ip_address" {
  description = "IP privado da Network Interface"
  value       = azurerm_network_interface.main.private_ip_address
}

output "network_interface_mac_address" {
  description = "MAC Address da Network Interface"
  value       = azurerm_network_interface.main.mac_address
}

# Network Security Group Outputs
output "network_security_group_id" {
  description = "ID do Network Security Group"
  value       = var.create_network_security_group ? azurerm_network_security_group.main[0].id : null
}

output "network_security_group_name" {
  description = "Nome do Network Security Group"
  value       = var.create_network_security_group ? azurerm_network_security_group.main[0].name : null
}

# Identity Outputs
output "vm_identity_principal_id" {
  description = "Principal ID da Managed Identity"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].identity[0].principal_id : azurerm_windows_virtual_machine.main[0].identity[0].principal_id) : null
}

output "vm_identity_tenant_id" {
  description = "Tenant ID da Managed Identity"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].identity[0].tenant_id : azurerm_windows_virtual_machine.main[0].identity[0].tenant_id) : null
}

output "vm_identity" {
  description = "Objeto completo de identidade"
  value       = var.identity_type != null ? (var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].identity : azurerm_windows_virtual_machine.main[0].identity) : null
}

# OS Disk Outputs
output "os_disk_id" {
  description = "ID do disco do OS"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].os_disk[0].name : azurerm_windows_virtual_machine.main[0].os_disk[0].name
}

output "os_disk_size_gb" {
  description = "Tamanho do disco do OS em GB"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].os_disk[0].disk_size_gb : azurerm_windows_virtual_machine.main[0].os_disk[0].disk_size_gb
}

# Data Disk Outputs
output "data_disk_ids" {
  description = "IDs dos data disks"
  value       = { for k, v in azurerm_managed_disk.data : k => v.id }
}

output "data_disk_names" {
  description = "Nomes dos data disks"
  value       = { for k, v in azurerm_managed_disk.data : k => v.name }
}

# VM Extension Outputs
output "vm_extension_ids" {
  description = "IDs das VM Extensions"
  value       = { for k, v in azurerm_virtual_machine_extension.main : k => v.id }
}

output "vm_extension_names" {
  description = "Nomes das VM Extensions"
  value       = { for k, v in azurerm_virtual_machine_extension.main : k => v.name }
}

# Complete VM Info
output "vm_info" {
  description = "Informações completas da VM"
  value = {
    id                  = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].id : azurerm_windows_virtual_machine.main[0].id
    name                = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].name : azurerm_windows_virtual_machine.main[0].name
    location            = var.location
    resource_group      = var.resource_group_name
    size                = var.vm_size
    os_type             = var.os_type
    private_ip_address  = azurerm_network_interface.main.private_ip_address
    public_ip_address   = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : null
    availability_zone   = var.availability_zone
    priority            = var.priority
    identity_enabled    = var.identity_type != null
  }
}

# Connection Info
output "ssh_connection_string" {
  description = "String de conexão SSH (apenas Linux)"
  value       = var.os_type == "Linux" && var.create_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : null
}

output "rdp_connection_string" {
  description = "Informações para conexão RDP (apenas Windows)"
  value       = var.os_type == "Windows" && var.create_public_ip ? "mstsc /v:${azurerm_public_ip.main[0].ip_address}" : null
}

# Computer Name
output "computer_name" {
  description = "Nome do computador"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].computer_name : azurerm_windows_virtual_machine.main[0].computer_name
}

# Virtual Machine ID (Azure resource ID)
output "virtual_machine_id" {
  description = "Azure Resource ID da VM"
  value       = var.os_type == "Linux" ? azurerm_linux_virtual_machine.main[0].virtual_machine_id : azurerm_windows_virtual_machine.main[0].virtual_machine_id
}
