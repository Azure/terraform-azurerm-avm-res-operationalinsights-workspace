resource "azurerm_log_analytics_workspace" "this" {
  location                           = var.location
  name                               = var.name
  resource_group_name                = var.resource_group_name
  allow_resource_only_permissions    = var.log_analytics_workspace_allow_resource_only_permissions
  cmk_for_query_forced               = var.log_analytics_workspace_cmk_for_query_forced
  daily_quota_gb                     = var.log_analytics_workspace_daily_quota_gb
  internet_ingestion_enabled         = var.log_analytics_workspace_internet_ingestion_enabled == "true" ? true : false
  internet_query_enabled             = var.log_analytics_workspace_internet_query_enabled == "true" ? true : false
  local_authentication_enabled       = var.log_analytics_workspace_local_authentication_enabled
  reservation_capacity_in_gb_per_day = var.log_analytics_workspace_reservation_capacity_in_gb_per_day
  retention_in_days                  = var.log_analytics_workspace_retention_in_days
  sku                                = var.log_analytics_workspace_sku
  tags                               = var.tags

  dynamic "identity" {
    for_each = var.log_analytics_workspace_identity == null ? [] : [var.log_analytics_workspace_identity]

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  dynamic "timeouts" {
    for_each = var.log_analytics_workspace_timeouts == null ? [] : [var.log_analytics_workspace_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_update_resource" "this" {
  count = (var.log_analytics_workspace_internet_ingestion_enabled == "SecuredByPerimeter" || var.log_analytics_workspace_internet_query_enabled == "SecuredByPerimeter") ? 1 : 0

  resource_id = azurerm_log_analytics_workspace.this.id
  type        = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      publicNetworkAccessForIngestion = var.log_analytics_workspace_internet_ingestion_enabled == "SecuredByPerimeter" ? "SecuredByPerimeter" : (var.log_analytics_workspace_internet_ingestion_enabled == "true" ? "Enabled" : "Disabled")
      publicNetworkAccessForQuery     = var.log_analytics_workspace_internet_query_enabled == "SecuredByPerimeter" ? "SecuredByPerimeter" : (var.log_analytics_workspace_internet_query_enabled == "true" ? "Enabled" : "Disabled")
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

