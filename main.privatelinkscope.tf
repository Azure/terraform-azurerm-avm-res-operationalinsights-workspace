resource "azapi_resource" "amplscope" {
  for_each = var.monitor_private_link_scope

  location  = "global"
  name      = each.value.name != null ? each.value.name : "law_pl_scope"
  parent_id = each.value.resource_id
  type      = var.resource_types.insights_private_link_scopes
  body = {
    properties = {
      accessModeSettings = {
        ingestionAccessMode = each.value.ingestion_access_mode
        queryAccessMode     = each.value.query_access_mode
      }
    }
  }
  ignore_body_changes       = length(var.ignore_body_changes.insights_private_link_scopes) > 0 ? var.ignore_body_changes.insights_private_link_scopes : null
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false
  tags                      = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

data "azapi_resource" "ampls_connections" {
  for_each = var.monitor_private_link_scope

  resource_id            = azapi_resource.amplscope[each.key].id
  type                   = var.resource_types.insights_private_link_scopes
  response_export_values = ["properties.privateEndpointConnections"]

  depends_on = [
    azurerm_private_endpoint.this,
    azurerm_private_endpoint.this_unmanaged
  ]
}

resource "azapi_update_resource" "amplscope_update" {
  for_each = var.monitor_private_link_scope

  resource_id = azapi_resource.amplscope[each.key].id
  type        = var.resource_types.insights_private_link_scopes
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
                try([for c in data.azapi_resource.ampls_connections[each.key].output.properties.privateEndpointConnections : c.name if lower(c.properties.privateEndpoint.id) == lower(local.private_endpoint_manage_dns_zone_group[k] ? azurerm_private_endpoint.this[k].id : azurerm_private_endpoint.this_unmanaged[k].id)][0], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}"))
                ] : {
                ingestionAccessMode           = try(var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion, null) == null ? "PrivateOnly" : var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion.ingestion_access_mode
                privateEndpointConnectionName = connection_name
                queryAccessMode               = try(var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion, null) == null ? "PrivateOnly" : var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion.query_access_mode
              }
              if connection_name != null
            ]
            if try(
              try(var.private_endpoint_extensions[k].monitor_private_link_scope_key, null) != null ? azapi_resource.amplscope[var.private_endpoint_extensions[k].monitor_private_link_scope_key].id : null,
              try(var.private_endpoint_extensions[k].monitor_private_link_scope_key, null) != null ? var.monitor_private_link_scoped_resource[var.private_endpoint_extensions[k].monitor_private_link_scope_key].resource_id : null,
              azapi_resource.amplscope[k].id,
              var.monitor_private_link_scoped_resource[k].resource_id,
              length(var.monitor_private_link_scope) + length(var.monitor_private_link_scoped_resource) == 1 ? coalesce(try(one(values(var.monitor_private_link_scoped_resource)).resource_id, null), try(one(values(azapi_resource.amplscope)).id, null)) : null
            ) == azapi_resource.amplscope[each.key].id &&
            !contains([for e in each.value.exclusions : e.private_endpoint_connection_name], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}")) &&
            (try(var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion, null) == null ? true : var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion.exclude)
          ])
        )
        ingestionAccessMode = each.value.ingestion_access_mode
        queryAccessMode     = each.value.query_access_mode
      }
    }
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azurerm_monitor_private_link_scoped_service" "this" {
  for_each = var.monitor_private_link_scope

  linked_resource_id  = azurerm_log_analytics_workspace.this.id
  name                = var.monitor_private_link_scoped_service_name
  resource_group_name = var.resource_group_name
  scope_name          = azapi_resource.amplscope[each.key].name

  depends_on = [
    azapi_update_resource.this
  ]
}

resource "time_sleep" "wait_for_ampls_update" {
  create_duration  = "30s"
  destroy_duration = "30s"

  depends_on = [
    azurerm_monitor_private_link_scoped_service.this
  ]
}

resource "azapi_resource" "ampls" {
  for_each = var.monitor_private_link_scoped_resource

  name      = each.value.name != null ? each.value.name : azurerm_log_analytics_workspace.this.name
  parent_id = each.value.resource_id
  type      = var.resource_types.insights_private_link_scopes_scoped_resources
  body = {
    properties = {
      linkedResourceId = azurerm_log_analytics_workspace.this.id
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.insights_private_link_scopes_scoped_resources) > 0 ? var.ignore_body_changes.insights_private_link_scopes_scoped_resources : null
  ignore_casing          = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    time_sleep.wait_for_ampls_update
  ]
}

data "azapi_resource" "ampls_existing" {
  for_each = var.monitor_private_link_scoped_resource

  resource_id            = each.value.resource_id
  type                   = var.resource_types.insights_private_link_scopes
  response_export_values = ["properties.accessModeSettings"]
}

data "azapi_resource" "ampls_connections_existing" {
  for_each = var.monitor_private_link_scoped_resource

  resource_id            = each.value.resource_id
  type                   = var.resource_types.insights_private_link_scopes
  response_export_values = ["properties.privateEndpointConnections"]

  depends_on = [
    azurerm_private_endpoint.this,
    azurerm_private_endpoint.this_unmanaged
  ]
}

resource "azapi_update_resource" "amplscope_update_existing" {
  for_each = var.monitor_private_link_scoped_resource

  resource_id = lower(each.value.resource_id)
  type        = var.resource_types.insights_private_link_scopes
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
                try([for c in data.azapi_resource.ampls_connections_existing[each.key].output.properties.privateEndpointConnections : c.name if lower(c.properties.privateEndpoint.id) == lower(local.private_endpoint_manage_dns_zone_group[k] ? azurerm_private_endpoint.this[k].id : azurerm_private_endpoint.this_unmanaged[k].id)][0], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}"))
                ] : {
                ingestionAccessMode           = try(var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion, null) == null ? "PrivateOnly" : var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion.ingestion_access_mode
                privateEndpointConnectionName = connection_name
                queryAccessMode               = try(var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion, null) == null ? "PrivateOnly" : var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion.query_access_mode
              }
              if connection_name != null
            ]
            if try(
              azapi_resource.amplscope[try(var.private_endpoint_extensions[k].monitor_private_link_scope_key, null)].id,
              var.monitor_private_link_scoped_resource[try(var.private_endpoint_extensions[k].monitor_private_link_scope_key, null)].resource_id,
              azapi_resource.amplscope[k].id,
              var.monitor_private_link_scoped_resource[k].resource_id,
              length(var.monitor_private_link_scope) + length(var.monitor_private_link_scoped_resource) == 1 ? coalesce(try(one(values(var.monitor_private_link_scoped_resource)).resource_id, null), try(one(values(azapi_resource.amplscope)).id, null)) : null
            ) == each.value.resource_id &&
            !contains([for e in each.value.exclusions : e.private_endpoint_connection_name], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}")) &&
            (try(var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion, null) == null ? true : var.private_endpoint_extensions[k].monitor_private_link_scope_exclusion.exclude)
          ])
        )
        ingestionAccessMode = data.azapi_resource.ampls_existing[each.key].output.properties.accessModeSettings.ingestionAccessMode
        queryAccessMode     = data.azapi_resource.ampls_existing[each.key].output.properties.accessModeSettings.queryAccessMode
      }
    }
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azurerm_management_lock" "amplscope" {
  for_each = { for k, v in var.monitor_private_link_scope : k => v if v.lock != null }

  lock_level = each.value.lock.kind
  name       = try(each.value.lock.name, null) != null ? each.value.lock.name : "${azapi_resource.amplscope[each.key].name}-lock"
  scope      = azapi_resource.amplscope[each.key].id
}
