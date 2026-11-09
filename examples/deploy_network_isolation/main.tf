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

provider "azapi" {
  use_cli = true
  use_msi = false
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
resource "azapi_resource" "this" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.this.location
  name      = module.naming.virtual_network.name_unique
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["192.168.0.0/24"]
      }
    }
  }
}

resource "azapi_resource" "subnet" {
  name      = module.naming.subnet.name_unique
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "192.168.0.0/24"
    }
  }
}

module "privatednszone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  domain_name      = "privatelink.monitor.azure.com"
  parent_id        = azapi_resource.this.id
  enable_telemetry = var.enable_telemetry
  virtual_network_links = {
    vnetlink0 = {
      name               = "dnslinktovnet"
      virtual_network_id = azapi_resource.virtual_network.id
    }
  }
}

# This is the module call
module "law" {
  source = "../../"

  location            = azapi_resource.this.location
  name                = "thislaworkspace"
  resource_group_name = azapi_resource.this.name
  enable_telemetry    = var.enable_telemetry
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
  monitor_private_link_scope = {
    pe1 = {
      name        = "law_pl_scope"
      resource_id = azapi_resource.this.id
    }
  }
  monitor_private_link_scoped_service_name = "law_pl_service"
  private_endpoints = {
    pe1 = {
      subnet_resource_id            = azapi_resource.subnet.id
      network_interface_name        = "nic1"
      private_dns_zone_group_name   = "dnslinktovnet"
      private_dns_zone_resource_ids = [module.privatednszone.resource_id]
    }
  }
}
