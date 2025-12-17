output "query_pack_resource_ids" {
  description = "A map of resource IDs for the created Query Packs."
  value       = { for k, v in azapi_resource.query_packs : k => v.id }
}

output "query_resource_ids" {
  description = "A map of resource IDs for the created Queries."
  value       = { for k, v in azapi_resource.queries : k => v.id }
}

output "resource_id" {
  description = "The resource ID of the primary resource. In this case, it returns null as this module creates multiple resources."
  value       = null
}
