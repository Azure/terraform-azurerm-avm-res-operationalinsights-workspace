data "azapi_client_config" "current" {}

resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = local.parent_id
  type      = var.resource_types.operationalinsights_workspaces
  body = {
    properties = local.workspace_properties
  }
  # A workspace linked to a dedicated cluster reports the `LACluster` SKU, which the AzureRM provider kept.
  ignore_body_changes = var.log_analytics_workspace_dedicated_cluster_resource_id != null ? distinct(concat(["properties.sku"], var.ignore_body_changes.operationalinsights_workspaces)) : (length(var.ignore_body_changes.operationalinsights_workspaces) > 0 ? var.ignore_body_changes.operationalinsights_workspaces : null)
  response_export_values = {
    customer_id                         = "properties.customerId"
    daily_quota_gb                      = "properties.workspaceCapping.dailyQuotaGb"
    data_collection_rule_id             = "properties.defaultDataCollectionRuleResourceId"
    features                            = "properties.features"
    force_cmk_for_query                 = "properties.forceCmkForQuery"
    public_network_access_for_ingestion = "properties.publicNetworkAccessForIngestion"
    public_network_access_for_query     = "properties.publicNetworkAccessForQuery"
    retention_in_days                   = "properties.retentionInDays"
    sku                                 = "properties.sku"
  }
  retry = var.retry
  tags  = var.tags

  dynamic "identity" {
    for_each = var.log_analytics_workspace_identity == null ? [] : [var.log_analytics_workspace_identity]

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids == null ? [] : tolist(identity.value.identity_ids)
    }
  }

  dynamic "timeouts" {
    for_each = var.log_analytics_workspace_timeouts == null && var.timeouts == null ? [] : [local.workspace_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    precondition {
      condition     = (var.log_analytics_workspace_reservation_capacity_in_gb_per_day != null) == (var.log_analytics_workspace_sku == null ? false : lower(var.log_analytics_workspace_sku) == "capacityreservation")
      error_message = "`log_analytics_workspace_reservation_capacity_in_gb_per_day` must be set when, and only when, `log_analytics_workspace_sku` is `CapacityReservation`."
    }
  }
}

# The workspace's customer ID does not change, so it is read from Azure when the workspace already exists, rather
# than from the workspace resource, whose outputs are unknown while the workspace has changes pending. This keeps
# `workspace_id` known when planning the upgrade from an earlier version, so resources that use it are not
# changed. A workspace that is about to be created, or recreated in another region, uses the resource's value.
data "azapi_resource" "workspace" {
  name             = var.name
  parent_id        = local.parent_id
  type             = var.resource_types.operationalinsights_workspaces
  ignore_not_found = true
  response_export_values = {
    customer_id = "properties.customerId"
    location    = "location"
  }
}

# The AzureRM provider read the shared keys with the workspace. They are read here when the workspace is
# created, or upgraded from an earlier version of this module, and not on later plans: reading them is a POST,
# which a `ReadOnly` lock blocks. The lock is created after them.
resource "azapi_resource_action" "shared_keys" {
  action                           = "sharedKeys"
  method                           = "POST"
  resource_id                      = azapi_resource.this.id
  type                             = var.resource_types.operationalinsights_workspaces
  response_export_values           = []
  retry                            = var.retry
  sensitive_response_export_values = ["primarySharedKey", "secondarySharedKey"]

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Moving the workspace to another region recreates it with the same resource ID and new keys.
    replace_triggered_by = [azapi_resource.this.location]
  }
}

# While upgrading from an earlier version, the shared keys are also read during plan, so that they are known and
# resources that use them are not changed.
data "azapi_resource_action" "shared_keys" {
  count = var.avm_managed_migration_enabled ? 1 : 0

  action                           = "sharedKeys"
  method                           = "POST"
  resource_id                      = local.workspace_resource_id
  type                             = var.resource_types.operationalinsights_workspaces
  response_export_values           = []
  retry                            = var.retry
  sensitive_response_export_values = ["primarySharedKey", "secondarySharedKey"]

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      read = timeouts.value.read
    }
  }
}
