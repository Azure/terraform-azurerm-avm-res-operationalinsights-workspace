resource "azurerm_monitor_private_link_scope" "this" {
  for_each            = var.monitor_private_link_scope
  name                = each.value.name != null ? each.value.name : "pl-${var.name}"
  resource_group_name = var.resource_group_name
  tags                = each.value.tags
}
 
resource "azurerm_monitor_private_link_scoped_service" "this" {
  for_each            = var.monitor_private_link_scope
 
  linked_resource_id  = azurerm_log_analytics_workspace.this.id
  name                = var.monitor_private_link_scoped_service_name
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.this[each.key].name
}