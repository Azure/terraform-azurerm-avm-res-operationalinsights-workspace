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

module "query_packs" {
  source = "../../modules/query_packs"

  location          = azapi_resource.rg.location
  resource_group_id = azapi_resource.rg.id
  enable_telemetry  = var.enable_telemetry
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
