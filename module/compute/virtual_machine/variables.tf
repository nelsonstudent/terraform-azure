# Resource Group
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Localização da VM"
  type        = string
}

# VM Configuration
variable "vm_name" {
  description = "Nome da Virtual Machine"
  type        = string
}

variable "vm_size" {
  description = "Tamanho da VM (ex: Standard_D2s_v3)"
  type        = string
}

variable "os_type" {
  description = "Tipo de SO: Linux ou Windows"
  type        = string

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type deve ser 'Linux' ou 'Windows'"
  }
}

variable "availability_zone" {
  description = "Availability zone (1, 2 ou 3)"
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "Lista de availability zones (para Public IP)"
  type        = list(string)
  default     = null
}

variable "availability_set_id" {
  description = "ID do Availability Set"
  type        = string
  default     = null
}

variable "proximity_placement_group_id" {
  description = "ID do Proximity Placement Group"
  type        = string
  default     = null
}

variable "priority" {
  description = "Prioridade da VM: Regular ou Spot"
  type        = string
  default     = "Regular"

  validation {
    condition     = contains(["Regular", "Spot"], var.priority)
    error_message = "priority deve ser 'Regular' ou 'Spot'"
  }
}

variable "eviction_policy" {
  description = "Política de eviction para Spot VMs: Deallocate ou Delete"
  type        = string
  default     = null

  validation {
    condition     = var.eviction_policy == null || contains(["Deallocate", "Delete"], var.eviction_policy)
    error_message = "eviction_policy deve ser 'Deallocate' ou 'Delete'"
  }
}

variable "max_bid_price" {
  description = "Preço máximo para Spot VM (-1 para preço on-demand)"
  type        = number
  default     = -1
}

# Admin Credentials
variable "admin_username" {
  description = "Username do administrador"
  type        = string
}

variable "admin_password" {
  description = "Password do administrador (obrigatório para Windows e Linux com password auth)"
  type        = string
  default     = null
  sensitive   = true
}

variable "disable_password_authentication" {
  description = "Desabilitar autenticação por senha (apenas Linux)"
  type        = bool
  default     = true
}

variable "admin_ssh_keys" {
  description = "Lista de chaves SSH públicas (apenas Linux)"
  type        = list(string)
  default     = []
}

# Source Image
variable "source_image_reference" {
  description = "Referência da imagem source"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

# OS Disk
variable "os_disk_name" {
  description = "Nome do disco do OS"
  type        = string
  default     = null
}

variable "os_disk_caching" {
  description = "Tipo de caching: None, ReadOnly, ReadWrite"
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "os_disk_caching deve ser 'None', 'ReadOnly' ou 'ReadWrite'"
  }
}

variable "os_disk_storage_account_type" {
  description = "Tipo de storage: Standard_LRS, StandardSSD_LRS, Premium_LRS, Premium_ZRS"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS", "PremiumV2_LRS"], var.os_disk_storage_account_type)
    error_message = "os_disk_storage_account_type inválido"
  }
}

variable "os_disk_size_gb" {
  description = "Tamanho do disco do OS em GB"
  type        = number
  default     = null
}

variable "os_disk_write_accelerator_enabled" {
  description = "Habilitar Write Accelerator (apenas Premium_LRS)"
  type        = bool
  default     = false
}

variable "os_disk_diff_disk_settings" {
  description = "Configurações de Ephemeral OS Disk"
  type = object({
    option    = string
    placement = optional(string)
  })
  default = null
}

variable "disk_encryption_set_id" {
  description = "ID do Disk Encryption Set"
  type        = string
  default     = null
}

# Data Disks
variable "data_disks" {
  description = "Discos de dados adicionais"
  type = map(object({
    storage_account_type      = string
    create_option             = string
    disk_size_gb              = number
    lun                       = number
    caching                   = string
    write_accelerator_enabled = optional(bool)
  }))
  default = {}
}

# Network Interface
variable "network_interface_name" {
  description = "Nome da Network Interface"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "ID da subnet"
  type        = string
}

variable "private_ip_address_allocation" {
  description = "Tipo de alocação de IP: Dynamic ou Static"
  type        = string
  default     = "Dynamic"

  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "private_ip_address_allocation deve ser 'Dynamic' ou 'Static'"
  }
}

variable "private_ip_address" {
  description = "IP privado (quando Static)"
  type        = string
  default     = null
}

variable "accelerated_networking_enabled" {
  description = "Habilitar Accelerated Networking"
  type        = bool
  default     = false
}

variable "ip_forwarding_enabled" {
  description = "Habilitar IP Forwarding"
  type        = bool
  default     = false
}

# Public IP
variable "create_public_ip" {
  description = "Criar Public IP"
  type        = bool
  default     = false
}

variable "public_ip_name" {
  description = "Nome do Public IP"
  type        = string
  default     = null
}

variable "public_ip_allocation_method" {
  description = "Método de alocação: Static ou Dynamic"
  type        = string
  default     = "Static"

  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "public_ip_allocation_method deve ser 'Static' ou 'Dynamic'"
  }
}

variable "public_ip_sku" {
  description = "SKU do Public IP: Basic ou Standard"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "public_ip_sku deve ser 'Basic' ou 'Standard'"
  }
}

# Network Security Group
variable "create_network_security_group" {
  description = "Criar Network Security Group"
  type        = bool
  default     = false
}

variable "network_security_group_name" {
  description = "Nome do Network Security Group"
  type        = string
  default     = null
}

variable "network_security_rules" {
  description = "Regras do NSG"
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    destination_port_range       = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    destination_address_prefix   = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}

# Identity
variable "identity_type" {
  description = "Tipo de identidade: SystemAssigned, UserAssigned ou SystemAssigned, UserAssigned"
  type        = string
  default     = null

  validation {
    condition = var.identity_type == null || contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned, UserAssigned"
    ], var.identity_type)
    error_message = "identity_type inválido"
  }
}

variable "identity_ids" {
  description = "IDs das User Assigned Identities"
  type        = list(string)
  default     = []
}

# Boot Diagnostics
variable "enable_boot_diagnostics" {
  description = "Habilitar boot diagnostics"
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_account_uri" {
  description = "URI da Storage Account para boot diagnostics (null para managed storage)"
  type        = string
  default     = null
}

# Patching
variable "patch_mode" {
  description = "Patch mode: AutomaticByPlatform, ImageDefault, Manual"
  type        = string
  default     = "ImageDefault"
}

variable "patch_assessment_mode" {
  description = "Patch assessment mode: AutomaticByPlatform, ImageDefault"
  type        = string
  default     = "ImageDefault"
}

variable "provision_vm_agent" {
  description = "Provisionar VM Agent"
  type        = bool
  default     = true
}

# Windows Specific
variable "enable_automatic_updates" {
  description = "Habilitar updates automáticos (apenas Windows)"
  type        = bool
  default     = true
}

variable "timezone" {
  description = "Timezone (apenas Windows)"
  type        = string
  default     = null
}

variable "license_type" {
  description = "License type: Windows_Client, Windows_Server (Hybrid Benefit)"
  type        = string
  default     = null
}

variable "winrm_listeners" {
  description = "WinRM listeners (apenas Windows)"
  type = list(object({
    protocol        = string
    certificate_url = optional(string)
  }))
  default = []
}

variable "additional_unattend_content" {
  description = "Additional unattend content (apenas Windows)"
  type = list(object({
    content = string
    setting = string
  }))
  default = []
}

# Security
variable "encryption_at_host_enabled" {
  description = "Habilitar criptografia em host"
  type        = bool
  default     = false
}

variable "secure_boot_enabled" {
  description = "Habilitar Secure Boot (Trusted Launch)"
  type        = bool
  default     = false
}

variable "vtpm_enabled" {
  description = "Habilitar vTPM (Trusted Launch)"
  type        = bool
  default     = false
}

# Custom Data
variable "custom_data" {
  description = "Custom data (cloud-init para Linux, custom script para Windows)"
  type        = string
  default     = null
  sensitive   = true
}

# Plan (para imagens do Marketplace)
variable "plan" {
  description = "Plan para imagens do Marketplace"
  type = object({
    name      = string
    product   = string
    publisher = string
  })
  default = null
}

# VM Extensions
variable "vm_extensions" {
  description = "VM Extensions"
  type = map(object({
    publisher                  = string
    type                       = string
    type_handler_version       = string
    auto_upgrade_minor_version = optional(bool)
    automatic_upgrade_enabled  = optional(bool)
    settings                   = optional(string)
    protected_settings         = optional(string)
  }))
  default = {}
}

# Azure Monitor Agent
variable "enable_azure_monitor_agent" {
  description = "Instalar Azure Monitor Agent"
  type        = bool
  default     = false
}

# Backup
variable "enable_backup" {
  description = "Habilitar Azure Backup"
  type        = bool
  default     = false
}

variable "backup_recovery_vault_name" {
  description = "Nome do Recovery Services Vault"
  type        = string
  default     = null
}

variable "backup_recovery_vault_resource_group_name" {
  description = "Resource Group do Recovery Services Vault"
  type        = string
  default     = null
}

variable "backup_policy_id" {
  description = "ID da Backup Policy"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}
