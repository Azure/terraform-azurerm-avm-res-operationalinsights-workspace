# TODO remove this code & var.private_endpoints if private link is not support.  Note it must be included in this module if it is supported.
resource "azurerm_private_endpoint" "this" {
  for_each = { for k, v in var.private_endpoints : k => v if v.manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection = false
    name                 = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = try(
      azapi_resource.amplscope[each.value.monitor_private_link_scope_key].id,
      lower(var.monitor_private_link_scoped_resource[each.value.monitor_private_link_scope_key].resource_id),
      azapi_resource.amplscope[each.key].id,
      lower(var.monitor_private_link_scoped_resource[each.key].resource_id),
      length(var.monitor_private_link_scope) + length(var.monitor_private_link_scoped_resource) == 1 ? coalesce(try(lower(one(values(var.monitor_private_link_scoped_resource)).resource_id), null), try(one(values(azapi_resource.amplscope)).id, null)) : null
    )
    subresource_names = ["azuremonitor"] # map to each.value.subresource_name if there are multiple services.
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "privatelink" # map to each.value.subresource_name if there are multiple services.
      subresource_name   = "privatelink" # map to each.value.subresource_name if there are multiple services.
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

resource "azurerm_private_endpoint" "this_unmanaged" {
  for_each = { for k, v in var.private_endpoints : k => v if !v.manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection = false
    name                 = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = try(
      azapi_resource.amplscope[each.value.monitor_private_link_scope_key].id,
      lower(var.monitor_private_link_scoped_resource[each.value.monitor_private_link_scope_key].resource_id),
      azapi_resource.amplscope[each.key].id,
      lower(var.monitor_private_link_scoped_resource[each.key].resource_id),
      length(var.monitor_private_link_scope) + length(var.monitor_private_link_scoped_resource) == 1 ? coalesce(try(lower(one(values(var.monitor_private_link_scoped_resource)).resource_id), null), try(one(values(azapi_resource.amplscope)).id, null)) : null
    )
    subresource_names = ["azuremonitor"] # map to each.value.subresource_name if there are multiple services.
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "privatelink" # map to each.value.subresource_name if there are multiple services.
      subresource_name   = "privatelink" # map to each.value.subresource_name if there are multiple services.
    }
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = { for k, v in local.private_endpoint_application_security_group_associations : k => v if var.private_endpoints[v.pe_key].manage_dns_zone_group }

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = azurerm_private_endpoint.this[each.value.pe_key].id
}

resource "azurerm_private_endpoint_application_security_group_association" "this_unmanaged" {
  for_each = { for k, v in local.private_endpoint_application_security_group_associations : k => v if !var.private_endpoints[v.pe_key].manage_dns_zone_group }

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = azurerm_private_endpoint.this_unmanaged[each.value.pe_key].id
}
