resource "azurerm_monitor_private_link_scope" "this" {
  name                = var.monitor_private_link_scope.name
  resource_group_name = var.resource_group_name
  tags                = var.monitor_private_link_scope.tags
}

resource "azurerm_monitor_private_link_scoped_service" "this" {
  linked_resource_id  = azurerm_log_analytics_workspace.this.id
  name                = var.monitor_private_link_scoped_service_name
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.this.name
}