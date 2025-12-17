resource "azurerm_log_analytics_linked_service" "this" {
  count = var.log_analytics_workspace_dedicated_cluster_resource_id != null ? 1 : 0

  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  write_access_id     = var.log_analytics_workspace_dedicated_cluster_resource_id
}
