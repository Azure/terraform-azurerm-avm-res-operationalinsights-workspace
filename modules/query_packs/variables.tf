variable "location" {
  type        = string
  description = "(Required) The Azure region where the resources should be deployed."
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "(Required) The Resource ID of the Resource Group where the resources will be deployed."
  nullable    = false
}

variable "monitor_queries" {
  type = map(object({
    name           = optional(string)
    query_pack_key = string
    body           = string
    display_name   = string
    description    = optional(string)
    tags           = optional(map(string))
    related = optional(object({
      categories     = optional(list(string))
      resource_types = optional(list(string))
      solutions      = optional(list(string))
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
(Optional) A map of Queries to create. The key is the name of the Query. The value is an object containing the configuration.
- `name` - (Optional) The name of the Query. This must be a GUID. If not provided, a UUID will be generated.
- `query_pack_key` - (Required) The key of the Query Pack to associate this Query with.
- `body` - (Required) The KQL query body.
- `display_name` - (Required) The display name of the query.
- `description` - (Optional) The description of the query.
- `tags` - (Optional) A map of tags to assign to the query.
- `related` - (Optional) A map of related items.
  - `categories` - (Optional) A list of categories for the query. Supported values: `security`, `network`, `management`, `virtualmachines`, `container`, `audit`, `desktopanalytics`, `workloads`, `resources`, `applications`, `monitor`, `databases`, `windowsvirtualdesktop`.
  - `resource_types` - (Optional) A list of resource types the query applies to. Example: `["Microsoft.Compute/virtualMachines"]`.
  - `solutions` - (Optional) A list of solutions the query is related to. Example: `["LogManagement"]`.
DESCRIPTION

  validation {
    condition     = alltrue([for k, v in var.monitor_queries : v.name == null || can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", v.name))])
    error_message = "The name of the query must be a valid GUID."
  }
}

variable "monitor_query_packs" {
  type = map(object({
    name = string
    tags = optional(map(string))
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
(Optional) A map of Query Packs to create. The key is the name of the Query Pack. The value is an object containing the configuration.
- `name` - (Required) The name of the Query Pack.
- `tags` - (Optional) A map of tags to assign to the Query Pack.
- `lock` - (Optional) Controls the Resource Lock configuration for this resource. The following properties can be specified:
  - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) A mapping of tags to assign to the resources."
}
