# terraform-azurerm-avm-res-operationalinsights-workspace

This repo is to deploy an Log Analytics Workspace.

Private endpoints keep their existing names and defaults.
`private_endpoints_manage_dns_zone_group` defaults to `true`; an explicit
`private_endpoint_extensions[key].manage_dns_zone_group` takes precedence.
Omitted service names default to `azuremonitor`; omitted IP configuration member
and subresource names retain `privatelink`. Endpoint resource groups accept names
or resource IDs. Endpoint role assignments and locks are applied when supplied;
these previously declared settings were not implemented.

## Upgrading from 0.5.x or earlier

The workspace and the resources around it are now AzAPI resources, and the module no longer uses the AzureRM provider. `moved` blocks carry the workspace, its lock, diagnostic settings, role assignments, linked service and linked storage accounts, the private endpoints, the Monitor Private Link Scope scoped services and the scope locks to their new addresses in the state, so nothing is recreated. The same applies to the solution of the `log_analytics_solution` submodule and the query pack locks of the `query_packs` submodule. Terraform 1.16 or later is required.

1. Keep the AzureRM provider's `provider` block in your root module until the upgrade has been applied. Terraform needs it to remove the application security group associations from the state.
1. A `ReadOnly` lock blocks the upgrade, because the workspace, the resources under it and the private endpoints are updated. Change it to `CanNotDelete`, or remove it, until the upgrade is applied.
1. If the module manages the private DNS zone group of a private endpoint, that is with `private_dns_zone_resource_ids` set and `manage_dns_zone_group` not `false`, set `avm_managed_migration_enabled = true` for the upgrade apply. The zone group is now a separate resource, and the flag makes the module import the existing zone group rather than fail with `Resource already exists`. Remove the flag after the upgrade. Leave it unset on a new deployment, because a zone group that does not exist yet cannot be imported.
1. The `log_analytics_solution` submodule now deploys AVM telemetry, which needs its new `location` input. Set `location` to the solution's region, or set `enable_telemetry = false`.
1. Cross-tenant role assignments, which set `delegated_managed_identity_resource_id`, need extra steps. The AzureRM provider stored their ID with a `|<tenant-id>` suffix that the `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module:

   ```pwsh
   terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
   ```

   ```hcl
   import {
     to = module.<module-name>.azapi_resource.role_assignments["<key>"]
     id = "<role assignment resource ID, without the |<tenant-id> suffix>"
   }
   ```

1. Run `terraform init -upgrade`, then `terraform plan`. The plan must not destroy or replace anything except the AVM telemetry deployment, whose name includes the module version. It updates the moved resources in place with the same settings. Attributes of the `resource` and `private_endpoints` outputs that come from Azure are known only after apply in this plan, except the IDs, `workspace_id` and the shared keys. The plan also adds:
   - a `random_uuid` for each role assignment, which only exists in the state. The assignments keep their names;
   - a `time_sleep` for each lock, which pauses for 30 seconds when the lock is removed;
   - the imported private DNS zone groups, when `avm_managed_migration_enabled` is set;
   - AVM telemetry resources, when telemetry is enabled. The telemetry resources of 0.5.x or earlier are removed from the state without being destroyed.

   The application security group associations, and the update that set `SecuredByPerimeter` network access, are removed from the state without being changed in Azure. Application security groups and network access are now set on the private endpoints and the workspace.
1. Apply the plan. Later plans report no changes, except that, when telemetry is enabled, each plan updates the AVM telemetry deployment to record the apply.

Linking a dedicated cluster with `log_analytics_workspace_dedicated_cluster_resource_id` has not been tested with a real cluster.

Other changes:

- `parent_id` can be set instead of `resource_group_name`.
- `resource_types`, `retry`, `timeouts` and `ignore_body_changes` cover all the module's resources, and the submodules accept them too. `log_analytics_workspace_timeouts` falls back to `timeouts` for each operation that it does not set.
- `lock` accepts `notes`, and `role_assignments` accepts `name`.
- The `resource` output keeps the attribute names of the `azurerm_log_analytics_workspace` resource, and the `private_endpoints` output those of the `azurerm_private_endpoint` resource. The new `name` output returns the workspace name.
- Role names are matched, ignoring case, against the role definitions that can be assigned in the resource group, and an unknown name fails during plan.
- Changing the SKU updates the workspace in place. The AzureRM provider recreated the workspace for most SKU changes.
- The linked service of a dedicated cluster now gets the module's `tags`.
- Locks on the workspace, private endpoints, Monitor Private Link Scopes and query packs are removed 30 seconds before the resources they protect, because Azure keeps enforcing a deleted lock for a few seconds.

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>
