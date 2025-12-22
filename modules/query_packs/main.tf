resource "azapi_resource" "query_packs" {
  for_each = var.monitor_query_packs

  location  = var.location
  name      = each.value.name
  parent_id = var.resource_group_id
  type      = "Microsoft.OperationalInsights/queryPacks@2019-09-01"
  body = {
    properties = {}
  }
  tags = merge(var.tags, try(each.value.tags, {}))
}

resource "random_uuid" "query_name" {
  for_each = { for k, v in var.monitor_queries : k => v if v.name == null }
}

resource "azapi_resource" "queries" {
  for_each = var.monitor_queries

  name      = each.value.name != null ? each.value.name : random_uuid.query_name[each.key].result
  parent_id = azapi_resource.query_packs[each.value.query_pack_key].id
  type      = "Microsoft.OperationalInsights/queryPacks/queries@2019-09-01"
  body = {
    properties = {
      body        = each.value.body
      displayName = each.value.display_name
      description = each.value.description
      tags        = each.value.tags
      related = each.value.related == null ? null : {
        categories    = each.value.related.categories
        resourceTypes = each.value.related.resource_types
        solutions     = each.value.related.solutions
      }
    }
  }
}

resource "azurerm_management_lock" "query_packs" {
  for_each = { for k, v in var.monitor_query_packs : k => v if v.lock != null }

  lock_level = each.value.lock.kind
  name       = try(each.value.lock.name, null) != null ? each.value.lock.name : "${azapi_resource.query_packs[each.key].name}-lock"
  scope      = azapi_resource.query_packs[each.key].id
}
