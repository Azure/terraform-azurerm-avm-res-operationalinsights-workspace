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

  location            = azurerm_resource_group.rg.location
  name                = "thislaworkspace"
  resource_group_name = azurerm_resource_group.rg.name
  enable_telemetry    = var.enable_telemetry
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
}

module "query_packs" {
  source = "../../modules/query_packs"

  location          = azurerm_resource_group.rg.location
  resource_group_id = azurerm_resource_group.rg.id
  monitor_queries = {
    "query1" = {
      query_pack_key = "pack1"
      display_name   = "My Query"
      body           = "Heartbeat | take 10"
      description    = "Sample query"
      related = {
        categories = ["monitor"]
      }
    }
  }
  monitor_query_packs = {
    "pack1" = {
      name = "my-query-pack"
      tags = { env = "dev" }
      lock = {
        kind = "CanNotDelete"
      }
    }
  }
}
