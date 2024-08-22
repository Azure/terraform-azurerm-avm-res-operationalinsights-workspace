resource "azapi_resource" "ampls" {
  type     = "Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview"
  for_each = var.monitor_private_link_scoped_resource

  name          = each.value.name != null ? each.value.name : azurerm_log_analytics_workspace.this.name
  parent_id     = each.value.resource_id
  ignore_casing = true

  body = jsonencode({
    properties = {
      linkedResourceId = azurerm_log_analytics_workspace.this.id
    }
  })

}