# terraform-azurerm-avm-res-operationalinsights-workspace

This repo is to deploy an Log Analytics Workspace.

Private endpoints retain their existing resource addresses, names, and defaults.
`private_endpoints_manage_dns_zone_group` defaults to `true`; an explicit
`private_endpoint_extensions[key].manage_dns_zone_group` takes precedence.
Omitted service names default to `azuremonitor`; omitted IP configuration member
and subresource names retain `privatelink`. Endpoint resource groups accept names
or resource IDs. Endpoint role assignments and locks are applied when supplied;
these previously declared settings were not implemented.

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>
