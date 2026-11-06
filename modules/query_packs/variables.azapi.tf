variable "ignore_body_changes" {
  type = object({
    authorization_locks                     = optional(list(string), [])
    operationalinsights_query_packs         = optional(list(string), [])
    operationalinsights_query_packs_queries = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot paths to ignore on the AzAPI resources of this module.
Changes take effect only after apply.
Ignored configuration is not sent to Azure until its path is removed.

- `authorization_locks` - Paths ignored on the query pack management locks.
- `operationalinsights_query_packs` - Paths ignored on the query packs.
- `operationalinsights_query_packs_queries` - Paths ignored on the queries.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_locks                     = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    operationalinsights_query_packs         = optional(string, "Microsoft.OperationalInsights/queryPacks@2019-09-01")
    operationalinsights_query_packs_queries = optional(string, "Microsoft.OperationalInsights/queryPacks/queries@2019-09-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions, in `<provider>/<resource>@<api-version>` form. Each key defaults to a tested value; supply only the keys you want to override.

- `authorization_locks` - The query pack management locks.
- `operationalinsights_query_packs` - The query packs.
- `operationalinsights_query_packs_queries` - The queries.
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
Retry configuration applied to every AzAPI resource of this module.
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
Per-operation timeouts applied to every AzAPI resource of this module.
Defaults to null (provider defaults). Values are Go duration strings.

- `create` - Create timeout.
- `read` - Read timeout.
- `update` - Update timeout.
- `delete` - Delete timeout.
DESCRIPTION
}
