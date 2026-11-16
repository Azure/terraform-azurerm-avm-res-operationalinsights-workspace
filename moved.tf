# The resources that versions 0.5.x and earlier managed with the AzureRM provider moved to AzAPI. They are
# adopted in place and updated with the same settings.
moved {
  from = azurerm_log_analytics_workspace.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

moved {
  from = azurerm_log_analytics_linked_service.this
  to   = azapi_resource.linked_service
}

moved {
  from = azurerm_log_analytics_linked_storage_account.this
  to   = azapi_resource.linked_storage_accounts
}

moved {
  from = azurerm_private_endpoint.this
  to   = azapi_resource.private_endpoints
}

moved {
  from = azurerm_private_endpoint.this_unmanaged
  to   = azapi_resource.private_endpoints_unmanaged
}

moved {
  from = azurerm_monitor_private_link_scoped_service.this
  to   = azapi_resource.amplscope_scoped_service
}

moved {
  from = azurerm_management_lock.amplscope
  to   = azapi_resource.amplscope_lock
}

# The public network access settings, including `SecuredByPerimeter`, are now part of the workspace.
removed {
  from = azapi_update_resource.this

  lifecycle {
    destroy = false
  }
}

# Application security groups are now set on the private endpoints. The associations are removed from the
# state and kept in Azure.
removed {
  from = azurerm_private_endpoint_application_security_group_association.this

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_private_endpoint_application_security_group_association.this_unmanaged

  lifecycle {
    destroy = false
  }
}
