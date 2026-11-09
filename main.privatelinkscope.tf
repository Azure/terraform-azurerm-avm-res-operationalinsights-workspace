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
    azapi_resource.private_endpoints,
    azapi_resource.private_endpoints_unmanaged,
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
                try([for c in data.azapi_resource.ampls_connections[each.key].output.properties.privateEndpointConnections : c.name if lower(c.properties.privateEndpoint.id) == lower(local.private_endpoint_ids[k])][0], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}"))
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

resource "azapi_resource" "amplscope_scoped_service" {
  for_each = var.monitor_private_link_scope

  name = var.monitor_private_link_scoped_service_name
  # The ID is built as the AzureRM provider built it, from the workspace's resource group, so that upgrading
  # does not replace the scoped service. The scope's own ID cannot be used, because it has the type in lower
  # case.
  parent_id = "${local.parent_id}/providers/Microsoft.Insights/privateLinkScopes/${azapi_resource.amplscope[each.key].name}"
  type      = var.resource_types.insights_private_link_scopes_scoped_resources
  body = {
    properties = {
      linkedResourceId = azapi_resource.this.id
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.insights_private_link_scopes_scoped_resources) > 0 ? var.ignore_body_changes.insights_private_link_scopes_scoped_resources : null
  ignore_casing       = true
  # The AzureRM provider replaced the scoped service when the linked workspace changed. While the prior value
  # is null, as it is straight after upgrading from AzureRM, nothing is replaced.
  replace_triggers_external_values = {
    linked_resource_id = lower(azapi_resource.this.id)
  }
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

resource "time_sleep" "wait_for_ampls_update" {
  create_duration  = "30s"
  destroy_duration = "30s"

  depends_on = [
    azapi_resource.amplscope_scoped_service
  ]
}

resource "azapi_resource" "ampls" {
  for_each = var.monitor_private_link_scoped_resource

  name      = each.value.name != null ? each.value.name : azapi_resource.this.name
  parent_id = each.value.resource_id
  type      = var.resource_types.insights_private_link_scopes_scoped_resources
  body = {
    properties = {
      linkedResourceId = azapi_resource.this.id
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
    azapi_resource.private_endpoints,
    azapi_resource.private_endpoints_unmanaged,
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
                try([for c in data.azapi_resource.ampls_connections_existing[each.key].output.properties.privateEndpointConnections : c.name if lower(c.properties.privateEndpoint.id) == lower(local.private_endpoint_ids[k])][0], (v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}"))
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

resource "azapi_resource" "amplscope_lock" {
  for_each = { for k, v in var.monitor_private_link_scope : k => v if v.lock != null }

  name      = try(each.value.lock.name, null) != null ? each.value.lock.name : "${azapi_resource.amplscope[each.key].name}-lock"
  parent_id = azapi_resource.amplscope[each.key].id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = each.value.lock.kind
      # The empty notes that earlier versions of this module wrote, so that upgrading leaves the lock unchanged.
      notes = ""
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
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

  depends_on = [time_sleep.amplscope_lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzAPI provider does not wait for it to be
# gone as the AzureRM provider did. This pause is destroyed after the lock and before the scope's scoped
# services and private endpoint connections.
resource "time_sleep" "amplscope_lock_removal" {
  for_each = { for k, v in var.monitor_private_link_scope : k => v if v.lock != null }

  destroy_duration = "30s"
  # Replacing the scope replaces its lock, so the pause is replaced with them.
  triggers = {
    scope_id = azapi_resource.amplscope[each.key].id
  }

  depends_on = [
    azapi_resource.amplscope_scoped_service,
    azapi_resource.private_endpoints,
    azapi_resource.private_endpoints_unmanaged,
    azapi_update_resource.amplscope_update,
  ]
}
