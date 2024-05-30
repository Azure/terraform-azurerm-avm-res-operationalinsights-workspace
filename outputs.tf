output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = azurerm_private_endpoint.this
}

output "resource" {
  description = <<-EOT
  "This is the full output for the Log Analytics resource. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  Examples:
  - module.log_analytics.resource.id
  - module.log_analytics.resource.name
EOT
  value       = azurerm_log_analytics_workspace.this
}

output "resource_id" {
  description = "This is the full output for the Log Analytics resource ID. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  value       = azurerm_log_analytics_workspace.this.id
}
