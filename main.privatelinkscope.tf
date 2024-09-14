resource "azapi_resource" "amplscope" {
  for_each = var.monitor_private_link_scope

  type = "microsoft.insights/privateLinkScopes@2021-07-01-preview"
  body = {
    properties = {
      accessModeSettings = {
        exclusions = [
          {
            ingestionAccessMode           = "PrivateOnly"
            privateEndpointConnectionName = "azurerm_private_endpoint.this.private_service_connection.name"
            queryAccessMode               = "PrivateOnly"
          }
        ]
        ingestionAccessMode = "PrivateOnly"
        queryAccessMode     = "PrivateOnly"
      }
    }
  }
  location                  = "global"
  name                      = each.value.name != null ? each.value.name : "law_pl_scope"
  parent_id                 = each.value.resource_id
  schema_validation_enabled = false
  tags                      = var.tags
}

resource "azurerm_monitor_private_link_scoped_service" "this" {
  for_each = var.monitor_private_link_scope

  linked_resource_id  = azurerm_log_analytics_workspace.this.id
  name                = var.monitor_private_link_scoped_service_name
  resource_group_name = var.resource_group_name
  scope_name          = azapi_resource.amplscope[each.key].name
}

resource "azapi_resource" "ampls" {
  for_each = var.monitor_private_link_scoped_resource

  type = "Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview"
  body = {
    properties = {
      linkedResourceId = azurerm_log_analytics_workspace.this.id
    }
  }
  ignore_casing = true
  name          = each.value.name != null ? each.value.name : azurerm_log_analytics_workspace.this.name
  parent_id     = each.value.resource_id
}

