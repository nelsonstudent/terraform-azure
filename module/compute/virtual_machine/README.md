# Azure Virtual Machine Terraform Module

Módulo Terraform para provisionar e gerenciar Azure Virtual Machines (VMs). Suporta Linux e Windows, múltiplos tamanhos de VM, data disks, extensions, backup, monitoring e configurações avançadas de rede e segurança.

## Funcionalidades

- ✅ VMs Linux e Windows
- ✅ Múltiplos tamanhos de VM (General Purpose, Compute, Memory, Storage Optimized)
- ✅ Availability Zones e Availability Sets
- ✅ Spot Instances para economia
- ✅ Managed Disks (Standard, Premium, Premium SSD v2)
- ✅ Data Disks adicionais
- ✅ Managed Identity (System e User Assigned)
- ✅ Network Security Groups
- ✅ Public IP (opcional)
- ✅ Accelerated Networking
- ✅ VM Extensions (scripts, agents, etc)
- ✅ Azure Monitor Agent
- ✅ Azure Backup integration
- ✅ Boot Diagnostics
- ✅ Custom Data (cloud-init)
- ✅ Trusted Launch (Secure Boot + vTPM)
- ✅ Disk Encryption

## Pré-requisitos

- Terraform >= 1.0
- Provider `hashicorp/azurerm` >= 3.0
- Resource Group existente
- VNet e Subnet configuradas

## Tamanhos de VM Populares

### General Purpose (B-series - Burstable)
- **Standard_B1s**: 1 vCPU, 1 GB RAM (~$9/mês) - Dev/Test
- **Standard_B2s**: 2 vCPU, 4 GB RAM (~$37/mês) - Small apps
- **Standard_B4ms**: 4 vCPU, 16 GB RAM (~$149/mês) - Medium apps

### General Purpose (D-series)
- **Standard_D2s_v3**: 2 vCPU, 8 GB RAM (~$96/mês)
- **Standard_D4s_v3**: 4 vCPU, 16 GB RAM (~$193/mês)
- **Standard_D8s_v3**: 8 vCPU, 32 GB RAM (~$385/mês)

### Compute Optimized (F-series)
- **Standard_F4s_v2**: 4 vCPU, 8 GB RAM (~$145/mês)
- **Standard_F8s_v2**: 8 vCPU, 16 GB RAM (~$291/mês)

### Memory Optimized (E-series)
- **Standard_E4s_v3**: 4 vCPU, 32 GB RAM (~$243/mês)
- **Standard_E8s_v3**: 8 vCPU, 64 GB RAM (~$486/mês)

### Storage Optimized (L-series)
- **Standard_L8s_v2**: 8 vCPU, 64 GB RAM, 1.92 TB SSD (~$496/mês)

## Uso Básico

### VM Linux Simples

```hcl
module "vm_linux" {
  source = "../../modules/compute/virtual_machine"

  resource_group_name = "rg-vms-prod"
  location            = "Brazil South"
  
  vm_name = "vm-web-prod-01"
  vm_size = "Standard_D2s_v3"
  os_type = "Linux"
  
  # Admin
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_keys = [
    file("~/.ssh/id_rsa.pub")
  ]
  
  # Network
  subnet_id = azurerm_subnet.vms.id
  
  # OS Disk
  os_disk_storage_account_type = "Premium_LRS"
  os_disk_size_gb              = 128
  
  # Image (Ubuntu 22.04)
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  tags = {
    Environment = "production"
  }
}
```

### VM Windows Server

```hcl
module "vm_windows" {
  source = "../../modules/compute/virtual_machine"

  resource_group_name = "rg-vms-prod"
  location            = "East US"
  
  vm_name = "vm-app-prod-01"
  vm_size = "Standard_D4s_v3"
  os_type = "Windows"
  
  # Admin
  admin_username = "adminuser"
  admin_password = var.admin_password  # Use Key Vault na prática
  
  # Network
  subnet_id = azurerm_subnet.vms.id
  
  # OS Disk
  os_disk_storage_account_type = "Premium_LRS"
  os_disk_size_gb              = 256
  
  # Image (Windows Server 2022)
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  
  # Windows Settings
  timezone                 = "E. South America Standard Time"
  enable_automatic_updates = true
  license_type             = "Windows_Server"  # Hybrid Benefit
  
  tags = {
    Environment = "production"
  }
}
```

### VM com Public IP e NSG

```hcl
module "vm_with_public_ip" {
  source = "../../modules/compute/virtual_machine"

  resource_group_name = "rg-vms-prod"
  location            = "Brazil South"
  
  vm_name = "vm-jumpbox-prod"
  vm_size = "Standard_B2s"
  os_type = "Linux"
  
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_keys                  = [file("~/.ssh/id_rsa.pub")]
  
  subnet_id = azurerm_subnet.dmz.id
  
  # Public IP
  create_public_ip            = true
  public_ip_allocation_method = "Static"
  public_ip_sku               = "Standard"
  
  # NSG
  create_network_security_group = true
  network_security_rules = {
    "allow-ssh" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "203.0.113.0/24"  # Office IP
      destination_address_prefix = "*"
    }
  }
  
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  tags = {
    Environment = "production"
    Role        = "jumpbox"
  }
}
```

## Exemplo Completo (Production-Ready)

```hcl
module "vm_production" {
  source = "../../modules/compute/virtual_machine"

  # Resource Group
  resource_group_name = "rg-vms-prod"
  location            = "Brazil South"
  
  # VM Configuration
  vm_name         = "vm-app-prod-01"
  vm_size         = "Standard_D8s_v3"
  os_type         = "Linux"
  availability_zone = "1"
  
  # Admin
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_keys = [
    file("~/.ssh/id_rsa.pub")
  ]
  
  # Network
  subnet_id                     = azurerm_subnet.vms.id
  private_ip_address_allocation = "Static"
  private_ip_address            = "10.0.2.10"
  enable_accelerated_networking = true
  
  # OS Disk (Premium SSD)
  os_disk_storage_account_type = "Premium_LRS"
  os_disk_size_gb              = 256
  os_disk_caching              = "ReadWrite"
  
  # Image (Ubuntu 22.04)
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  # Data Disks
  data_disks = {
    "data01" = {
      storage_account_type      = "Premium_LRS"
      create_option             = "Empty"
      disk_size_gb              = 512
      lun                       = 0
      caching                   = "ReadOnly"
      write_accelerator_enabled = false
    }
    "data02" = {
      storage_account_type = "Premium_LRS"
      create_option        = "Empty"
      disk_size_gb         = 1024
      lun                  = 1
      caching              = "None"
    }
  }
  
  # Managed Identity
  identity_type = "SystemAssigned"
  
  # Security
  encryption_at_host_enabled = true
  secure_boot_enabled        = true
  vtpm_enabled               = true
  
  # Patching
  patch_mode            = "AutomaticByPlatform"
  patch_assessment_mode = "AutomaticByPlatform"
  
  # Boot Diagnostics
  enable_boot_diagnostics = true
  
  # Custom Data (cloud-init)
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname = "vm-app-prod-01"
  }))
  
  # VM Extensions
  vm_extensions = {
    "custom-script" = {
      publisher            = "Microsoft.Azure.Extensions"
      type                 = "CustomScript"
      type_handler_version = "2.1"
      settings = jsonencode({
        script = base64encode(file("${path.module}/setup.sh"))
      })
    }
  }
  
  # Azure Monitor Agent
  enable_azure_monitor_agent = true
  
  # Backup
  enable_backup                              = true
  backup_recovery_vault_name                 = "rsv-prod"
  backup_recovery_vault_resource_group_name  = "rg-backup-prod"
  backup_policy_id                           = azurerm_backup_policy_vm.daily.id
  
  tags = {
    Environment = "production"
    Application = "webapp"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Role Assignment para acessar recursos
resource "azurerm_role_assignment" "vm_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.vm_production.vm_identity_principal_id
}
```

## Imagens Comuns

### Ubuntu
```hcl
source_image_reference = {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}
```

### Red Hat Enterprise Linux (RHEL)
```hcl
source_image_reference = {
  publisher = "RedHat"
  offer     = "RHEL"
  sku       = "9_3-gen2"
  version   = "latest"
}
```

### Windows Server 2022
```hcl
source_image_reference = {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-datacenter-azure-edition"
  version   = "latest"
}
```

### Windows 11 Pro
```hcl
source_image_reference = {
  publisher = "MicrosoftWindowsDesktop"
  offer     = "Windows-11"
  sku       = "win11-23h2-pro"
  version   = "latest"
}
```

**Listar imagens disponíveis:**
```bash
# List publishers
az vm image list-publishers --location brazilsouth --output table

# List offers
az vm image list-offers --publisher Canonical --location brazilsouth --output table

# List SKUs
az vm image list-skus --publisher Canonical --offer 0001-com-ubuntu-server-jammy --location brazilsouth --output table
```

## Cloud-Init (Linux)

### Exemplo básico (cloud-init.yaml)
```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - docker.io
  - nginx
  - git

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - systemctl enable nginx
  - systemctl start nginx

write_files:
  - path: /etc/nginx/sites-available/default
    content: |
      server {
        listen 80;
        location / {
          proxy_pass http://localhost:3000;
        }
      }

users:
  - name: appuser
    groups: docker
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
```

**Usar no Terraform:**
```hcl
custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
```

## VM Extensions

### Custom Script Extension (Linux)
```hcl
vm_extensions = {
  "install-docker" = {
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.1"
    settings = jsonencode({
      commandToExecute = "apt-get update && apt-get install -y docker.io"
    })
  }
}
```

### Custom Script Extension (Windows)
```hcl
vm_extensions = {
  "install-iis" = {
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    settings = jsonencode({
      commandToExecute = "powershell.exe Install-WindowsFeature -Name Web-Server -IncludeManagementTools"
    })
  }
}
```

### Azure AD Login Extension (Linux)
```hcl
vm_extensions = {
  "aad-login" = {
    publisher            = "Microsoft.Azure.ActiveDirectory"
    type                 = "AADSSHLoginForLinux"
    type_handler_version = "1.0"
  }
}
```

## Spot Instances (Economia)

```hcl
module "vm_spot" {
  source = "../../modules/compute/virtual_machine"

  # ... outras configurações ...
  
  priority        = "Spot"
  eviction_policy = "Deallocate"  # ou "Delete"
  max_bid_price   = -1  # Pagar até o preço on-demand
  
  # Ou definir preço máximo
  # max_bid_price = 0.05  # $0.05/hora
}
```

**Economia típica:** 60-90% vs Regular pricing

**Uso recomendado:**
- Workloads stateless
- Batch processing
- Dev/Test environments
- CI/CD workers

## Data Disks

```hcl
data_disks = {
  "database" = {
    storage_account_type = "Premium_LRS"
    create_option        = "Empty"
    disk_size_gb         = 1024
    lun                  = 0
    caching              = "ReadOnly"
  }
  "logs" = {
    storage_account_type = "StandardSSD_LRS"
    create_option        = "Empty"
    disk_size_gb         = 512
    lun                  = 1
    caching              = "None"
  }
}
```

**Montar discos no Linux:**
```bash
# Listar discos
lsblk

# Formatar
sudo mkfs.ext4 /dev/sdc

# Montar
sudo mkdir /mnt/data
sudo mount /dev/sdc /mnt/data

# Adicionar ao fstab
echo '/dev/sdc /mnt/data ext4 defaults 0 0' | sudo tee -a /etc/fstab
```

## Accelerated Networking

```hcl
enable_accelerated_networking = true
```

**Requisitos:**
- VM size deve suportar (D/E/F/M series, 2+ vCPUs)
- Melhor latência e throughput
- Suporte a DPDK

**Tamanhos que suportam:**
- Standard_D2s_v3 e maiores
- Standard_E2s_v3 e maiores
- Standard_F2s_v2 e maiores

## Managed Identity

```hcl
identity_type = "SystemAssigned"
```

**Acessar Azure resources sem credentials:**
```bash
# Get access token
TOKEN=$(curl -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" | jq -r .access_token)

# Use token to access Storage
curl -H "Authorization: Bearer $TOKEN" https://mystorageaccount.blob.core.windows.net/
```

## Azure Backup

```hcl
enable_backup                              = true
backup_recovery_vault_name                 = "rsv-prod"
backup_recovery_vault_resource_group_name  = "rg-backup"
backup_policy_id                           = azurerm_backup_policy_vm.daily.id
```

**Recovery Services Vault e Policy:**
```hcl
resource "azurerm_recovery_services_vault" "main" {
  name                = "rsv-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = "daily-backup"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}
```

## Trusted Launch (Secure Boot + vTPM)

```hcl
secure_boot_enabled = true
vtpm_enabled        = true
```

**Benefícios:**
- Secure Boot: Previne bootkit e rootkit
- vTPM: Trusted Platform Module virtual
- Attestation: Verificação de integridade

**Requisitos:**
- Gen2 VMs
- Imagens que suportam (Ubuntu 20.04+, Windows Server 2019+)

## Azure Hybrid Benefit

```hcl
# Windows
license_type = "Windows_Server"  # Ou "Windows_Client"

# Linux (RHEL/SUSE)
license_type = "RHEL_BYOS"  # Ou "SLES_BYOS"
```

**Economia:** Até 40% em Windows VMs

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| resource_group_name | Nome do Resource Group | `string` | - | Sim |
| location | Localização Azure | `string` | - | Sim |
| vm_name | Nome da VM | `string` | - | Sim |
| vm_size | Tamanho da VM | `string` | - | Sim |
| os_type | Linux ou Windows | `string` | - | Sim |
| admin_username | Username admin | `string` | - | Sim |
| subnet_id | ID da subnet | `string` | - | Sim |
| source_image_reference | Imagem source | `object` | - | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| vm_id | ID da VM |
| vm_name | Nome da VM |
| vm_private_ip_address | IP privado |
| vm_public_ip_address | IP público |
| vm_identity_principal_id | Principal ID da Managed Identity |
| ssh_connection_string | String de conexão SSH |

## Boas Práticas

### 1. **Segurança**
- ✅ Use SSH keys em vez de passwords (Linux)
- ✅ Configure NSG com regras restritivas
- ✅ Habilite Managed Identity
- ✅ Use Trusted Launch (Secure Boot + vTPM)
- ✅ Habilite encryption at host
- ✅ Não exponha VMs diretamente à internet

### 2. **Performance**
- ✅ Use Premium SSD para workloads I/O intensive
- ✅ Habilite Accelerated Networking
- ✅ Use Availability Zones para HA
- ✅ Tamanho correto de VM para workload

### 3. **Custo**
- ✅ Use Spot instances para dev/test
- ✅ Azure Hybrid Benefit para licenças existentes
- ✅ Reserved Instances para economia (1-3 anos)
- ✅ Auto-shutdown para ambientes não-prod
- ✅ Monitore utilização com Azure Advisor

### 4. **Backup e DR**
- ✅ Configure Azure Backup
- ✅ Teste restore procedures
- ✅ Use Availability Zones ou Sets
- ✅ Snapshots de disks críticos

## Troubleshooting

### VM não inicia
```bash
# Ver boot diagnostics
az vm boot-diagnostics get-boot-log --resource-group rg-vms --name vm-app-01

# Ver serial console
az serial-console connect --resource-group rg-vms --name vm-app-01
```

### Não consegue SSH
- Verificar NSG rules
- Verificar se VM tem Public IP
- Verificar se SSH key está correta
- Usar Run Command: `az vm run-command invoke`

### Performance issues
```bash
# Ver métricas
az monitor metrics list --resource /subscriptions/.../vm-app-01

# Resize VM
az vm resize --resource-group rg-vms --name vm-app-01 --size Standard_D8s_v3
```

## Referências

- [Azure VMs Documentation](https://learn.microsoft.com/azure/virtual-machines/)
- [VM Sizes](https://learn.microsoft.com/azure/virtual-machines/sizes)
- [VM Pricing](https://azure.microsoft.com/pricing/details/virtual-machines/linux/)
- [Cloud-Init](https://cloudinit.readthedocs.io/)
