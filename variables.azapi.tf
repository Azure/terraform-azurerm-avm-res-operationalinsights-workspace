variable "ignore_body_changes" {
  type = object({
    authorization_locks                                       = optional(list(string), [])
    authorization_role_assignments                            = optional(list(string), [])
    insights_diagnostic_settings                              = optional(list(string), [])
    insights_private_link_scopes                              = optional(list(string), [])
    insights_private_link_scopes_scoped_resources             = optional(list(string), [])
    network_network_security_perimeters_resource_associations = optional(list(string), [])
    network_private_endpoints                                 = optional(list(string), [])
    network_private_endpoints_private_dns_zone_groups         = optional(list(string), [])
    operationalinsights_workspaces                            = optional(list(string), [])
    operationalinsights_workspaces_data_exports               = optional(list(string), [])
    operationalinsights_workspaces_linked_services            = optional(list(string), [])
    operationalinsights_workspaces_linked_storage_accounts    = optional(list(string), [])
    operationalinsights_workspaces_tables                     = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot paths to ignore on AzAPI resources that support this argument.
The provider does not support this setting on `azapi_update_resource`.
Changes take effect only after apply.
Ignored configuration is not sent to Azure until its path is removed.

- `authorization_locks` - Paths ignored on the management locks of the workspace, Monitor Private Link Scopes and private endpoints.
- `authorization_role_assignments` - Paths ignored on the role assignments of the workspace and private endpoints.
- `insights_diagnostic_settings` - Paths ignored on diagnostic settings.
- `insights_private_link_scopes` - Paths ignored on newly managed Monitor Private Link Scopes.
- `insights_private_link_scopes_scoped_resources` - Paths ignored on scoped resources.
- `network_network_security_perimeters_resource_associations` - Paths ignored on NSP associations.
- `network_private_endpoints` - Paths ignored on private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Paths ignored on private DNS zone groups.
- `operationalinsights_workspaces` - Paths ignored on the workspace.
- `operationalinsights_workspaces_data_exports` - Paths ignored on workspace data exports.
- `operationalinsights_workspaces_linked_services` - Paths ignored on the dedicated cluster link.
- `operationalinsights_workspaces_linked_storage_accounts` - Paths ignored on linked storage accounts.
- `operationalinsights_workspaces_tables` - Paths ignored on newly managed workspace tables.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_locks                                       = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                            = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_diagnostic_settings                              = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    insights_private_link_scopes                              = optional(string, "microsoft.insights/privateLinkScopes@2021-07-01-preview")
    insights_private_link_scopes_scoped_resources             = optional(string, "Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview")
    network_network_security_perimeters_resource_associations = optional(string, "Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview")
    network_private_endpoints                                 = optional(string, "Microsoft.Network/privateEndpoints@2025-01-01")
    network_private_endpoints_private_dns_zone_groups         = optional(string, "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-01-01")
    operationalinsights_workspaces                            = optional(string, "Microsoft.OperationalInsights/workspaces@2023-09-01")
    operationalinsights_workspaces_data_exports               = optional(string, "Microsoft.OperationalInsights/workspaces/dataExports@2020-08-01")
    operationalinsights_workspaces_linked_services            = optional(string, "Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01")
    operationalinsights_workspaces_linked_storage_accounts    = optional(string, "Microsoft.OperationalInsights/workspaces/linkedStorageAccounts@2020-08-01")
    operationalinsights_workspaces_tables                     = optional(string, "Microsoft.OperationalInsights/workspaces/tables@2022-10-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions, in `<provider>/<resource>@<api-version>` form. Each key defaults to a tested value; supply only the keys you want to override.

- `authorization_locks` - The management locks of the workspace, Monitor Private Link Scopes and private endpoints.
- `authorization_role_assignments` - The role assignments of the workspace and private endpoints.
- `insights_diagnostic_settings` - Diagnostic settings.
- `insights_private_link_scopes` - Monitor Private Link Scopes and their updates.
- `insights_private_link_scopes_scoped_resources` - The workspace's connections to Monitor Private Link Scopes.
- `network_network_security_perimeters_resource_associations` - NSP associations.
- `network_private_endpoints` - Private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Private DNS zone groups.
- `operationalinsights_workspaces` - The workspace, and reading its shared keys.
- `operationalinsights_workspaces_data_exports` - Workspace data exports.
- `operationalinsights_workspaces_linked_services` - The dedicated cluster link.
- `operationalinsights_workspaces_linked_storage_accounts` - Linked storage accounts.
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
The workspace uses `log_analytics_workspace_timeouts` first, for the operations that it sets.
Defaults to null (provider defaults). Values are Go duration strings.

- `create` - Create timeout.
- `read` - Read timeout.
- `update` - Update timeout.
- `delete` - Delete timeout.
DESCRIPTION
}
