resource "azapi_resource" "data_export" {
  for_each = var.log_analytics_workspace_data_exports

  name      = each.value.name
  parent_id = azurerm_log_analytics_workspace.this.id
  type      = var.resource_types.operationalinsights_workspaces_data_exports
  body = {
    properties = {
      destination = {
        resourceId = each.value.event_hub_name != null ? each.value.destination_resource_id : (can(regex("(?i)/eventhubs/", each.value.destination_resource_id)) ? join("/", slice(split("/", each.value.destination_resource_id), 0, length(split("/", each.value.destination_resource_id)) - 2)) : each.value.destination_resource_id)
        metaData = each.value.event_hub_name != null ? {
          eventHubName = each.value.event_hub_name
          } : (can(regex("(?i)/eventhubs/", each.value.destination_resource_id)) ? {
            eventHubName = element(split("/", each.value.destination_resource_id), length(split("/", each.value.destination_resource_id)) - 1)
        } : {})
      }
      tableNames = each.value.table_names
      enable     = each.value.enabled
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.operationalinsights_workspaces_data_exports) > 0 ? var.ignore_body_changes.operationalinsights_workspaces_data_exports : null
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
