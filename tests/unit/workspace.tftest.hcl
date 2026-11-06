mock_provider "azapi" {
  alias = "mocked"

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-workspace"
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      output = {
        properties = {
          privateEndpointConnections = []
          accessModeSettings = {
            ingestionAccessMode = "Open"
            queryAccessMode     = "Open"
          }
        }
      }
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          role_name = "Reader"
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        }]
      }
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {
  alias = "mocked"
}

mock_provider "time" {
  alias = "mocked"
}

variables {
  enable_telemetry    = false
  location            = "uksouth"
  name                = "test-workspace"
  resource_group_name = "test-rg"
}

run "workspace_defaults_match_earlier_versions" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg" && azapi_resource.this.type == "Microsoft.OperationalInsights/workspaces@2023-09-01" && length(azapi_resource.this.tags) == 0
    error_message = "The workspace must be created in the named resource group with the default API version and no tags."
  }
  assert {
    condition     = azapi_resource.this.body.properties.features.disableLocalAuth == false && azapi_resource.this.body.properties.features.enableLogAccessUsingOnlyResourcePermissions == true
    error_message = "Local authentication and resource-only permissions must default to enabled, as before."
  }
  assert {
    condition     = azapi_resource.this.body.properties.publicNetworkAccessForIngestion == "Disabled" && azapi_resource.this.body.properties.publicNetworkAccessForQuery == "Disabled"
    error_message = "Public network access must default to disabled, as before."
  }
  assert {
    condition     = azapi_resource.this.body.properties.sku == { name = "PerGB2018" } && azapi_resource.this.body.properties.workspaceCapping.dailyQuotaGb == -1
    error_message = "The SKU must default to PerGB2018 and the daily quota to unlimited, as before."
  }
  assert {
    condition     = !contains(keys(azapi_resource.this.body.properties), "retentionInDays") && !contains(keys(azapi_resource.this.body.properties), "forceCmkForQuery")
    error_message = "Unset optional settings must be left to Azure."
  }
  assert {
    condition     = length(azapi_resource.lock) == 0 && length(time_sleep.lock_removal) == 0 && length(azapi_resource.role_assignments) == 0 && length(azapi_resource.diagnostic_settings) == 0
    error_message = "Optional interfaces must be absent by default."
  }
  assert {
    condition     = output.name == "test-workspace"
    error_message = "The name output must return the workspace name."
  }
}

run "workspace_settings_reach_the_request" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    parent_id                                                  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/parent-rg"
    log_analytics_workspace_allow_resource_only_permissions    = false
    log_analytics_workspace_cmk_for_query_forced               = true
    log_analytics_workspace_daily_quota_gb                     = 5
    log_analytics_workspace_internet_ingestion_enabled         = "SecuredByPerimeter"
    log_analytics_workspace_internet_query_enabled             = "true"
    log_analytics_workspace_local_authentication_enabled       = false
    log_analytics_workspace_reservation_capacity_in_gb_per_day = 100
    log_analytics_workspace_retention_in_days                  = 90
    log_analytics_workspace_sku                                = "CapacityReservation"
    tags                                                       = { environment = "test" }
    log_analytics_workspace_identity = {
      type         = "UserAssigned"
      identity_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity"]
    }
  }

  assert {
    condition     = azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.tags["environment"] == "test"
    error_message = "parent_id must take precedence over resource_group_name, and tags must be set."
  }
  assert {
    condition     = azapi_resource.this.body.properties.features.disableLocalAuth == true && azapi_resource.this.body.properties.features.enableLogAccessUsingOnlyResourcePermissions == false && azapi_resource.this.body.properties.forceCmkForQuery == true
    error_message = "Feature settings must reach the request."
  }
  assert {
    condition     = azapi_resource.this.body.properties.publicNetworkAccessForIngestion == "SecuredByPerimeter" && azapi_resource.this.body.properties.publicNetworkAccessForQuery == "Enabled"
    error_message = "SecuredByPerimeter and enabled network access must be set on the workspace itself."
  }
  assert {
    condition     = azapi_resource.this.body.properties.sku == { name = "CapacityReservation", capacityReservationLevel = 100 } && azapi_resource.this.body.properties.workspaceCapping.dailyQuotaGb == 5 && azapi_resource.this.body.properties.retentionInDays == 90
    error_message = "SKU, capacity reservation, quota and retention must reach the request."
  }
  assert {
    condition     = azapi_resource.this.identity[0].type == "UserAssigned" && length(azapi_resource.this.identity[0].identity_ids) == 1
    error_message = "The identity must be set."
  }
}

run "capacity_reservation_requires_its_sku" {
  command = plan
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    log_analytics_workspace_reservation_capacity_in_gb_per_day = 100
  }

  expect_failures = [azapi_resource.this]
}

run "timeouts_fall_back_per_operation" {
  command = plan
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    log_analytics_workspace_timeouts = { create = "45m" }
    timeouts                         = { create = "10m", delete = "20m" }
  }

  assert {
    condition     = azapi_resource.this.timeouts.create == "45m" && azapi_resource.this.timeouts.delete == "20m" && azapi_resource.this.timeouts.read == null
    error_message = "Workspace timeouts must take precedence per operation and fall back to timeouts."
  }
}

run "lock_and_role_assignments" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    lock = { kind = "CanNotDelete" }
    role_assignments = {
      by_name = {
        role_definition_id_or_name       = "reader"
        principal_id                     = "33333333-3333-3333-3333-333333333333"
        skip_service_principal_aad_check = true
      }
      by_id = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_id               = "33333333-3333-3333-3333-333333333333"
        principal_type             = "Group"
      }
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete" && azapi_resource.lock[0].body.properties == { level = "CanNotDelete", notes = "Cannot delete the resource or its child resources." } && length(time_sleep.lock_removal) == 1
    error_message = "The lock must keep its earlier name and notes, and be removed with a pause."
  }
  assert {
    condition     = azapi_resource.role_assignments["by_name"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" && azapi_resource.role_assignments["by_id"].body.properties.roleDefinitionId == azapi_resource.role_assignments["by_name"].body.properties.roleDefinitionId
    error_message = "Role names must resolve ignoring case, and tenant-level IDs must be qualified with the subscription."
  }
  assert {
    condition     = azapi_resource.role_assignments["by_name"].body.properties.principalType == "ServicePrincipal" && azapi_resource.role_assignments["by_id"].body.properties.principalType == "Group"
    error_message = "skip_service_principal_aad_check must set the ServicePrincipal principal type."
  }
}

run "diagnostic_settings_default_to_this_workspace" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    diagnostic_settings = {
      self = {}
      other = {
        name                           = "custom"
        log_analytics_destination_type = "AzureDiagnostics"
        storage_account_resource_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/teststorage"
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["self"].name == "diag-test-workspace" && azapi_resource.diagnostic_settings["self"].body.properties.workspaceId == azapi_resource.this.id && azapi_resource.diagnostic_settings["self"].body.properties.logAnalyticsDestinationType == null
    error_message = "A setting with no destination must send logs to this workspace, without a destination type."
  }
  assert {
    condition     = azapi_resource.diagnostic_settings["other"].body.properties.workspaceId == null && azapi_resource.diagnostic_settings["other"].body.properties.logAnalyticsDestinationType == "AzureDiagnostics"
    error_message = "A setting with another destination must not send logs to this workspace."
  }
  assert {
    condition     = length(azapi_resource.diagnostic_settings["self"].body.properties.logs) == 1 && azapi_resource.diagnostic_settings["self"].body.properties.logs[0].categoryGroup == "allLogs" && azapi_resource.diagnostic_settings["self"].body.properties.logs[0].category == null && length(azapi_resource.diagnostic_settings["self"].body.properties.metrics) == 1 && azapi_resource.diagnostic_settings["self"].body.properties.metrics[0].category == "AllMetrics"
    error_message = "Default log groups and metric categories must be sent."
  }
}

run "linked_resources_and_private_link_scope" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    log_analytics_workspace_dedicated_cluster_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/clusters/test-cluster"
    log_analytics_workspace_linked_storage_accounts = {
      logs = {
        data_source_type    = "CustomLogs"
        storage_account_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/teststorage"]
      }
    }
    monitor_private_link_scope = {
      scope = {
        name        = "law_pl_scope"
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/scope-rg"
        lock        = { kind = "CanNotDelete" }
      }
    }
    monitor_private_link_scoped_service_name = "law_pl_service"
  }

  assert {
    condition     = azapi_resource.linked_service[0].name == "Cluster" && azapi_resource.linked_service[0].body.properties.writeAccessResourceId == var.log_analytics_workspace_dedicated_cluster_resource_id
    error_message = "The dedicated cluster link must keep its name and target."
  }
  assert {
    condition     = azapi_resource.linked_storage_accounts["logs"].name == "CustomLogs" && azapi_resource.linked_storage_accounts["logs"].body.properties.storageAccountIds == var.log_analytics_workspace_linked_storage_accounts["logs"].storage_account_ids
    error_message = "Linked storage accounts must be named by data source type."
  }
  assert {
    condition     = azapi_resource.amplscope_scoped_service["scope"].name == "law_pl_service" && azapi_resource.amplscope_scoped_service["scope"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Insights/privateLinkScopes/law_pl_scope" && azapi_resource.amplscope_scoped_service["scope"].body.properties.linkedResourceId == azapi_resource.this.id
    error_message = "The scoped service must keep the resource ID that earlier versions gave it."
  }
  assert {
    condition     = azapi_resource.amplscope_lock["scope"].name == "law_pl_scope-lock" && azapi_resource.amplscope_lock["scope"].body.properties == { level = "CanNotDelete", notes = "" } && length(time_sleep.amplscope_lock_removal) == 1
    error_message = "The scope lock must keep its earlier name and settings, and be removed with a pause."
  }
}
