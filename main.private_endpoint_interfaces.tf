module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location         = var.location
  enable_telemetry = false
  private_endpoints = {
    for k, v in var.private_endpoints : k => merge(v, {
      lock = try(v.lock.kind, "None") == "None" ? null : v.lock
    })
  }
  private_endpoints_scope = azurerm_log_analytics_workspace.this.id
  role_assignment_definition_lookup_enabled = anytrue(flatten([
    for pe in var.private_endpoints : [
      for ra in pe.role_assignments :
      !strcontains(lower(ra.role_definition_id_or_name), "/providers/microsoft.authorization/roledefinitions/")
    ]
  ]))
  role_assignment_definition_scope = azurerm_log_analytics_workspace.this.id
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = module.avm_interfaces.role_assignments_private_endpoint_azapi

  name                   = each.value.name
  parent_id              = local.private_endpoint_manage_dns_zone_group[each.value.pe_key] ? azurerm_private_endpoint.this[each.value.pe_key].id : azurerm_private_endpoint.this_unmanaged[each.value.pe_key].id
  type                   = var.resource_types.authorization_role_assignments
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = module.avm_interfaces.lock_private_endpoint_azapi

  name                   = coalesce(each.value.name, "lock-${lower(each.value.body.properties.level)}")
  parent_id              = local.private_endpoint_manage_dns_zone_group[each.value.pe_key] ? azurerm_private_endpoint.this[each.value.pe_key].id : azurerm_private_endpoint.this_unmanaged[each.value.pe_key].id
  type                   = var.resource_types.authorization_locks
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource.private_endpoint_role_assignments,
    azurerm_private_endpoint_application_security_group_association.this,
    azurerm_private_endpoint_application_security_group_association.this_unmanaged,
    azapi_update_resource.amplscope_update,
    azapi_update_resource.amplscope_update_existing,
  ]
}
