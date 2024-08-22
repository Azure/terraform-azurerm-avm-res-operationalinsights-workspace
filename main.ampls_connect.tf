resource "azapi_resource" "ampls" {
  for_each = var.monitor_private_link_scoped_resource

  type = "Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview"
  body = jsonencode({
    properties = {
      linkedResourceId = azurerm_log_analytics_workspace.this.id
    }
  })
  ignore_casing = true
  name          = each.value.name != null ? each.value.name : azurerm_log_analytics_workspace.this.name
  parent_id     = each.value.resource_id
}