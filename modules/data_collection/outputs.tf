output "data_collection_endpoint_ids" {
  description = "The Resource IDs of the Data Collection Endpoints."
  value       = { for k, v in azapi_resource.data_collection_endpoint : k => v.id }
}

output "data_collection_rule_association_ids" {
  description = "The Resource IDs of the Data Collection Rule Associations."
  value       = { for k, v in azapi_resource.data_collection_rule_association : k => v.id }
}

output "data_collection_rule_ids" {
  description = "The Resource IDs of the Data Collection Rules."
  value       = { for k, v in azapi_resource.data_collection_rule : k => v.id }
}

output "resource_id" {
  description = "The resource ID of the primary resource. In this case, it returns null as this module creates multiple resources."
  value       = null
}
