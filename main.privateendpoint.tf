resource "azapi_resource" "private_endpoints" {
  for_each = { for k, v in var.private_endpoints : k => v if local.private_endpoint_manage_dns_zone_group[k] }

  location  = each.value.location != null ? each.value.location : var.location
  name      = local.private_endpoint_names[each.key]
  parent_id = local.private_endpoint_parent_ids[each.key]
  type      = var.resource_types.network_private_endpoints
  body = {
    properties = local.private_endpoint_properties[each.key]
  }
  ignore_body_changes  = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  ignore_casing        = true
  ignore_null_property = true
  # Azure can return the application security groups in a different order from the one they were sent in.
  list_unique_id_property = {
    "properties.applicationSecurityGroups" = "id"
  }
  replace_triggers_external_values = local.private_endpoint_replace_triggers[each.key]
  response_export_values = {
    custom_dns_configs = "properties.customDnsConfigs"
    network_interfaces = "properties.networkInterfaces"
  }
  retry = var.retry
  tags  = each.value.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# Private endpoints whose DNS zone group is managed outside this module, for example by Azure Policy.
resource "azapi_resource" "private_endpoints_unmanaged" {
  for_each = { for k, v in var.private_endpoints : k => v if !local.private_endpoint_manage_dns_zone_group[k] }

  location  = each.value.location != null ? each.value.location : var.location
  name      = local.private_endpoint_names[each.key]
  parent_id = local.private_endpoint_parent_ids[each.key]
  type      = var.resource_types.network_private_endpoints
  body = {
    properties = local.private_endpoint_properties[each.key]
  }
  ignore_body_changes  = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  ignore_casing        = true
  ignore_null_property = true
  # Azure can return the application security groups in a different order from the one they were sent in.
  list_unique_id_property = {
    "properties.applicationSecurityGroups" = "id"
  }
  replace_triggers_external_values = local.private_endpoint_replace_triggers[each.key]
  response_export_values = {
    custom_dns_configs = "properties.customDnsConfigs"
    network_interfaces = "properties.networkInterfaces"
  }
  retry = var.retry
  tags  = each.value.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = local.private_dns_zone_groups

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in each.value.private_dns_zone_resource_ids : {
          name = element(reverse(split("/", private_dns_zone_resource_id)), 0)
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
  ignore_casing          = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# Adopts the zone groups that versions 0.5.x and earlier created as part of the private endpoint, so that
# upgrading does not fail with `Resource already exists`. The gate is required: on a new deployment the zone
# group does not exist yet and an unconditional import fails at plan time. Terraform skips an import whose
# target is already in state, so leaving the flag set after the upgrade is a no-op for those zone groups.
import {
  for_each = var.avm_managed_migration_enabled ? local.private_dns_zone_group_imports : {}

  to = azapi_resource.private_dns_zone_groups[each.key]
  id = each.value
}
