terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  min = 0
  max = length(local.azure_regions) - 1
}

# This is required for resource modules
resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name_unique
  location = local.azure_regions[random_integer.region_index.result]
}

# This is the module call
module "log_analytics_workspace" {
  source = "../../"
  # source             = "Azure/avm-res-operationalinsights-workspace/azurerm"
  enable_telemetry                = var.enable_telemetry
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  law_name                        = module.naming.log_analytics_workspace.name
  law_sku                         = "PerGB2018"
  retention_in_days               = 30
  allow_resource_only_permissions = true
  local_auth_disabled             = false
  internet_ingestion_enabled      = true
  internet_query_enabled          = true
  # ...
}

