output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
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
  value       = module.log_analytics.resource_id
}
