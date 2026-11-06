resource "azapi_resource" "linked_storage_accounts" {
  for_each = var.log_analytics_workspace_linked_storage_accounts

  name      = each.value.data_source_type
  parent_id = azapi_resource.this.id
  type      = var.resource_types.operationalinsights_workspaces_linked_storage_accounts
  body = {
    properties = {
      storageAccountIds = each.value.storage_account_ids
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.operationalinsights_workspaces_linked_storage_accounts) > 0 ? var.ignore_body_changes.operationalinsights_workspaces_linked_storage_accounts : null
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
