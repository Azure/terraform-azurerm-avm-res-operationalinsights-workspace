resource "azapi_resource" "tables" {
  for_each = var.log_analytics_workspace_tables

  name      = each.value.name
  parent_id = each.value.resource_id != null ? each.value.resource_id : azurerm_log_analytics_workspace.this.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = {
    properties = {
      for k, v in {
        retentionInDays      = each.value.retention_in_days
        totalRetentionInDays = each.value.total_retention_in_days
        plan                 = each.value.plan
        schema = each.value.schema == null ? null : {
          for sk, sv in {
            name        = each.value.schema.name
            description = each.value.schema.description
            columns     = each.value.schema.columns
          } : sk => sv if sv != null
        }
      } : k => v if v != null
    }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_update_resource" "tables" {
  for_each = var.log_analytics_workspace_tables_update

  name      = each.value.name
  parent_id = each.value.resource_id != null ? each.value.resource_id : azurerm_log_analytics_workspace.this.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = {
    properties = {
      for k, v in {
        retentionInDays      = each.value.retention_in_days
        totalRetentionInDays = each.value.total_retention_in_days
        plan                 = each.value.plan
        schema = each.value.schema == null ? null : {
          for sk, sv in {
            name        = each.value.schema.name
            description = each.value.schema.description
            columns     = each.value.schema.columns
          } : sk => sv if sv != null
        }
      } : k => v if v != null
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
