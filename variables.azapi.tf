variable "ignore_body_changes" {
  type = object({
    authorization_locks                                       = optional(list(string), [])
    authorization_role_assignments                            = optional(list(string), [])
    insights_private_link_scopes                              = optional(list(string), [])
    insights_private_link_scopes_scoped_resources             = optional(list(string), [])
    network_network_security_perimeters_resource_associations = optional(list(string), [])
    operationalinsights_workspaces_data_exports               = optional(list(string), [])
    operationalinsights_workspaces_tables                     = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot paths to ignore on AzAPI resources that support this argument.
The provider does not support this setting on `azapi_update_resource`.
Changes take effect only after apply.
Ignored configuration is not sent to Azure until its path is removed.
Non-empty lists require Terraform 1.11 or later.

- `authorization_locks` - Paths ignored on private endpoint management locks.
- `authorization_role_assignments` - Paths ignored on private endpoint role assignments.
- `insights_private_link_scopes` - Paths ignored on newly managed Monitor Private Link Scopes.
- `insights_private_link_scopes_scoped_resources` - Paths ignored on scoped resources.
- `network_network_security_perimeters_resource_associations` - Paths ignored on NSP associations.
- `operationalinsights_workspaces_data_exports` - Paths ignored on workspace data exports.
- `operationalinsights_workspaces_tables` - Paths ignored on newly managed workspace tables.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_locks                                       = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                            = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_private_link_scopes                              = optional(string, "microsoft.insights/privateLinkScopes@2021-07-01-preview")
    insights_private_link_scopes_scoped_resources             = optional(string, "Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview")
    network_network_security_perimeters_resource_associations = optional(string, "Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview")
    operationalinsights_workspaces                            = optional(string, "Microsoft.OperationalInsights/workspaces@2023-09-01")
    operationalinsights_workspaces_data_exports               = optional(string, "Microsoft.OperationalInsights/workspaces/dataExports@2020-08-01")
    operationalinsights_workspaces_tables                     = optional(string, "Microsoft.OperationalInsights/workspaces/tables@2022-10-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions. Defaults preserve the existing API versions.

- `authorization_locks` - Private endpoint management locks.
- `authorization_role_assignments` - Private endpoint role assignments.
- `insights_private_link_scopes` - Monitor Private Link Scopes and their updates.
- `insights_private_link_scopes_scoped_resources` - Resources connected to existing scopes.
- `network_network_security_perimeters_resource_associations` - NSP associations.
- `operationalinsights_workspaces` - Workspace network-access updates.
- `operationalinsights_workspaces_data_exports` - Workspace data exports.
- `operationalinsights_workspaces_tables` - Workspace tables and table updates.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every supported AzAPI resource declared by this module.
Defaults to null (no custom retry).

- `error_message_regex` - Error-message patterns that trigger a retry.
- `interval_seconds` - Initial interval between retries in seconds.
- `max_interval_seconds` - Maximum interval between retries in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Per-operation timeouts applied to every supported AzAPI resource declared by this module.
Defaults to null (provider defaults). Values are Go duration strings.

- `create` - Create timeout.
- `read` - Read timeout.
- `update` - Update timeout.
- `delete` - Delete timeout.
DESCRIPTION
}
