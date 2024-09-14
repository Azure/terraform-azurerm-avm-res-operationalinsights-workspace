terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.15.0, < 2.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azapi" {
  use_cli = true
  use_msi = false
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
resource "azurerm_resource_group" "this" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "this" {
  address_space       = ["192.168.0.0/24"]
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  address_prefixes     = ["192.168.0.0/24"]
  name                 = module.naming.subnet.name_unique
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

module "privatednszone" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "~> 0.1.1"
  domain_name         = "privatelink.workspace.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    vnetlink0 = {
      vnetlinkname = "dnslinktovnet"
      vnetid       = azurerm_virtual_network.this.id
    }
  }
}

# This is the module call
module "law" {
  source = "../../"
  # source             = "Azure/avm-res-operationalinsights-workspace/azurerm"
  enable_telemetry                          = var.enable_telemetry
  location                                  = azurerm_resource_group.this.location
  resource_group_name                       = azurerm_resource_group.this.name
  name                                      = "thislaworkspace"
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  monitor_private_link_scope = {
    pe1 = {
      name        = "law_pl_scope"
      resource_id = azurerm_resource_group.this.id
    }
  }
  monitor_private_link_scoped_service_name = "law_pl_service"
  private_endpoints = {
    pe1 = {
      subnet_resource_id          = azurerm_subnet.this.id
      network_interface_name      = "nic1"
      private_dns_zone_group_name = "dnslinktovnet"
    }
  }
}

