terraform {
  required_version = ">= 1.0"
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Azure DevOps Project
resource "azuredevops_project" "main" {
  name               = var.project_name
  description        = var.project_description
  visibility         = var.project_visibility
  version_control    = var.version_control
  work_item_template = var.work_item_template

  features = {
    "boards"       = var.enable_boards ? "enabled" : "disabled"
    "repositories" = var.enable_repos ? "enabled" : "disabled"
    "pipelines"    = var.enable_pipelines ? "enabled" : "disabled"
    "testplans"    = var.enable_test_plans ? "enabled" : "disabled"
    "artifacts"    = var.enable_artifacts ? "enabled" : "disabled"
  }
}

# Azure DevOps Git Repository
resource "azuredevops_git_repository" "main" {
  for_each = var.repositories

  project_id     = azuredevops_project.main.id
  name           = each.key
  default_branch = each.value.default_branch
  initialization {
    init_type = each.value.init_type
  }
}

# Service Connection to Azure Resource Manager
resource "azuredevops_serviceendpoint_azurerm" "main" {
  count = var.create_service_connection ? 1 : 0

  project_id                             = azuredevops_project.main.id
  service_endpoint_name                  = var.service_connection_name
  description                            = var.service_connection_description
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = var.service_principal_id
  }
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = var.subscription_name
}

# Build Definition (Pipeline)
resource "azuredevops_build_definition" "main" {
  for_each = var.pipelines

  project_id = azuredevops_project.main.id
  name       = each.key

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.main[each.value.repository_name].id
    branch_name = each.value.branch_name
    yml_path    = each.value.yaml_path
  }

  dynamic "variable" {
    for_each = each.value.variables
    content {
      name  = variable.key
      value = variable.value
    }
  }
}

# Variable Group
resource "azuredevops_variable_group" "main" {
  for_each = var.variable_groups

  project_id   = azuredevops_project.main.id
  name         = each.key
  description  = each.value.description
  allow_access = each.value.allow_access

  dynamic "variable" {
    for_each = each.value.variables
    content {
      name  = variable.key
      value = variable.value
    }
  }

  dynamic "key_vault" {
    for_each = each.value.key_vault_name != null ? [1] : []
    content {
      name                = each.value.key_vault_name
      service_endpoint_id = azuredevops_serviceendpoint_azurerm.main[0].id
    }
  }
}

# Branch Policy - Require Pull Request Reviews
resource "azuredevops_branch_policy_min_reviewers" "main" {
  for_each = var.branch_policies

  project_id = azuredevops_project.main.id

  enabled  = true
  blocking = each.value.blocking

  settings {
    reviewer_count                         = each.value.minimum_reviewers
    submitter_can_vote                     = each.value.submitter_can_vote
    last_pusher_cannot_approve             = each.value.last_pusher_cannot_approve
    allow_completion_with_rejects_or_waits = each.value.allow_completion_with_rejects
    on_push_reset_approved_votes           = each.value.reset_votes_on_push

    scope {
      repository_id  = azuredevops_git_repository.main[each.value.repository_name].id
      repository_ref = each.value.branch_name
      match_type     = "Exact"
    }
  }
}

# Branch Policy - Build Validation
resource "azuredevops_branch_policy_build_validation" "main" {
  for_each = var.build_validation_policies

  project_id = azuredevops_project.main.id

  enabled  = true
  blocking = each.value.blocking

  settings {
    display_name        = each.value.display_name
    build_definition_id = azuredevops_build_definition.main[each.value.pipeline_name].id
    valid_duration      = each.value.valid_duration
    filename_patterns   = each.value.filename_patterns

    scope {
      repository_id  = azuredevops_git_repository.main[each.value.repository_name].id
      repository_ref = each.value.branch_name
      match_type     = "Exact"
    }
  }
}

# Environment
resource "azuredevops_environment" "main" {
  for_each = var.environments

  project_id  = azuredevops_project.main.id
  name        = each.key
  description = each.value.description
}

# Team
resource "azuredevops_team" "main" {
  for_each = var.teams

  project_id   = azuredevops_project.main.id
  name         = each.key
  description  = each.value.description
  administrators = each.value.administrators
  members        = each.value.members
}
