output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = merge(azurerm_private_endpoint.this, azurerm_private_endpoint.this_unmanaged)
}

output "resource" {
  description = <<-EOT
  "This is the full output for the Log Analytics resource. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  Examples:
  - module.log_analytics.resource.id
  - module.log_analytics.resource.name
EOT
  sensitive = true
  value = {
    id                                 = azurerm_log_analytics_workspace.this.id
    name                               = azurerm_log_analytics_workspace.this.name
    location                           = azurerm_log_analytics_workspace.this.location
    resource_group_name                = azurerm_log_analytics_workspace.this.resource_group_name
    workspace_id                       = azurerm_log_analytics_workspace.this.workspace_id
    sku                                = azurerm_log_analytics_workspace.this.sku
    retention_in_days                  = azurerm_log_analytics_workspace.this.retention_in_days
    daily_quota_gb                     = azurerm_log_analytics_workspace.this.daily_quota_gb
    internet_ingestion_enabled         = azurerm_log_analytics_workspace.this.internet_ingestion_enabled
    internet_query_enabled             = azurerm_log_analytics_workspace.this.internet_query_enabled
    local_authentication_enabled       = azurerm_log_analytics_workspace.this.local_authentication_enabled
    allow_resource_only_permissions    = azurerm_log_analytics_workspace.this.allow_resource_only_permissions
    cmk_for_query_forced               = azurerm_log_analytics_workspace.this.cmk_for_query_forced
    reservation_capacity_in_gb_per_day = azurerm_log_analytics_workspace.this.reservation_capacity_in_gb_per_day
    primary_shared_key                 = azurerm_log_analytics_workspace.this.primary_shared_key
    secondary_shared_key               = azurerm_log_analytics_workspace.this.secondary_shared_key
    tags                               = azurerm_log_analytics_workspace.this.tags
  }
}

output "resource_id" {
  description = "This is the full output for the Log Analytics resource ID. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  value       = azurerm_log_analytics_workspace.this.id
}
