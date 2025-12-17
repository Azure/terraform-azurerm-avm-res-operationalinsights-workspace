resource "azapi_resource" "amplscope" {
  for_each = var.monitor_private_link_scope

  location  = "global"
  name      = each.value.name != null ? each.value.name : "law_pl_scope"
  parent_id = each.value.resource_id
  type      = "microsoft.insights/privateLinkScopes@2021-07-01-preview"
  body = {
    properties = {
      accessModeSettings = {
        ingestionAccessMode = each.value.ingestion_access_mode
        queryAccessMode     = each.value.query_access_mode
      }
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

data "azapi_resource" "ampls_connections" {
  for_each = var.monitor_private_link_scope

  resource_id            = azapi_resource.amplscope[each.key].id
  type                   = "microsoft.insights/privateLinkScopes@2021-07-01-preview"
  response_export_values = ["properties.privateEndpointConnections"]

  depends_on = [
    azurerm_private_endpoint.this,
    azurerm_private_endpoint.this_unmanaged
  ]
}

resource "azapi_update_resource" "amplscope_update" {
  for_each = var.monitor_private_link_scope

  resource_id = azapi_resource.amplscope[each.key].id
  type        = "microsoft.insights/privateLinkScopes@2021-07-01-preview"
  body = {
    properties = {
      accessModeSettings = {
        exclusions = concat(
          [
            for exclusion in each.value.exclusions : {
              ingestionAccessMode           = exclusion.ingestion_access_mode
              privateEndpointConnectionName = exclusion.private_endpoint_connection_name
              queryAccessMode               = exclusion.query_access_mode
            }
          ],
          flatten([
            for k, v in var.private_endpoints : [
              for connection_name in [
                try([for c in data.azapi_resource.ampls_connections[each.key].output.properties.privateEndpointConnections : c.name if lower(c.properties.privateEndpoint.id) == lower(var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this[k].id : azurerm_private_endpoint.this_unmanaged[k].id)][0], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}"))
                ] : {
                ingestionAccessMode           = v.monitor_private_link_scope_exclusion == null ? "PrivateOnly" : v.monitor_private_link_scope_exclusion.ingestion_access_mode
                privateEndpointConnectionName = connection_name
                queryAccessMode               = v.monitor_private_link_scope_exclusion == null ? "PrivateOnly" : v.monitor_private_link_scope_exclusion.query_access_mode
              }
              if connection_name != null
            ]
            if try(
              azapi_resource.amplscope[v.monitor_private_link_scope_key].id,
              var.monitor_private_link_scoped_resource[v.monitor_private_link_scope_key].resource_id,
              azapi_resource.amplscope[k].id,
              var.monitor_private_link_scoped_resource[k].resource_id,
              length(var.monitor_private_link_scope) + length(var.monitor_private_link_scoped_resource) == 1 ? coalesce(try(one(values(var.monitor_private_link_scoped_resource)).resource_id, null), try(one(values(azapi_resource.amplscope)).id, null)) : null
            ) == azapi_resource.amplscope[each.key].id &&
            !contains([for e in each.value.exclusions : e.private_endpoint_connection_name], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}")) &&
            (v.monitor_private_link_scope_exclusion == null ? true : v.monitor_private_link_scope_exclusion.exclude)
          ])
        )
        ingestionAccessMode = each.value.ingestion_access_mode
        queryAccessMode     = each.value.query_access_mode
      }
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azurerm_monitor_private_link_scoped_service" "this" {
  for_each = var.monitor_private_link_scope

  linked_resource_id  = azurerm_log_analytics_workspace.this.id
  name                = var.monitor_private_link_scoped_service_name
  resource_group_name = var.resource_group_name
  scope_name          = azapi_resource.amplscope[each.key].name
}

resource "azapi_resource" "ampls" {
  for_each = var.monitor_private_link_scoped_resource

  name      = each.value.name != null ? each.value.name : azurerm_log_analytics_workspace.this.name
  parent_id = each.value.resource_id
  type      = "Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview"
  body = {
    properties = {
      linkedResourceId = azurerm_log_analytics_workspace.this.id
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_casing  = true
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

data "azapi_resource" "ampls_existing" {
  for_each = var.monitor_private_link_scoped_resource

  resource_id            = each.value.resource_id
  type                   = "microsoft.insights/privateLinkScopes@2021-07-01-preview"
  response_export_values = ["properties.accessModeSettings"]
}

data "azapi_resource" "ampls_connections_existing" {
  for_each = var.monitor_private_link_scoped_resource

  resource_id            = each.value.resource_id
  type                   = "microsoft.insights/privateLinkScopes@2021-07-01-preview"
  response_export_values = ["properties.privateEndpointConnections"]

  depends_on = [
    azurerm_private_endpoint.this,
    azurerm_private_endpoint.this_unmanaged
  ]
}

resource "azapi_update_resource" "amplscope_update_existing" {
  for_each = var.monitor_private_link_scoped_resource

  resource_id = lower(each.value.resource_id)
  type        = "microsoft.insights/privateLinkScopes@2021-07-01-preview"
  body = {
    properties = {
      accessModeSettings = {
        exclusions = concat(
          [
            for exclusion in each.value.exclusions : {
              ingestionAccessMode           = exclusion.ingestion_access_mode
              privateEndpointConnectionName = exclusion.private_endpoint_connection_name
              queryAccessMode               = exclusion.query_access_mode
            }
          ],
          flatten([
            for k, v in var.private_endpoints : [
              for connection_name in [
                try([for c in data.azapi_resource.ampls_connections_existing[each.key].output.properties.privateEndpointConnections : c.name if lower(c.properties.privateEndpoint.id) == lower(var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this[k].id : azurerm_private_endpoint.this_unmanaged[k].id)][0], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}"))
                ] : {
                ingestionAccessMode           = v.monitor_private_link_scope_exclusion == null ? "PrivateOnly" : v.monitor_private_link_scope_exclusion.ingestion_access_mode
                privateEndpointConnectionName = connection_name
                queryAccessMode               = v.monitor_private_link_scope_exclusion == null ? "PrivateOnly" : v.monitor_private_link_scope_exclusion.query_access_mode
              }
              if connection_name != null
            ]
            if try(
              azapi_resource.amplscope[v.monitor_private_link_scope_key].id,
              var.monitor_private_link_scoped_resource[v.monitor_private_link_scope_key].resource_id,
              azapi_resource.amplscope[k].id,
              var.monitor_private_link_scoped_resource[k].resource_id,
              length(var.monitor_private_link_scope) + length(var.monitor_private_link_scoped_resource) == 1 ? coalesce(try(one(values(var.monitor_private_link_scoped_resource)).resource_id, null), try(one(values(azapi_resource.amplscope)).id, null)) : null
            ) == each.value.resource_id &&
            !contains([for e in each.value.exclusions : e.private_endpoint_connection_name], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}")) &&
            (v.monitor_private_link_scope_exclusion == null ? true : v.monitor_private_link_scope_exclusion.exclude)
          ])
        )
        ingestionAccessMode = data.azapi_resource.ampls_existing[each.key].output.properties.accessModeSettings.ingestionAccessMode
        queryAccessMode     = data.azapi_resource.ampls_existing[each.key].output.properties.accessModeSettings.queryAccessMode
      }
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azurerm_management_lock" "amplscope" {
  for_each = { for k, v in var.monitor_private_link_scope : k => v if v.lock != null }

  lock_level = each.value.lock.kind
  name       = try(each.value.lock.name, null) != null ? each.value.lock.name : "${azapi_resource.amplscope[each.key].name}-lock"
  scope      = azapi_resource.amplscope[each.key].id
}

