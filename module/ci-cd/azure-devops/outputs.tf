# Project Outputs
output "project_id" {
  description = "ID do projeto Azure DevOps"
  value       = azuredevops_project.main.id
}

output "project_name" {
  description = "Nome do projeto Azure DevOps"
  value       = azuredevops_project.main.name
}

output "project_url" {
  description = "URL do projeto Azure DevOps"
  value       = azuredevops_project.main.process_template_id
}

# Repository Outputs
output "repository_ids" {
  description = "Mapa de IDs dos repositórios criados"
  value       = { for k, v in azuredevops_git_repository.main : k => v.id }
}

output "repository_urls" {
  description = "Mapa de URLs dos repositórios criados"
  value       = { for k, v in azuredevops_git_repository.main : k => v.url }
}

output "repository_default_branches" {
  description = "Mapa de branches padrão dos repositórios"
  value       = { for k, v in azuredevops_git_repository.main : k => v.default_branch }
}

output "repository_ssh_urls" {
  description = "Mapa de URLs SSH dos repositórios"
  value       = { for k, v in azuredevops_git_repository.main : k => v.ssh_url }
}

output "repository_web_urls" {
  description = "Mapa de URLs web dos repositórios"
  value       = { for k, v in azuredevops_git_repository.main : k => v.web_url }
}

# Service Connection Outputs
output "service_connection_id" {
  description = "ID da service connection Azure Resource Manager"
  value       = var.create_service_connection ? azuredevops_serviceendpoint_azurerm.main[0].id : null
}

output "service_connection_name" {
  description = "Nome da service connection"
  value       = var.create_service_connection ? azuredevops_serviceendpoint_azurerm.main[0].service_endpoint_name : null
}

# Pipeline Outputs
output "pipeline_ids" {
  description = "Mapa de IDs dos pipelines criados"
  value       = { for k, v in azuredevops_build_definition.main : k => v.id }
}

output "pipeline_names" {
  description = "Mapa de nomes dos pipelines"
  value       = { for k, v in azuredevops_build_definition.main : k => v.name }
}

output "pipeline_urls" {
  description = "Mapa de URLs dos pipelines"
  value       = { for k, v in azuredevops_build_definition.main : k => "https://dev.azure.com/${azuredevops_project.main.name}/_build?definitionId=${v.id}" }
}

# Variable Group Outputs
output "variable_group_ids" {
  description = "Mapa de IDs dos variable groups criados"
  value       = { for k, v in azuredevops_variable_group.main : k => v.id }
}

output "variable_group_names" {
  description = "Mapa de nomes dos variable groups"
  value       = { for k, v in azuredevops_variable_group.main : k => v.name }
}

# Environment Outputs
output "environment_ids" {
  description = "Mapa de IDs dos ambientes criados"
  value       = { for k, v in azuredevops_environment.main : k => v.id }
}

output "environment_names" {
  description = "Mapa de nomes dos ambientes"
  value       = { for k, v in azuredevops_environment.main : k => v.name }
}

# Team Outputs
output "team_ids" {
  description = "Mapa de IDs dos times criados"
  value       = { for k, v in azuredevops_team.main : k => v.id }
}

output "team_names" {
  description = "Mapa de nomes dos times"
  value       = { for k, v in azuredevops_team.main : k => v.name }
}

output "team_descriptors" {
  description = "Mapa de descriptors dos times (para permissões)"
  value       = { for k, v in azuredevops_team.main : k => v.descriptor }
}

# Branch Policy Outputs
output "branch_policy_ids" {
  description = "Mapa de IDs das políticas de branch"
  value       = { for k, v in azuredevops_branch_policy_min_reviewers.main : k => v.id }
}

output "build_validation_policy_ids" {
  description = "Mapa de IDs das políticas de validação de build"
  value       = { for k, v in azuredevops_branch_policy_build_validation.main : k => v.id }
}

# Complete Project Info
output "project_info" {
  description = "Informações completas do projeto"
  value = {
    id                 = azuredevops_project.main.id
    name               = azuredevops_project.main.name
    visibility         = azuredevops_project.main.visibility
    version_control    = azuredevops_project.main.version_control
    work_item_template = azuredevops_project.main.work_item_template
    features = {
      boards     = var.enable_boards
      repos      = var.enable_repos
      pipelines  = var.enable_pipelines
      test_plans = var.enable_test_plans
      artifacts  = var.enable_artifacts
    }
  }
}
