locals {
  private_endpoint_manage_dns_zone_group = {
    for k, v in var.private_endpoints : k => coalesce(
      try(var.private_endpoint_extensions[k].manage_dns_zone_group, null),
      var.private_endpoints_manage_dns_zone_group
    )
  }
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}

locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
