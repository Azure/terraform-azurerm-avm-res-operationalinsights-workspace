<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-operationalinsights-workspace

This repo is to deploy an Log Anayltics Workspace

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (3.83.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.5.1)

## Resources

The following resources are used by this module:

- [azurerm_log_analytics_workspace.law](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_allow_resource_only_permissions"></a> [allow\_resource\_only\_permissions](#input\_allow\_resource\_only\_permissions)

Description: value of users accessing to data associated with resources they have permission to view, without permission to workspace

Type: `bool`

### <a name="input_identity"></a> [identity](#input\_identity)

Description:  The Identity block supports the following:

  - `type` - (Required) The type of identity being used for the Log Analytics Workspace. Possible values are `SystemAssigned` and `UserAssigned`.
  - `identity_ids` - (Optional) A set of User Assigned Identity's ids which should be associated with the Log Analytics Workspace. This argument is only valid when `type` is set to `UserAssigned`.

 Example Usage
  ```terraform
  identity = {
    type = "UserAssigned"
    identity_ids = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  }
```

Type:

```hcl
object({
    type         = optional(string)
    identity_ids = optional(set(string))
  })
```

### <a name="input_internet_ingestion_enabled"></a> [internet\_ingestion\_enabled](#input\_internet\_ingestion\_enabled)

Description: value if law should allow internet ingestion over the public internet

Type: `bool`

### <a name="input_internet_query_enabled"></a> [internet\_query\_enabled](#input\_internet\_query\_enabled)

Description: value if law should allow internet query over the public internet

Type: `bool`

### <a name="input_law_name"></a> [law\_name](#input\_law\_name)

Description: value of the law\_name variable

Type: `string`

### <a name="input_local_auth_disabled"></a> [local\_auth\_disabled](#input\_local\_auth\_disabled)

Description: value if law should enfore auth using Entra ID

Type: `bool`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days)

Description: Workspace data retention in days. Possible values range between 30 and 730.

Type: `number`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: n/a

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories_and_groups                = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_law_sku"></a> [law\_sku](#input\_law\_sku)

Description: value of the sku of the Log Analytics Workspace

Type: `string`

Default: `"PerGB2018"`

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure Region where the resources will be deployed.

Type: `string`

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
```

Default: `{}`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: n/a

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, true)
    condition                              = optional(string, null)
    condition_version                      = optional(string, "2.0")
    delegated_managed_identity_resource_id = optional(string)
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to associate with your network and subnets.

Type: `map(any)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: TODO: insert outputs here.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->