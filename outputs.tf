output "name" {
  description = "The name of the Log Analytics Workspace."
  value       = azapi_resource.this.name
}

output "private_endpoints" {
  description = <<-EOT
  A map of the private endpoints created, with the attribute names of the `azurerm_private_endpoint` resource that earlier versions of this module returned, so that existing references keep working.
  `private_service_connection[0].private_ip_address` is the first IP address in `custom_dns_configs`.
  EOT
  value = {
    for k, pe in merge(azapi_resource.private_endpoints, azapi_resource.private_endpoints_unmanaged) : k => {
      custom_dns_configs = [
        for config in try(pe.output.custom_dns_configs, null) == null ? [] : pe.output.custom_dns_configs : {
          fqdn         = try(config.fqdn, "")
          ip_addresses = try(config.ipAddresses, [])
        }
      ]
      custom_network_interface_name = var.private_endpoints[k].network_interface_name == null ? "" : var.private_endpoints[k].network_interface_name
      id                            = pe.id
      ip_configuration = [
        for ip_configuration in values(var.private_endpoints[k].ip_configurations) : {
          member_name        = coalesce(ip_configuration.member_name, "privatelink")
          name               = ip_configuration.name
          private_ip_address = ip_configuration.private_ip_address
          subresource_name   = coalesce(var.private_endpoints[k].subresource_name, "privatelink")
        }
      ]
      location = pe.location
      name     = pe.name
      network_interface = [
        for network_interface in try(pe.output.network_interfaces, null) == null ? [] : pe.output.network_interfaces : {
          id   = network_interface.id
          name = element(reverse(split("/", network_interface.id)), 0)
        }
      ]
      private_dns_zone_group = [
        for zone_group in [try(azapi_resource.private_dns_zone_groups[k], null)] : {
          id                   = zone_group.id
          name                 = zone_group.name
          private_dns_zone_ids = tolist(local.private_dns_zone_groups[k].private_dns_zone_resource_ids)
        } if zone_group != null
      ]
      private_service_connection = [
        {
          is_manual_connection           = false
          name                           = local.private_endpoint_properties[k].privateLinkServiceConnections[0].name
          private_connection_resource_id = local.private_endpoint_private_link_scope_ids[k]
          private_ip_address             = try(pe.output.custom_dns_configs[0].ipAddresses[0], "")
          request_message                = ""
          subresource_names              = local.private_endpoint_properties[k].privateLinkServiceConnections[0].properties.groupIds
        }
      ]
      resource_group_name = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", pe.parent_id).resource_group_name
      subnet_id           = var.private_endpoints[k].subnet_resource_id
      tags                = pe.tags == null ? tomap({}) : pe.tags
    }
  }
}

output "resource" {
  description = <<-EOT
  The Log Analytics Workspace, with the attribute names of the `azurerm_log_analytics_workspace` resource that earlier versions of this module returned, so that existing references keep working. Prefer `resource_id` and `name`.
  `primary_shared_key` and `secondary_shared_key` are read when the workspace is created, and when it is upgraded from version 0.5.x or earlier.
  Examples:
  - module.log_analytics.resource.id
  - module.log_analytics.resource.name
  EOT
  sensitive   = true
  value = {
    allow_resource_only_permissions         = try(azapi_resource.this.output.features.enableLogAccessUsingOnlyResourcePermissions, null) == null ? true : azapi_resource.this.output.features.enableLogAccessUsingOnlyResourcePermissions
    cmk_for_query_forced                    = try(azapi_resource.this.output.force_cmk_for_query, null) == true
    daily_quota_gb                          = try(azapi_resource.this.output.daily_quota_gb, null) == null ? -1 : azapi_resource.this.output.daily_quota_gb
    data_collection_rule_id                 = try(azapi_resource.this.output.data_collection_rule_id, null) == null ? "" : azapi_resource.this.output.data_collection_rule_id
    id                                      = azapi_resource.this.id
    identity                                = azapi_resource.this.identity
    immediate_data_purge_on_30_days_enabled = try(azapi_resource.this.output.features.immediatePurgeDataOn30Days, null) == true
    internet_ingestion_enabled              = try(azapi_resource.this.output.public_network_access_for_ingestion, null) == "Enabled"
    internet_query_enabled                  = try(azapi_resource.this.output.public_network_access_for_query, null) == "Enabled"
    local_authentication_disabled           = try(azapi_resource.this.output.features.disableLocalAuth, null) == true
    local_authentication_enabled            = try(azapi_resource.this.output.features.disableLocalAuth, null) != true
    location                                = azapi_resource.this.location
    name                                    = azapi_resource.this.name
    primary_shared_key                      = try(data.azapi_resource_action.shared_keys.sensitive_output.primarySharedKey, null)
    reservation_capacity_in_gb_per_day      = try(azapi_resource.this.output.sku.capacityReservationLevel, null)
    resource_group_name                     = local.resource_group_name
    retention_in_days                       = try(azapi_resource.this.output.retention_in_days, null)
    secondary_shared_key                    = try(data.azapi_resource_action.shared_keys.sensitive_output.secondarySharedKey, null)
    sku                                     = try(azapi_resource.this.output.sku.name, null)
    tags                                    = azapi_resource.this.tags == null ? tomap({}) : azapi_resource.this.tags
    workspace_id                            = local.workspace_exists ? data.azapi_resource.workspace.output.customer_id : try(azapi_resource.this.output.customer_id, null)
  }
}

output "resource_id" {
  description = "This is the full output for the Log Analytics resource ID. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  value       = azapi_resource.this.id
}
