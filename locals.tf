locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : [
        for pl_k, pl_v in var.monitor_private_link_scope : {
          asg_key         = asg_k
          pe_key          = pe_k
          asg_resource_id = asg_v
          pl_key          = pl_k
        }
      ]
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}-${assoc.pl_key}" => assoc }
}

locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}