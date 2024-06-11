output "resource" {
  description = "this is the resource of the rule collection group"
  value       = azurerm_log_analytics_solution.this
}

output "resource_id" {
  description = "the resource id of the rule_collection_group"
  value       = azurerm_log_analytics_solution.this.id
}
