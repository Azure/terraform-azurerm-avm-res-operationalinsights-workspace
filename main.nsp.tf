resource "azapi_resource" "nsp_association" {
  count = var.network_security_perimeter_association != null ? 1 : 0

  name      = "nsp-assoc-${azurerm_log_analytics_workspace.this.name}"
  parent_id = var.network_security_perimeter_association.resource_id
  type      = var.resource_types.network_network_security_perimeters_resource_associations
  body = {
    properties = {
      privateLinkResource = {
        id = azurerm_log_analytics_workspace.this.id
      }
      profile = {
        id = "${var.network_security_perimeter_association.resource_id}/profiles/${var.network_security_perimeter_association.profile_name}"
      }
      accessMode = var.network_security_perimeter_association.access_mode
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_network_security_perimeters_resource_associations) > 0 ? var.ignore_body_changes.network_network_security_perimeters_resource_associations : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
