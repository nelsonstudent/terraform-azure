output "id" {
  description = "ID da DNS Zone"
  value       = local.zone_id
}

output "name" {
  description = "Nome da DNS Zone"
  value       = local.zone_name
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = var.resource_group_name
}

output "zone_type" {
  description = "Tipo da zona (Public ou Private)"
  value       = var.create_public_zone ? "Public" : "Private"
}

# Public DNS Zone Outputs
output "public_zone_id" {
  description = "ID da Public DNS Zone"
  value       = var.create_public_zone ? azurerm_dns_zone.public[0].id : null
}

output "public_zone_name" {
  description = "Nome da Public DNS Zone"
  value       = var.create_public_zone ? azurerm_dns_zone.public[0].name : null
}

output "name_servers" {
  description = "Lista de name servers da Public DNS Zone"
  value       = var.create_public_zone ? azurerm_dns_zone.public[0].name_servers : []
}

output "number_of_record_sets" {
  description = "Número de record sets na Public DNS Zone"
  value       = var.create_public_zone ? azurerm_dns_zone.public[0].number_of_record_sets : null
}

output "max_number_of_record_sets" {
  description = "Número máximo de record sets permitidos na Public DNS Zone"
  value       = var.create_public_zone ? azurerm_dns_zone.public[0].max_number_of_record_sets : null
}

# Private DNS Zone Outputs
output "private_zone_id" {
  description = "ID da Private DNS Zone"
  value       = var.create_private_zone ? azurerm_private_dns_zone.private[0].id : null
}

output "private_zone_name" {
  description = "Nome da Private DNS Zone"
  value       = var.create_private_zone ? azurerm_private_dns_zone.private[0].name : null
}

output "max_number_of_virtual_network_links" {
  description = "Número máximo de VNet links na Private DNS Zone"
  value       = var.create_private_zone ? azurerm_private_dns_zone.private[0].max_number_of_virtual_network_links : null
}

output "max_number_of_virtual_network_links_with_registration" {
  description = "Número máximo de VNet links com auto-registro"
  value       = var.create_private_zone ? azurerm_private_dns_zone.private[0].max_number_of_virtual_network_links_with_registration : null
}

# VNet Links
output "vnet_links" {
  description = "Informações dos VNet links (Private DNS)"
  value = {
    for link in var.vnet_links :
    link.name => {
      id                   = var.create_private_zone ? azurerm_private_dns_zone_virtual_network_link.links[link.name].id : null
      name                 = link.name
      virtual_network_id   = link.virtual_network_id
      registration_enabled = link.registration_enabled
    }
  }
}

# A Records
output "a_records" {
  description = "Informações dos registros A"
  value = merge(
    {
      for record in var.a_records :
      record.name => {
        id      = var.create_public_zone ? azurerm_dns_a_record.public_a[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_public_zone ? azurerm_dns_a_record.public_a[record.name].fqdn : null
      }
      if var.create_public_zone
    },
    {
      for record in var.a_records :
      record.name => {
        id      = var.create_private_zone ? azurerm_private_dns_a_record.private_a[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_private_zone ? azurerm_private_dns_a_record.private_a[record.name].fqdn : null
      }
      if var.create_private_zone
    }
  )
}

# AAAA Records
output "aaaa_records" {
  description = "Informações dos registros AAAA"
  value = merge(
    {
      for record in var.aaaa_records :
      record.name => {
        id      = var.create_public_zone ? azurerm_dns_aaaa_record.public_aaaa[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_public_zone ? azurerm_dns_aaaa_record.public_aaaa[record.name].fqdn : null
      }
      if var.create_public_zone
    },
    {
      for record in var.aaaa_records :
      record.name => {
        id      = var.create_private_zone ? azurerm_private_dns_aaaa_record.private_aaaa[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_private_zone ? azurerm_private_dns_aaaa_record.private_aaaa[record.name].fqdn : null
      }
      if var.create_private_zone
    }
  )
}

# CNAME Records
output "cname_records" {
  description = "Informações dos registros CNAME"
  value = merge(
    {
      for record in var.cname_records :
      record.name => {
        id     = var.create_public_zone ? azurerm_dns_cname_record.public_cname[record.name].id : null
        name   = record.name
        ttl    = record.ttl
        record = record.record
        fqdn   = var.create_public_zone ? azurerm_dns_cname_record.public_cname[record.name].fqdn : null
      }
      if var.create_public_zone
    },
    {
      for record in var.cname_records :
      record.name => {
        id     = var.create_private_zone ? azurerm_private_dns_cname_record.private_cname[record.name].id : null
        name   = record.name
        ttl    = record.ttl
        record = record.record
        fqdn   = var.create_private_zone ? azurerm_private_dns_cname_record.private_cname[record.name].fqdn : null
      }
      if var.create_private_zone
    }
  )
}

# MX Records
output "mx_records" {
  description = "Informações dos registros MX"
  value = merge(
    {
      for record in var.mx_records :
      record.name => {
        id      = var.create_public_zone ? azurerm_dns_mx_record.public_mx[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_public_zone ? azurerm_dns_mx_record.public_mx[record.name].fqdn : null
      }
      if var.create_public_zone
    },
    {
      for record in var.mx_records :
      record.name => {
        id      = var.create_private_zone ? azurerm_private_dns_mx_record.private_mx[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_private_zone ? azurerm_private_dns_mx_record.private_mx[record.name].fqdn : null
      }
      if var.create_private_zone
    }
  )
}

# TXT Records
output "txt_records" {
  description = "Informações dos registros TXT"
  value = merge(
    {
      for record in var.txt_records :
      record.name => {
        id      = var.create_public_zone ? azurerm_dns_txt_record.public_txt[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_public_zone ? azurerm_dns_txt_record.public_txt[record.name].fqdn : null
      }
      if var.create_public_zone
    },
    {
      for record in var.txt_records :
      record.name => {
        id      = var.create_private_zone ? azurerm_private_dns_txt_record.private_txt[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_private_zone ? azurerm_private_dns_txt_record.private_txt[record.name].fqdn : null
      }
      if var.create_private_zone
    }
  )
}

# SRV Records
output "srv_records" {
  description = "Informações dos registros SRV"
  value = merge(
    {
      for record in var.srv_records :
      record.name => {
        id      = var.create_public_zone ? azurerm_dns_srv_record.public_srv[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_public_zone ? azurerm_dns_srv_record.public_srv[record.name].fqdn : null
      }
      if var.create_public_zone
    },
    {
      for record in var.srv_records :
      record.name => {
        id      = var.create_private_zone ? azurerm_private_dns_srv_record.private_srv[record.name].id : null
        name    = record.name
        ttl     = record.ttl
        records = record.records
        fqdn    = var.create_private_zone ? azurerm_private_dns_srv_record.private_srv[record.name].fqdn : null
      }
      if var.create_private_zone
    }
  )
}

# CAA Records (Public only)
output "caa_records" {
  description = "Informações dos registros CAA"
  value = {
    for record in var.caa_records :
    record.name => {
      id      = var.create_public_zone ? azurerm_dns_caa_record.public_caa[record.name].id : null
      name    = record.name
      ttl     = record.ttl
      records = record.records
      fqdn    = var.create_public_zone ? azurerm_dns_caa_record.public_caa[record.name].fqdn : null
    }
    if var.create_public_zone
  }
}

# Traffic Manager Records
output "traffic_manager_records" {
  description = "Informações dos registros Traffic Manager"
  value = {
    for record in var.traffic_manager_records :
    record.name => {
      id                 = var.create_public_zone && var.create_traffic_manager_records ? azurerm_dns_cname_record.traffic_manager[record.name].id : null
      name               = record.name
      ttl                = record.ttl
      traffic_manager_fqdn = record.traffic_manager_fqdn
      fqdn               = var.create_public_zone && var.create_traffic_manager_records ? azurerm_dns_cname_record.traffic_manager[record.name].fqdn : null
    }
    if var.create_public_zone && var.create_traffic_manager_records
  }
}

# Azure Service Records
output "azure_service_records" {
  description = "Informações dos registros de serviços Azure (Private Link)"
  value = {
    for record in var.azure_service_records :
    record.name => {
      id         = var.create_private_zone && var.create_azure_service_records ? azurerm_private_dns_a_record.azure_services[record.name].id : null
      name       = record.name
      ttl        = record.ttl
      ip_address = record.ip_address
      fqdn       = var.create_private_zone && var.create_azure_service_records ? azurerm_private_dns_a_record.azure_services[record.name].fqdn : null
    }
    if var.create_private_zone && var.create_azure_service_records
  }
}

# Summary
output "zone_summary" {
  description = "Resumo das informações da DNS Zone"
  value = {
    id                  = local.zone_id
    name                = local.zone_name
    type                = var.create_public_zone ? "Public" : "Private"
    name_servers        = var.create_public_zone ? azurerm_dns_zone.public[0].name_servers : []
    a_records_count     = length(var.a_records)
    aaaa_records_count  = length(var.aaaa_records)
    cname_records_count = length(var.cname_records)
    mx_records_count    = length(var.mx_records)
    txt_records_count   = length(var.txt_records)
    srv_records_count   = length(var.srv_records)
    caa_records_count   = length(var.caa_records)
    vnet_links_count    = var.create_private_zone ? length(var.vnet_links) : 0
  }
}

# Lists for easy reference
output "record_names" {
  description = "Lista de todos os nomes de registros"
  value = distinct(concat(
    [for r in var.a_records : r.name],
    [for r in var.aaaa_records : r.name],
    [for r in var.cname_records : r.name],
    [for r in var.mx_records : r.name],
    [for r in var.txt_records : r.name],
    [for r in var.srv_records : r.name]
  ))
}

output "a_record_names" {
  description = "Lista de nomes dos registros A"
  value       = [for r in var.a_records : r.name]
}

output "cname_record_names" {
  description = "Lista de nomes dos registros CNAME"
  value       = [for r in var.cname_records : r.name]
}