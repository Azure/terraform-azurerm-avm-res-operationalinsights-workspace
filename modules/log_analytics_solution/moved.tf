# The solution moved from the AzureRM provider to AzAPI. It is adopted in place and updated with the same
# settings.
moved {
  from = azurerm_log_analytics_solution.this
  to   = azapi_resource.this
}
