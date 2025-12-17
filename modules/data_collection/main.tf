resource "azapi_resource" "data_collection_endpoint" {
  for_each = var.data_collection_endpoints

  location  = var.location
  name      = each.value.name
  parent_id = var.resource_group_id
  type      = "Microsoft.Insights/dataCollectionEndpoints@2022-06-01"
  body = {
    properties = {
      description = each.value.description
      networkAcls = {
        publicNetworkAccess = each.value.public_network_access_enabled
      }
    }
  }
  tags = merge(var.tags, each.value.tags)
}

resource "azapi_resource" "dce_nsp_association" {
  for_each = { for k, v in var.data_collection_endpoints : k => v if v.network_security_perimeter_association != null }

  name      = "nsp-assoc-${each.value.name}"
  parent_id = each.value.network_security_perimeter_association.resource_id
  type      = "Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview"
  body = {
    properties = {
      privateLinkResource = {
        id = azapi_resource.data_collection_endpoint[each.key].id
      }
      profile = {
        id = "${each.value.network_security_perimeter_association.resource_id}/profiles/${each.value.network_security_perimeter_association.profile_name}"
      }
      accessMode = each.value.network_security_perimeter_association.access_mode
    }
  }
}

resource "azapi_resource" "data_collection_rule" {
  for_each = var.data_collection_rules

  location  = var.location
  name      = each.value.name
  parent_id = var.resource_group_id
  type      = "Microsoft.Insights/dataCollectionRules@2022-06-01"
  body = {
    kind = try(each.value.kind, null)
    properties = {
      description = try(each.value.description, null)
      dataSources = try(each.value.data_sources, null)
      destinations = try(each.value.destinations, null) == null ? null : merge(
        each.value.destinations,
        try(each.value.destinations.logAnalytics, null) == null ? {} : {
          logAnalytics = [
            for d in each.value.destinations.logAnalytics : {
              name                = d.name
              workspaceResourceId = var.log_analytics_workspace_resource_id
            }
          ]
        }
      )
      dataFlows          = try(each.value.data_flows, null)
      streamDeclarations = try(each.value.stream_declarations, null)
    }
  }
  tags = merge(var.tags, try(each.value.tags, {}))
}

resource "azapi_resource" "data_collection_rule_association" {
  for_each = var.data_collection_rule_associations

  name      = each.value.name
  parent_id = each.value.target_resource_id
  type      = "Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01"
  body = {
    properties = {
      description              = each.value.description
      dataCollectionRuleId     = try(each.value.data_collection_rule_id, null) != null ? each.value.data_collection_rule_id : (try(each.value.data_collection_rule_name, null) != null ? azapi_resource.data_collection_rule[each.value.data_collection_rule_name].id : null)
      dataCollectionEndpointId = try(each.value.data_collection_endpoint_id, null) != null ? each.value.data_collection_endpoint_id : (try(each.value.data_collection_endpoint_name, null) != null ? azapi_resource.data_collection_endpoint[each.value.data_collection_endpoint_name].id : null)
    }
  }
}

resource "azurerm_management_lock" "data_collection_endpoint" {
  for_each = { for k, v in var.data_collection_endpoints : k => v if v.lock != null }

  lock_level = each.value.lock.kind
  name       = try(each.value.lock.name, null) != null ? each.value.lock.name : "${each.value.name}-lock"
  scope      = azapi_resource.data_collection_endpoint[each.key].id
}

resource "azurerm_management_lock" "data_collection_rule" {
  for_each = { for k, v in var.data_collection_rules : k => v if v.lock != null }

  lock_level = each.value.lock.kind
  name       = try(each.value.lock.name, null) != null ? each.value.lock.name : "${each.value.name}-lock"
  scope      = azapi_resource.data_collection_rule[each.key].id
}
