terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.36.0, < 5.0.0"
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
  version = "0.4.1"
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

module "data_collection" {
  source = "../../modules/data_collection"

  location                            = azurerm_resource_group.rg.location
  log_analytics_workspace_resource_id = module.log_analytics_workspace.resource_id
  resource_group_id                   = azurerm_resource_group.rg.id
  data_collection_endpoints = {
    "dce-test" = {
      name                          = "dce-avm-test"
      description                   = "Test Data Collection Endpoint"
      public_network_access_enabled = "Disabled"
      tags                          = { Purpose = "Testing" }
      lock = {
        kind = "CanNotDelete"
      }
    }
  }
  data_collection_rule_associations = {
    "assoc-windows-vm" = {
      name                          = "configurationAccessEndpoint"
      target_resource_id            = "<VM_resource_id>"
      data_collection_endpoint_name = "dce-test"
      description                   = "Association for Windows VM to DCE"
    }
    "assoc-windows-vm-dcr" = {
      name                      = "dcr-association"
      target_resource_id        = "<VM_resource_id>"
      data_collection_rule_name = "dcr-test"
      description               = "Association for Windows VM to DCR"
    }
  }
  data_collection_rules = {
    "dcr-test" = {
      name        = "dcr-avm-test"
      kind        = "Windows"
      description = "Test Data Collection Rule for Windows"
      tags        = { Purpose = "Testing" }
      lock        = { kind = "CanNotDelete" }
      data_sources = {
        performanceCounters = [
          {
            name                       = "cloudTeamCoreCounters"
            streams                    = ["Microsoft-Perf"]
            samplingFrequencyInSeconds = 60
            counterSpecifiers          = ["\\Processor(_Total)\\% Processor Time", "\\Memory\\Committed Bytes"]
          }
        ]
        windowsEventLogs = [
          {
            name         = "cloudSecurityTeamEvents"
            streams      = ["Microsoft-Event"]
            xPathQueries = ["Security!*[System[(band(Keywords,13510798882111488))]]"]
          }
        ]
      }
      destinations = {
        logAnalytics = [
          {
            name = "law-destination"
          }
        ]
      }
      data_flows = [
        {
          streams      = ["Microsoft-Perf", "Microsoft-Event"]
          destinations = ["law-destination"]
        }
      ]
    }
  }
}
