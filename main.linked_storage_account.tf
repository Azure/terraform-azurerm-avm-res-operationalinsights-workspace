resource "azurerm_log_analytics_linked_storage_account" "this" {
  for_each = var.log_analytics_workspace_linked_storage_accounts

  data_source_type      = each.value.data_source_type
  resource_group_name   = var.resource_group_name
  storage_account_ids   = each.value.storage_account_ids
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
}
