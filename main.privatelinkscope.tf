resource "azurerm_monitor_private_link_scope" "this" {
  name                = var.monitor_private_link_scope_name
  resource_group_name = var.resource_group_name
  tags                = var.monitor_private_link_scope_tags

  dynamic "timeouts" {
    for_each = var.monitor_private_link_scope_timeouts == null ? [] : [var.monitor_private_link_scope_timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_monitor_private_link_scoped_service" "this" {
  linked_resource_id  = azurerm_log_analytics_workspace.this.id
  name                = var.monitor_private_link_scoped_service_name
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.this.name
}