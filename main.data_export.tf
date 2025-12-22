resource "azapi_resource" "data_export" {
  for_each = var.log_analytics_workspace_data_exports

  name      = each.value.name
  parent_id = azurerm_log_analytics_workspace.this.id
  type      = "Microsoft.OperationalInsights/workspaces/dataExports@2020-08-01"
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
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
