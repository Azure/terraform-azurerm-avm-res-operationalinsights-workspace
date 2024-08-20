locals {
  azure_regions = [
    "eastus",
    "eastus2",
    "westus",
    "westus2",
    "southcentralus",
    "northcentralus",
    "centralus"
  ]
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
