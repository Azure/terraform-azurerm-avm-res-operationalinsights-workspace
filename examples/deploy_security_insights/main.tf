terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.3.0"
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  max = length(local.azure_regions) - 1
  min = 0
}

# This is required for resource modules
resource "azapi_resource" "rg" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

# This is the module call
module "log_analytics_workspace" {
  source = "../../"

  location            = azapi_resource.rg.location
  name                = "thislaworkspace"
  resource_group_name = azapi_resource.rg.name
  enable_telemetry    = var.enable_telemetry
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
}

module "log_analytics_solution" {
  source = "../../modules/log_analytics_solution"

  log_analytics_solution_location = azapi_resource.rg.location
  log_analytics_solution_plan = {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
  log_analytics_solution_resource_group_name   = azapi_resource.rg.name
  log_analytics_solution_solution_name         = "SecurityInsights"
  log_analytics_solution_workspace_name        = module.log_analytics_workspace.name
  log_analytics_solution_workspace_resource_id = module.log_analytics_workspace.resource_id
  enable_telemetry                             = var.enable_telemetry
  location                                     = var.location
}
