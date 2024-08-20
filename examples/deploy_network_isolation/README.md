<!-- BEGIN_TF_DOCS -->
# Deploy Network Isolation

This examples deploys network isolation with log analytics workspace using Private Endpoints and Azure Monitor Private Link Service.

- Log Analytics Workspace
- Private Endpoint
- Virtual Network
- Subnet
- Private DNS Zone
- Azure Monitor Private Link Scope
- Azure Monitor Private Link Scope Service

```hcl
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
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

  }
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

module "vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "~> 0.2.3"
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = ["10.0.0.0/16"]
  subnets = {
    subnet0 = {
      name             = module.naming.subnet.name_unique
      address_prefixes = ["10.0.0.0/24"]
    }
  }
}

locals {
  privatednszone = {
    "privatelink.monitor.azure.com"             = {}
    "privatelink.agentsvc.azure-automation.net" = {}
    "privatelink.oms.opinsights.azure.com"      = {}
    "privatelink.ods.opinsights.azure.com"      = {}
    "privatelink.blob.core.windows.net"         = {}
  }
}
module "privatednszone" {
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  version  = "~> 0.1.2"
  for_each = local.privatednszone

  domain_name         = each.key
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    vnetlink0 = {
      vnetlinkname = "dnslinktovnet"
      vnetid       = module.vnet.resource.id
    }
  }
}

# This is the module call
module "law" {
  source = "../../"
  # source = "Azure/avm-res-operationalinsights-workspace/azurerm"

  enable_telemetry                                      = var.enable_telemetry
  location                                              = azurerm_resource_group.this.location
  resource_group_name                                   = azurerm_resource_group.this.name
  name                                                  = "thislaworkspace"
  log_analytics_workspace_retention_in_days             = 30
  log_analytics_workspace_sku                           = "PerGB2018"
  log_analytics_workspace_local_authentication_disabled = true
  log_analytics_workspace_internet_ingestion_enabled    = false
  log_analytics_workspace_internet_query_enabled        = false

  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }

}

# sub module call
module "ampls" {
  source = "../../modules/monitor_private_link_scope"

  enable_telemetry                               = var.enable_telemetry
  monitor_private_link_scope_name                = "law-pl-service"
  monitor_private_link_scope_resource_group_name = azurerm_resource_group.this.name

  private_endpoints = {
    pe_01 = {
      name               = module.naming.private_endpoint.name_unique
      subnet_resource_id = module.vnet.subnets["subnet0"].resource.id
      location           = azurerm_resource_group.this.location
      private_dns_zone_resource_ids = [
        module.privatednszone["privatelink.monitor.azure.com"].resource.id,
        module.privatednszone["privatelink.agentsvc.azure-automation.net"].resource.id,
        module.privatednszone["privatelink.oms.opinsights.azure.com"].resource.id,
        module.privatednszone["privatelink.ods.opinsights.azure.com"].resource.id,
        module.privatednszone["privatelink.blob.core.windows.net"].resource.id
      ]
      network_interface_name = "law-pl-service-pe-nic"
    }
  }

  monitor_private_link_scoped_service = {
    ampls_connect_01 = {
      name               = module.law.resource.name
      linked_resource_id = module.law.resource_id
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_ampls"></a> [ampls](#module\_ampls)

Source: ../../modules/monitor_private_link_scope

Version:

### <a name="module_law"></a> [law](#module\_law)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_privatednszone"></a> [privatednszone](#module\_privatednszone)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.1.2

### <a name="module_vnet"></a> [vnet](#module\_vnet)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: ~> 0.2.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->