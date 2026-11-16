# The management locks moved from the AzureRM provider to AzAPI. They are adopted in place.
moved {
  from = azurerm_management_lock.query_packs
  to   = azapi_resource.query_pack_locks
}
