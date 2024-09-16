terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.71, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  #subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  max = length(local.azure_regions) - 1
  min = 0
}

# This is required for resource modules
resource "azurerm_resource_group" "rg" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

# This is the module call
module "log_analytics_workspace" {
  source = "../../"
  # source             = "Azure/avm-res-operationalinsights-workspace/azurerm"
  enable_telemetry                          = var.enable_telemetry
  location                                  = azurerm_resource_group.rg.location
  resource_group_name                       = azurerm_resource_group.rg.name
  name                                      = "thislaworkspace"
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
}

module "log_analytics_solution" {
  source                                       = "../../modules/log_analytics_solution"
  log_analytics_solution_solution_name         = "SecurityInsights"
  log_analytics_solution_workspace_name        = module.log_analytics_workspace.resource.name
  log_analytics_solution_workspace_resource_id = module.log_analytics_workspace.resource_id
  log_analytics_solution_resource_group_name   = azurerm_resource_group.rg.name
  log_analytics_solution_location              = azurerm_resource_group.rg.location
  log_analytics_solution_plan = {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}