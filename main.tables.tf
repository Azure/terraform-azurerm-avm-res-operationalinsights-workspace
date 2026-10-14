resource "azapi_resource" "tables" {
  for_each = var.log_analytics_workspace_tables

  name      = each.value.name
  parent_id = each.value.resource_id != null ? each.value.resource_id : azurerm_log_analytics_workspace.this.id
  type      = var.resource_types.operationalinsights_workspaces_tables
  body = {
    properties = {
      for k, v in {
        retentionInDays      = each.value.retention_in_days
        totalRetentionInDays = each.value.total_retention_in_days
        plan                 = each.value.plan
        schema = each.value.schema == null ? null : {
          for sk, sv in {
            name        = each.value.schema.name
            description = each.value.schema.description
            columns     = each.value.schema.columns
          } : sk => sv if sv != null
        }
      } : k => v if v != null
    }
  }
  ignore_body_changes       = length(var.ignore_body_changes.operationalinsights_workspaces_tables) > 0 ? var.ignore_body_changes.operationalinsights_workspaces_tables : null
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false

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

resource "azapi_update_resource" "tables" {
  for_each = var.log_analytics_workspace_tables_update

  name      = each.value.name
  parent_id = each.value.resource_id != null ? each.value.resource_id : azurerm_log_analytics_workspace.this.id
  type      = var.resource_types.operationalinsights_workspaces_tables
  body = {
    properties = {
      for k, v in {
        retentionInDays      = each.value.retention_in_days
        totalRetentionInDays = each.value.total_retention_in_days
        plan                 = each.value.plan
        schema = each.value.schema == null ? null : {
          for sk, sv in {
            name        = each.value.schema.name
            description = each.value.schema.description
            columns     = each.value.schema.columns
          } : sk => sv if sv != null
        }
      } : k => v if v != null
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
