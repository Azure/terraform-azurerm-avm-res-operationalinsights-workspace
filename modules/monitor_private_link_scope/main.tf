
resource "azurerm_monitor_private_link_scope" "this" {
  name                  = var.monitor_private_link_scope_name
  resource_group_name   = var.monitor_private_link_scope_resource_group_name
  ingestion_access_mode = var.monitor_private_link_scope_ingestion_access_mode
  query_access_mode     = var.monitor_private_link_scope_query_access_mode
  tags                  = var.monitor_private_link_scope_tags
}
