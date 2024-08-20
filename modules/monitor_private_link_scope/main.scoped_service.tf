resource "azurerm_monitor_private_link_scoped_service" "this" {
  for_each = var.monitor_private_link_scoped_service

  linked_resource_id  = each.value.linked_resource_id
  name                = each.value.name
  resource_group_name = each.value.resource_group_name != null ? each.value.resource_group_name : var.monitor_private_link_scope_resource_group_name
  scope_name          = each.value.scope_name != null ? each.value.scope_name : var.monitor_private_link_scope_name
}
