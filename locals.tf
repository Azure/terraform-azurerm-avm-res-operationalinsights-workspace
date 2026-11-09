locals {
  # The notes this module has always written, so that upgrading leaves existing locks unchanged.
  lock_notes = {
    CanNotDelete = "Cannot delete the resource or its child resources."
    ReadOnly     = "Cannot delete or modify the resource or its child resources."
  }
  parent_id           = var.parent_id != null ? var.parent_id : "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  resource_group_name = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", local.parent_id).resource_group_name
  subscription_id     = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", local.parent_id).subscription_id
}

locals {
  # True when the workspace already exists in the configured region, so it is updated in place rather than
  # created or recreated.
  workspace_exists = try(data.azapi_resource.workspace.exists && lower(replace(data.azapi_resource.workspace.output.location, " ", "")) == lower(replace(var.location, " ", "")), false)
  workspace_public_network_access = {
    for key, value in {
      ingestion = var.log_analytics_workspace_internet_ingestion_enabled
      query     = var.log_analytics_workspace_internet_query_enabled
    } : key => value == "SecuredByPerimeter" ? "SecuredByPerimeter" : (value == "true" ? "Enabled" : "Disabled")
  }
  # The settings the AzureRM provider sent. Unset optional settings are left out, so Azure keeps its defaults.
  workspace_properties = merge(
    {
      features = {
        disableLocalAuth                            = !coalesce(var.log_analytics_workspace_local_authentication_enabled, true)
        enableLogAccessUsingOnlyResourcePermissions = coalesce(var.log_analytics_workspace_allow_resource_only_permissions, true)
      }
      publicNetworkAccessForIngestion = local.workspace_public_network_access.ingestion
      publicNetworkAccessForQuery     = local.workspace_public_network_access.query
      sku = merge(
        { name = coalesce(var.log_analytics_workspace_sku, "PerGB2018") },
        var.log_analytics_workspace_reservation_capacity_in_gb_per_day == null ? {} : { capacityReservationLevel = var.log_analytics_workspace_reservation_capacity_in_gb_per_day },
      )
      workspaceCapping = {
        dailyQuotaGb = coalesce(var.log_analytics_workspace_daily_quota_gb, -1)
      }
    },
    var.log_analytics_workspace_cmk_for_query_forced == null ? {} : { forceCmkForQuery = var.log_analytics_workspace_cmk_for_query_forced },
    var.log_analytics_workspace_retention_in_days == null ? {} : { retentionInDays = var.log_analytics_workspace_retention_in_days },
  )
  # Terraform waits until apply to read a data source that refers directly to a resource with changes pending.
  # Referring to an existing workspace by this ID lets data sources read from it during plan instead.
  workspace_resource_id = local.workspace_exists ? data.azapi_resource.workspace.id : azapi_resource.this.id
  workspace_timeouts = {
    create = try(coalesce(try(var.log_analytics_workspace_timeouts.create, null), try(var.timeouts.create, null)), null)
    delete = try(coalesce(try(var.log_analytics_workspace_timeouts.delete, null), try(var.timeouts.delete, null)), null)
    read   = try(coalesce(try(var.log_analytics_workspace_timeouts.read, null), try(var.timeouts.read, null)), null)
    update = try(coalesce(try(var.log_analytics_workspace_timeouts.update, null), try(var.timeouts.update, null)), null)
  }
}

locals {
  # Role names are matched case-insensitively, as the AzureRM provider matched them.
  role_definition_ids_by_name = length(var.role_assignments) > 0 ? {
    for definition in data.azapi_resource_list.role_definitions[0].output.results : lower(definition.role_name) => definition.id...
  } : {}
  role_definition_resource_substring = "/providers/microsoft.authorization/roledefinitions/"
  role_assignments = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      # The AzureRM provider sent this principal type when the flag was set, which skips the Entra ID
      # existence check that fails for newly created service principals.
      principal_type = assignment.principal_type == null && assignment.skip_service_principal_aad_check ? "ServicePrincipal" : assignment.principal_type
      # Names resolve to IDs. Tenant-level IDs are qualified with the subscription, which is the form Azure
      # returns, so that the configuration and the deployed assignment compare equal.
      role_definition_id_or_name = (
        !strcontains(lower(assignment.role_definition_id_or_name), local.role_definition_resource_substring) ? try(local.role_definition_ids_by_name[lower(assignment.role_definition_id_or_name)][0], assignment.role_definition_id_or_name) :
        startswith(lower(assignment.role_definition_id_or_name), "/providers/") ? "/subscriptions/${local.subscription_id}${assignment.role_definition_id_or_name}" :
        assignment.role_definition_id_or_name
      )
    })
  }
}

locals {
  private_endpoint_manage_dns_zone_group = {
    for k, v in var.private_endpoints : k => coalesce(
      try(var.private_endpoint_extensions[k].manage_dns_zone_group, null),
      var.private_endpoints_manage_dns_zone_group
    )
  }
  private_endpoint_ids = merge(
    { for k, v in azapi_resource.private_endpoints : k => v.id },
    { for k, v in azapi_resource.private_endpoints_unmanaged : k => v.id },
  )
  private_endpoint_names = { for k, v in var.private_endpoints : k => v.name != null ? v.name : "pep-${var.name}" }
  # The resource group of each private endpoint. As before, a resource group given by ID is used by name, in
  # the subscription of the workspace.
  private_endpoint_parent_ids = {
    for k, v in var.private_endpoints : k => v.resource_group_name == null ? local.parent_id : "/subscriptions/${local.subscription_id}/resourceGroups/${try(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", v.resource_group_name).resource_group_name, v.resource_group_name)}"
  }
  private_endpoint_private_link_scope_ids = {
    for k, v in var.private_endpoints : k => try(
      azapi_resource.amplscope[try(var.private_endpoint_extensions[k].monitor_private_link_scope_key, null)].id,
      lower(var.monitor_private_link_scoped_resource[try(var.private_endpoint_extensions[k].monitor_private_link_scope_key, null)].resource_id),
      azapi_resource.amplscope[k].id,
      lower(var.monitor_private_link_scoped_resource[k].resource_id),
      length(var.monitor_private_link_scope) + length(var.monitor_private_link_scoped_resource) == 1 ? coalesce(try(lower(one(values(var.monitor_private_link_scoped_resource)).resource_id), null), try(one(values(azapi_resource.amplscope)).id, null)) : null
    )
  }
  private_endpoint_properties = {
    for k, v in var.private_endpoints : k => {
      applicationSecurityGroups  = [for id in values(v.application_security_group_associations) : { id = id }]
      customNetworkInterfaceName = v.network_interface_name
      ipConfigurations = [
        for ip_configuration in values(v.ip_configurations) : {
          name = ip_configuration.name
          properties = {
            groupId          = coalesce(v.subresource_name, "privatelink")
            memberName       = coalesce(ip_configuration.member_name, "privatelink")
            privateIPAddress = ip_configuration.private_ip_address
          }
        }
      ]
      privateLinkServiceConnections = [
        {
          name = v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${var.name}"
          properties = {
            groupIds             = [coalesce(v.subresource_name, "azuremonitor")]
            privateLinkServiceId = local.private_endpoint_private_link_scope_ids[k]
          }
        }
      ]
      subnet = {
        id = v.subnet_resource_id
      }
    }
  }
  # The AzureRM provider replaced a private endpoint when one of these settings changed. While the prior
  # value is null, as it is straight after upgrading from AzureRM, nothing is replaced.
  private_endpoint_replace_triggers = {
    for k, v in var.private_endpoints : k => {
      ip_configurations               = local.private_endpoint_properties[k].ipConfigurations
      network_interface_name          = v.network_interface_name
      private_connection_resource_id  = local.private_endpoint_private_link_scope_ids[k] == null ? null : lower(local.private_endpoint_private_link_scope_ids[k])
      private_service_connection_name = local.private_endpoint_properties[k].privateLinkServiceConnections[0].name
      subnet_resource_id              = lower(v.subnet_resource_id)
      subresource_name                = v.subresource_name
    }
  }
  # The zone groups of managed private endpoints, which earlier versions managed as part of the private
  # endpoint. Built from the configuration, so they are known when planning the upgrade.
  private_dns_zone_group_imports = {
    for k, v in local.private_dns_zone_groups : k => "${local.private_endpoint_parent_ids[k]}/providers/Microsoft.Network/privateEndpoints/${local.private_endpoint_names[k]}/privateDnsZoneGroups/${v.name}?api-version=${split("@", var.resource_types.network_private_endpoints_private_dns_zone_groups)[1]}"
  }
  private_dns_zone_groups = {
    for k, v in var.private_endpoints : k => {
      name                          = coalesce(v.private_dns_zone_group_name, "default")
      private_dns_zone_resource_ids = v.private_dns_zone_resource_ids
    } if local.private_endpoint_manage_dns_zone_group[k] && length(v.private_dns_zone_resource_ids) > 0
  }
}
