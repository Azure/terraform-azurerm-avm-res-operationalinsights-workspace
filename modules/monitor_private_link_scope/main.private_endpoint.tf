resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  location                      = each.value.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.monitor_private_link_scope_name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.monitor_private_link_scope_resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.monitor_private_link_scope_name}"
    private_connection_resource_id = azurerm_monitor_private_link_scope.this.id
    subresource_names              = ["azuremonitor"]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "azuremonitor"
      subresource_name   = "azuremonitor"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  depends_on = [time_sleep.private_endpoint_setup]
}

resource "time_sleep" "private_endpoint_setup" {
  create_duration = "5s"

  depends_on = [azurerm_monitor_private_link_scope.this]
}