output "resource" {
  description = "this is the resource of the rule collection group"
  sensitive   = true
  value       = azurerm_monitor_private_link_scope.this
}

output "resource_id" {
  description = "the resource id of the rule_collection_group"
  value       = azurerm_monitor_private_link_scope.this.id
}
