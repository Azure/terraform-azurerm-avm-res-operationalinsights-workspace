variable "log_analytics_solution_location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  nullable    = false
}

variable "log_analytics_solution_plan" {
  type = object({
    product        = string
    promotion_code = optional(string)
    publisher      = string
  })
  description = <<-EOT
 - `product` - (Required) The product name of the solution. For example `OMSGallery/Containers`. Changing this forces a new resource to be created.
 - `promotion_code` - (Optional) A promotion code to be used with the solution. Changing this forces a new resource to be created.
 - `publisher` - (Required) The publisher of the solution. For example `Microsoft`. Changing this forces a new resource to be created.
EOT
  nullable    = false
}

variable "log_analytics_solution_solution_name" {
  type        = string
  description = "(Required) Specifies the name of the solution to be deployed. See [here for options](https://docs.microsoft.com/azure/log-analytics/log-analytics-add-solutions).Changing this forces a new resource to be created."
  nullable    = false
}

variable "log_analytics_solution_workspace_name" {
  type        = string
  description = "(Required) The full name of the Log Analytics workspace with which the solution will be linked. Changing this forces a new resource to be created."
  nullable    = false
}

variable "log_analytics_solution_workspace_resource_id" {
  type        = string
  description = "(Required) The full resource ID of the Log Analytics workspace with which the solution will be linked. Changing this forces a new resource to be created."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "(Required) The resource ID of the resource group in which to create the Log Analytics solution, for example `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg`. The solution and its workspace must be in the same resource group. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "location" {
  type        = string
  default     = null
  description = "The Azure region for this module's resources or telemetry deployment."

  validation {
    condition     = !var.enable_telemetry || var.location != null
    error_message = "The location must not be null when telemetry is enabled."
  }
}

variable "log_analytics_solution_tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

variable "log_analytics_solution_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
Per-operation timeouts for the Log Analytics Solution. An operation that is not set here uses `timeouts`, and otherwise the provider default. Values are Go duration strings.

 - `create` - Used when creating the Log Analytics Solution.
 - `delete` - Used when deleting the Log Analytics Solution.
 - `read` - Used when retrieving the Log Analytics Solution.
 - `update` - Used when updating the Log Analytics Solution.
EOT
}
