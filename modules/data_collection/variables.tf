variable "location" {
  type        = string
  description = "(Required) The Azure region where the resources should be deployed."
  nullable    = false
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "(Required) The Resource ID of the Log Analytics Workspace to associate with the Data Collection Rules."
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "(Required) The Resource ID of the Resource Group where the resources will be deployed."
  nullable    = false
}

variable "data_collection_endpoints" {
  type = map(object({
    name                          = string
    description                   = optional(string)
    public_network_access_enabled = optional(string, "Enabled")
    tags                          = optional(map(string))
    network_security_perimeter_association = optional(object({
      resource_id  = string
      profile_name = string
      access_mode  = string
    }))
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
(Optional) A map of Data Collection Endpoints to create. The key is the name of the endpoint. The value is an object containing the configuration.
- `name` - (Required) The name of the Data Collection Endpoint.
- `description` - (Optional) The description of the Data Collection Endpoint.
- `public_network_access_enabled` - (Optional) Whether public network access is enabled. Possible values are `Enabled`, `Disabled`, and `SecuredByPerimeter`. Defaults to `Enabled`.
- `tags` - (Optional) A map of tags to assign to the Data Collection Endpoint.
- `network_security_perimeter_association` - (Optional) An object defining the Network Security Perimeter association.
  - `resource_id` - (Required) The Resource ID of the Network Security Perimeter.
  - `profile_name` - (Required) The name of the Network Security Perimeter Profile.
  - `access_mode` - (Required) The access mode for the Network Security Perimeter.
- `lock` - (Optional) Controls the Resource Lock configuration for this resource. The following properties can be specified:
  - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION
}

variable "data_collection_rule_associations" {
  type = map(object({
    name                          = string
    target_resource_id            = string
    data_collection_rule_id       = optional(string)
    data_collection_endpoint_id   = optional(string)
    data_collection_rule_name     = optional(string)
    data_collection_endpoint_name = optional(string)
    description                   = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
(Optional) A map of Data Collection Rule Associations to create. The key is the name of the association. The value is an object containing the configuration.
- `name` - (Required) The name of the Data Collection Rule Association.
- `target_resource_id` - (Required) The Resource ID of the target resource.
- `data_collection_rule_id` - (Optional) The Resource ID of the Data Collection Rule.
- `data_collection_endpoint_id` - (Optional) The Resource ID of the Data Collection Endpoint.
- `data_collection_rule_name` - (Optional) The name of the Data Collection Rule to associate (if created in this module).
- `data_collection_endpoint_name` - (Optional) The name of the Data Collection Endpoint to associate (if created in this module).
- `description` - (Optional) The description of the Data Collection Rule Association.
DESCRIPTION
}

variable "data_collection_rules" {
  type = map(object({
    name        = string
    kind        = optional(string)
    description = optional(string)
    tags        = optional(map(string))
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))
    data_sources = optional(object({
      performanceCounters = optional(list(object({
        name                       = string
        streams                    = list(string)
        samplingFrequencyInSeconds = number
        counterSpecifiers          = list(string)
      })))
      windowsEventLogs = optional(list(object({
        name         = string
        streams      = list(string)
        xPathQueries = list(string)
      })))
      syslog = optional(list(object({
        name          = string
        streams       = list(string)
        facilityNames = list(string)
        logLevels     = list(string)
      })))
      extensions = optional(list(object({
        name              = string
        streams           = list(string)
        extensionName     = string
        extensionSettings = optional(any)
        inputDataSources  = optional(list(string))
      })))
      platformTelemetry = optional(list(object({
        name    = string
        streams = list(string)
      })))
      prometheusForwarder = optional(list(object({
        name               = string
        streams            = list(string)
        labelIncludeFilter = optional(map(string))
      })))
      iisLogs = optional(list(object({
        name           = string
        streams        = list(string)
        logDirectories = optional(list(string))
      })))
      logFiles = optional(list(object({
        name         = string
        streams      = list(string)
        filePatterns = list(string)
        format       = string
        settings = optional(object({
          text = optional(object({
            recordStartTimestampFormat = string
          }))
        }))
      })))
    }))
    destinations = optional(object({
      logAnalytics = optional(list(object({
        name                = string
        workspaceResourceId = optional(string)
      })))
      azureMonitorMetrics = optional(object({
        name = string
      }))
      eventHubs = optional(list(object({
        name               = string
        eventHubResourceId = string
      })))
      storageBlobsDirect = optional(list(object({
        name                     = string
        storageAccountResourceId = string
        containerName            = string
      })))
      storageTablesDirect = optional(list(object({
        name                     = string
        storageAccountResourceId = string
        tableName                = string
      })))
    }))
    data_flows = optional(list(object({
      streams      = list(string)
      destinations = list(string)
      transformKql = optional(string)
      outputStream = optional(string)
    })))
    stream_declarations = optional(map(object({
      columns = list(object({
        name = string
        type = string
      }))
    })))
  }))
  default     = {}
  description = <<DESCRIPTION
(Optional) A map of Data Collection Rules to create. The key is the name of the rule. The value is an object containing the configuration.
- `name` - (Required) The name of the Data Collection Rule.
- `kind` - (Optional) The kind of the Data Collection Rule. Possible values are `Linux`, `Windows`, and `AgentDirectToStore`.
- `description` - (Optional) The description of the Data Collection Rule.
- `tags` - (Optional) A map of tags to assign to the Data Collection Rule.
- `lock` - (Optional) Controls the Resource Lock configuration for this resource. The following properties can be specified:
  - `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
- `data_sources` - (Optional) An object defining the data sources.
  - `performanceCounters` - (Optional) A list of performance counters.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
    - `samplingFrequencyInSeconds` - (Required) The sampling frequency in seconds.
    - `counterSpecifiers` - (Required) A list of counter specifiers.
  - `windowsEventLogs` - (Optional) A list of Windows Event Logs.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
    - `xPathQueries` - (Required) A list of XPath queries.
  - `syslog` - (Optional) A list of Syslog configurations.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
    - `facilityNames` - (Required) A list of facility names. Possible values include `auth`, `authpriv`, `cron`, `daemon`, `kern`, `lpr`, `mail`, `mark`, `news`, `syslog`, `user`, `uucp`, `local0` through `local7`.
    - `logLevels` - (Required) A list of log levels. Possible values include `Debug`, `Info`, `Notice`, `Warning`, `Error`, `Critical`, `Alert`, `Emergency`.
  - `extensions` - (Optional) A list of extensions.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
    - `extensionName` - (Required) The name of the extension.
    - `extensionSettings` - (Optional) The settings for the extension.
    - `inputDataSources` - (Optional) A list of input data sources.
  - `platformTelemetry` - (Optional) A list of platform telemetry configurations.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
  - `prometheusForwarder` - (Optional) A list of Prometheus Forwarder configurations.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
    - `labelIncludeFilter` - (Optional) A map of label include filters.
  - `iisLogs` - (Optional) A list of IIS Logs configurations.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
    - `logDirectories` - (Optional) A list of log directories.
  - `logFiles` - (Optional) A list of Log Files configurations.
    - `name` - (Required) The name of the data source.
    - `streams` - (Required) A list of streams.
    - `filePatterns` - (Required) A list of file patterns.
    - `format` - (Required) The format of the log files.
    - `settings` - (Optional) The settings for the log files.
      - `text` - (Optional) Text settings.
        - `recordStartTimestampFormat` - (Required) The record start timestamp format.
- `destinations` - (Optional) An object defining the destinations.
  - `logAnalytics` - (Optional) A list of Log Analytics destinations.
    - `name` - (Required) The name of the destination.
    - `workspaceResourceId` - (Optional) The Resource ID of the Log Analytics Workspace. If not provided, the module's workspace is used.
  - `azureMonitorMetrics` - (Optional) An Azure Monitor Metrics destination.
    - `name` - (Required) The name of the destination.
  - `eventHubs` - (Optional) A list of Event Hub destinations.
    - `name` - (Required) The name of the destination.
    - `eventHubResourceId` - (Required) The Resource ID of the Event Hub.
  - `storageBlobsDirect` - (Optional) A list of Storage Blob destinations.
    - `name` - (Required) The name of the destination.
    - `storageAccountResourceId` - (Required) The Resource ID of the Storage Account.
    - `containerName` - (Required) The name of the container.
  - `storageTablesDirect` - (Optional) A list of Storage Table destinations.
    - `name` - (Required) The name of the destination.
    - `storageAccountResourceId` - (Required) The Resource ID of the Storage Account.
    - `tableName` - (Required) The name of the table.
- `data_flows` - (Optional) A list of data flows.
  - `streams` - (Required) A list of streams.
  - `destinations` - (Required) A list of destinations.
  - `transformKql` - (Optional) The KQL transformation query.
  - `outputStream` - (Optional) The output stream.
- `stream_declarations` - (Optional) A map of stream declarations.
  - `columns` - (Required) A list of columns.
    - `name` - (Required) The name of the column.
    - `type` - (Required) The type of the column.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A map of tags to assign to the resources."
}
