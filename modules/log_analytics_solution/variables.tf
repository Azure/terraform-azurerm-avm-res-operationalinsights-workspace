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

variable "log_analytics_solution_resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the Log Analytics solution is created. Changing this forces a new resource to be created. Note: The solution and its related workspace can only exist in the same resource group."
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
 - `create` - (Defaults to 30 minutes) Used when creating the Log Analytics Solution.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Log Analytics Solution.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Log Analytics Solution.
 - `update` - (Defaults to 30 minutes) Used when updating the Log Analytics Solution.
EOT
}
