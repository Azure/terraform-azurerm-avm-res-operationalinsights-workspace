resource "azapi_resource" "nsp_association" {
  count = var.network_security_perimeter_association != null ? 1 : 0

  name      = "nsp-assoc-${azurerm_log_analytics_workspace.this.name}"
  parent_id = var.network_security_perimeter_association.resource_id
  type      = "Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview"
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
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
