resource "azapi_resource" "query_packs" {
  for_each = var.monitor_query_packs

  location  = var.location
  name      = each.value.name
  parent_id = var.resource_group_id
  type      = var.resource_types.operationalinsights_query_packs
  body = {
    properties = {}
  }
  ignore_body_changes    = length(var.ignore_body_changes.operationalinsights_query_packs) > 0 ? var.ignore_body_changes.operationalinsights_query_packs : null
  response_export_values = []
  retry                  = var.retry
  tags                   = merge(var.tags, try(each.value.tags, {}))

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "random_uuid" "query_name" {
  for_each = { for k, v in var.monitor_queries : k => v if v.name == null }
}

resource "azapi_resource" "queries" {
  for_each = var.monitor_queries

  name      = each.value.name != null ? each.value.name : random_uuid.query_name[each.key].result
  parent_id = azapi_resource.query_packs[each.value.query_pack_key].id
  type      = var.resource_types.operationalinsights_query_packs_queries
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
  ignore_body_changes    = length(var.ignore_body_changes.operationalinsights_query_packs_queries) > 0 ? var.ignore_body_changes.operationalinsights_query_packs_queries : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "query_pack_locks" {
  for_each = { for k, v in var.monitor_query_packs : k => v if v.lock != null }

  name      = try(each.value.lock.name, null) != null ? each.value.lock.name : "${azapi_resource.query_packs[each.key].name}-lock"
  parent_id = azapi_resource.query_packs[each.key].id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = each.value.lock.kind
      # The empty notes that earlier versions of this module wrote, so that upgrading leaves the lock unchanged.
      notes = ""
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [time_sleep.query_pack_lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzAPI provider does not wait for it to be
# gone as the AzureRM provider did. This pause is destroyed after the lock and before the query pack and its
# queries.
resource "time_sleep" "query_pack_lock_removal" {
  for_each = { for k, v in var.monitor_query_packs : k => v if v.lock != null }

  destroy_duration = "30s"
  # Replacing the query pack replaces its lock, so the pause is replaced with them.
  triggers = {
    query_pack_id = azapi_resource.query_packs[each.key].id
  }

  depends_on = [azapi_resource.queries]
}
