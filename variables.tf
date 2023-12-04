variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "location" {
  type        = string
  default     = null
  description = "The Azure Region where the resources will be deployed."
}

variable "law_name" {
  type        = string
  description = "value of the law_name variable"
  validation {
    condition     = can(regex("^[a-z0-9-]{4,63}$", var.law_name))
    error_message = "The law_name must be a valid Log Analytics Workspace name."
  }
}

variable "law_sku" {
  type        = string
  description = "value of the sku of the Log Analytics Workspace"
  default     = "PerGB2018"
}

variable "retention_in_days" {
  type        = number
  description = "Workspace data retention in days. Possible values range between 30 and 730."
  validation {
    condition     = var.retention_in_days == null ? true : var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "The retention_in_days must be between 30 and 730."
  }
}

variable "allow_resource_only_permissions" {
  type        = bool
  description = "value of users accessing to data associated with resources they have permission to view, without permission to workspace"
  validation {
    condition     = var.allow_resource_only_permissions == null ? true : contains([true, false], var.allow_resource_only_permissions)
    error_message = "The allow_resource_only_permissions must be one of: 'true' or 'false'."
  }
}

variable "identity" {
  type = object({
    type         = optional(string)
    identity_ids = optional(set(string))
  })
  description = <<DESCRIPTION
 The Identity block supports the following:

  - `type` - (Required) The type of identity being used for the Log Analytics Workspace. Possible values are `SystemAssigned` and `UserAssigned`.
  - `identity_ids` - (Optional) A set of User Assigned Identity's ids which should be associated with the Log Analytics Workspace. This argument is only valid when `type` is set to `UserAssigned`.

 Example Usage
  ```terraform
  identity = {
    type = "UserAssigned"
    identity_ids = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  }
  ```
DESCRIPTION
  validation {
    condition     = length(var.identity) == 0 ? true : contains(["SystemAssigned", "UserAssigned"], var.identity.type)
    error_message = "The identity type must be one of: 'SystemAssigned' or 'UserAssigned'."
  }
}

variable "local_auth_disabled" {
  type        = bool
  description = "value if law should enfore auth using Entra ID"
  validation {
    condition     = var.local_auth_disabled == null ? true : contains([true, false], var.local_auth_disabled)
    error_message = "The local_auth_disabled must be one of: 'true' or 'false'."
  }
}

variable "internet_ingestion_enabled" {
  type        = bool
  description = "value if law should allow internet ingestion over the public internet"
  validation {
    condition     = var.internet_ingestion_enabled == null ? true : contains([true, false], var.internet_ingestion_enabled)
    error_message = "The internet_ingestion_enabled must be one of: 'true' or 'false'."

  }
}

variable "internet_query_enabled" {
  type        = bool
  description = "value if law should allow internet query over the public internet"
  validation {
    condition     = var.internet_query_enabled == null ? true : contains([true, false], var.internet_query_enabled)
    error_message = "The internet_query_enabled must be one of: 'true' or 'false'."
  }
}

variable "diagnostic_settings" {
  type = map(object({
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
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
}


variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, true)
    condition                              = optional(string, null)
    condition_version                      = optional(string, "2.0")
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  description = "The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}


# Example resource implementation

variable "tags" {
  type = map(any)
  default = {
  }
  description = <<DESCRIPTION
The tags to associate with your network and subnets.
DESCRIPTION
}