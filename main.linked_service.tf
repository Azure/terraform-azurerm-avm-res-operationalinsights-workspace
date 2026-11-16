resource "azapi_resource" "linked_service" {
  count = var.log_analytics_workspace_dedicated_cluster_resource_id != null ? 1 : 0

  name      = "Cluster"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.operationalinsights_workspaces_linked_services
  body = {
    properties = {
      writeAccessResourceId = var.log_analytics_workspace_dedicated_cluster_resource_id
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.operationalinsights_workspaces_linked_services) > 0 ? var.ignore_body_changes.operationalinsights_workspaces_linked_services : null
  ignore_casing          = true
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

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
