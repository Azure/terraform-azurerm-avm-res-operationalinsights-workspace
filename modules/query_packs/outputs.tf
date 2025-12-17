output "query_pack_resource_ids" {
  value = { for k, v in azapi_resource.query_packs : k => v.id }
}

output "query_resource_ids" {
  value = { for k, v in azapi_resource.queries : k => v.id }
}
