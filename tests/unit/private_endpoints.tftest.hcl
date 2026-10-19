mock_provider "azapi" {
  alias = "mocked"

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Insights/privateLinkScopes/test-scope"
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      output = {
        properties = {
          privateEndpointConnections = [{
            name = "observed-connection"
            properties = {
              privateEndpoint = {
                id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/privateEndpoints/test-pe"
              }
            }
          }]
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
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  alias = "mocked"

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-workspace"
    }
  }

  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/privateEndpoints/test-pe"
    }
  }
}

mock_provider "random" {
  alias = "mocked"

  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-1111-1111-111111111111"
    }
  }
}

mock_provider "time" {
  alias = "mocked"
}

variables {
  enable_telemetry    = false
  location            = "uksouth"
  name                = "test-workspace"
  resource_group_name = "test-rg"
  monitor_private_link_scoped_resource = {
    scope = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Insights/privateLinkScopes/test-scope"
    }
  }
  private_endpoints = {
    legacy = {
      subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
      private_dns_zone_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/privateDnsZones/privatelink.monitor.azure.com"
      ]
      application_security_group_associations = {
        asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/applicationSecurityGroups/test-asg"
      }
      ip_configurations = {
        primary = {
          name               = "primary"
          private_ip_address = "10.0.0.5"
        }
      }
    }
  }
}

run "legacy_defaults_and_managed_addresses" {
  command = apply
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }

  assert {
    condition     = length(azurerm_private_endpoint.this) == 1 && length(azurerm_private_endpoint.this_unmanaged) == 0 && length(azurerm_private_endpoint_application_security_group_association.this) == 1 && length(azurerm_private_endpoint_application_security_group_association.this_unmanaged) == 0
    error_message = "Legacy defaults must keep the managed endpoint and ASG addresses."
  }
  assert {
    condition     = azurerm_private_endpoint.this["legacy"].name == "pep-test-workspace" && azurerm_private_endpoint.this["legacy"].resource_group_name == "test-rg" && azurerm_private_endpoint.this["legacy"].tags == null && azurerm_private_endpoint.this["legacy"].private_service_connection[0].name == "pse-test-workspace" && one(azurerm_private_endpoint.this["legacy"].private_service_connection[0].subresource_names) == "azuremonitor"
    error_message = "Legacy endpoint naming, resource group, tags and service defaults must remain unchanged."
  }
  assert {
    condition     = one(azurerm_private_endpoint.this["legacy"].ip_configuration).member_name == "privatelink" && one(azurerm_private_endpoint.this["legacy"].ip_configuration).subresource_name == "privatelink" && one(azurerm_private_endpoint.this["legacy"].private_dns_zone_group).name == "default"
    error_message = "Legacy IP and DNS defaults must remain unchanged."
  }
  assert {
    condition     = azapi_update_resource.amplscope_update_existing["scope"].body.properties.accessModeSettings.exclusions[0].privateEndpointConnectionName == "observed-connection"
    error_message = "Existing-scope exclusions must resolve the actual managed endpoint connection."
  }
  assert {
    condition     = length(azapi_resource.private_endpoint_locks) == 0 && length(azapi_resource.private_endpoint_role_assignments) == 0
    error_message = "Endpoint extension resources must remain absent by default."
  }
}

run "global_dns_false_with_scope_only_extension" {
  command = apply
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoint_extensions = {
      legacy = {
        monitor_private_link_scope_key = "scope"
        monitor_private_link_scope_exclusion = {
          ingestion_access_mode = "Open"
        }
      }
    }
  }
  assert {
    condition     = length(azurerm_private_endpoint.this) == 0 && length(azurerm_private_endpoint.this_unmanaged) == 1 && length(azurerm_private_endpoint_application_security_group_association.this) == 0 && length(azurerm_private_endpoint_application_security_group_association.this_unmanaged) == 1 && length(azurerm_private_endpoint.this_unmanaged["legacy"].private_dns_zone_group) == 0
    error_message = "Scope-only extensions must inherit global DNS ownership, including endpoint and ASG routing."
  }
  assert {
    condition     = azapi_update_resource.amplscope_update_existing["scope"].body.properties.accessModeSettings.exclusions[0].privateEndpointConnectionName == "observed-connection" && azapi_update_resource.amplscope_update_existing["scope"].body.properties.accessModeSettings.exclusions[0].ingestionAccessMode == "Open" && one(azurerm_private_endpoint.this_unmanaged["legacy"].ip_configuration).member_name == "privatelink" && one(azurerm_private_endpoint.this_unmanaged["legacy"].ip_configuration).subresource_name == "privatelink"
    error_message = "Unmanaged routing must retain existing IP defaults and extension exclusion settings."
  }
}

run "explicit_legacy_dns_overrides_global" {
  command = apply
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      managed = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        application_security_group_associations = {
          asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/applicationSecurityGroups/test-asg"
        }
      }
      unmanaged = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        application_security_group_associations = {
          asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/applicationSecurityGroups/test-asg"
        }
      }
    }
    private_endpoint_extensions = {
      managed   = { manage_dns_zone_group = true }
      unmanaged = { manage_dns_zone_group = false }
    }
  }
  assert {
    condition     = contains(keys(azurerm_private_endpoint.this), "managed") && contains(keys(azurerm_private_endpoint.this_unmanaged), "unmanaged") && contains(keys(azurerm_private_endpoint_application_security_group_association.this), "managed-asg") && contains(keys(azurerm_private_endpoint_application_security_group_association.this_unmanaged), "unmanaged-asg")
    error_message = "Explicit true and false legacy DNS overrides must retain both endpoint and ASG addresses."
  }
}

run "canonical_fields_and_legacy_resource_group_names" {
  command = apply
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints = {
      managed = {
        name                            = "custom-pe"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        resource_group_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/canonical-rg"
        subresource_name                = "azuremonitor"
        location                        = "westeurope"
        network_interface_name          = "custom-nic"
        private_service_connection_name = "custom-connection"
        private_dns_zone_group_name     = "custom-dns"
        private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/privateDnsZones/privatelink.monitor.azure.com"]
        tags                            = { purpose = "endpoint" }
        ip_configurations = {
          primary = { name = "custom-ip", private_ip_address = "10.0.0.6", member_name = "custom-member" }
        }
      }
      unmanaged = {
        subnet_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        resource_group_name = "legacy-rg"
        subresource_name    = "azuremonitor"
        ip_configurations = {
          primary = { name = "custom-ip", private_ip_address = "10.0.0.7", member_name = "custom-member" }
        }
      }
    }
    private_endpoint_extensions = {
      unmanaged = { manage_dns_zone_group = false }
    }
  }
  assert {
    condition     = azurerm_private_endpoint.this["managed"].resource_group_name == "canonical-rg" && azurerm_private_endpoint.this_unmanaged["unmanaged"].resource_group_name == "legacy-rg"
    error_message = "Canonical resource group IDs and existing resource group names must both work."
  }
  assert {
    condition     = azurerm_private_endpoint.this["managed"].name == "custom-pe" && azurerm_private_endpoint.this["managed"].location == "westeurope" && azurerm_private_endpoint.this["managed"].custom_network_interface_name == "custom-nic" && azurerm_private_endpoint.this["managed"].tags["purpose"] == "endpoint" && azurerm_private_endpoint.this["managed"].private_service_connection[0].name == "custom-connection" && one(azurerm_private_endpoint.this["managed"].private_dns_zone_group).name == "custom-dns"
    error_message = "Explicit per-endpoint overrides must remain effective."
  }
  assert {
    condition     = alltrue([for pe in [azurerm_private_endpoint.this["managed"], azurerm_private_endpoint.this_unmanaged["unmanaged"]] : one(pe.ip_configuration).member_name == "custom-member" && one(pe.ip_configuration).subresource_name == "azuremonitor" && one(pe.private_service_connection[0].subresource_names) == "azuremonitor"])
    error_message = "Canonical member and subresource fields must reach both endpoint branches."
  }
}

run "new_scope_connection_uses_unmanaged_endpoint" {
  command = apply
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    monitor_private_link_scoped_service_name = "workspace-link"
    monitor_private_link_scoped_resource     = {}
    monitor_private_link_scope = {
      scope = {
        name        = "test-scope"
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      }
    }
    private_endpoints_manage_dns_zone_group = false
    private_endpoint_extensions = {
      legacy = { monitor_private_link_scope_key = "scope" }
    }
  }
  assert {
    condition     = azapi_update_resource.amplscope_update["scope"].body.properties.accessModeSettings.exclusions[0].privateEndpointConnectionName == "observed-connection"
    error_message = "New-scope exclusions must resolve the unmanaged endpoint connection rather than fall back to its service name."
  }
}

run "endpoint_locks_roles_and_azapi_controls" {
  command = apply
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints = {
      managed = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        lock               = { kind = "CanNotDelete", name = "custom-lock", notes = "Keep this endpoint" }
        role_assignments = {
          reader = {
            name                                   = "22222222-2222-2222-2222-222222222222"
            principal_id                           = "33333333-3333-3333-3333-333333333333"
            principal_type                         = "ServicePrincipal"
            role_definition_id_or_name             = "Reader"
            description                            = "Endpoint reader"
            condition                              = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'example'"
            condition_version                      = "2.0"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity"
          }
        }
      }
      unmanaged = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        lock               = { kind = "ReadOnly" }
        role_assignments = {
          reader = {
            principal_id               = "33333333-3333-3333-3333-333333333333"
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          }
        }
      }
    }
    private_endpoint_extensions = {
      unmanaged = { manage_dns_zone_group = false }
    }
    retry    = { error_message_regex = ["ScopeLocked"], interval_seconds = 2, max_interval_seconds = 10 }
    timeouts = { create = "10m", read = "5m", update = "10m", delete = "5m" }
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["managed"].name == "custom-lock" && azapi_resource.private_endpoint_locks["managed"].body.properties.notes == "Keep this endpoint" && azapi_resource.private_endpoint_locks["managed"].body.properties.level == "CanNotDelete" && azapi_resource.private_endpoint_locks["unmanaged"].name == "lock-readonly"
    error_message = "Canonical lock names and notes and legacy kind-only locks must be implemented."
  }
  assert {
    condition     = azapi_resource.private_endpoint_role_assignments["managed-reader"].name == "22222222-2222-2222-2222-222222222222" && azapi_resource.private_endpoint_role_assignments["unmanaged-reader"].name == "11111111-1111-1111-1111-111111111111" && azapi_resource.private_endpoint_role_assignments["managed-reader"].body.properties.roleDefinitionId == azapi_resource.private_endpoint_role_assignments["unmanaged-reader"].body.properties.roleDefinitionId
    error_message = "Named and generated role assignments must resolve both role names and IDs."
  }
  assert {
    condition     = azapi_resource.private_endpoint_role_assignments["managed-reader"].body.properties.principalType == "ServicePrincipal" && azapi_resource.private_endpoint_role_assignments["managed-reader"].body.properties.description == "Endpoint reader" && azapi_resource.private_endpoint_role_assignments["managed-reader"].body.properties.conditionVersion == "2.0" && azapi_resource.private_endpoint_role_assignments["managed-reader"].body.properties.delegatedManagedIdentityResourceId == var.private_endpoints["managed"].role_assignments["reader"].delegated_managed_identity_resource_id
    error_message = "Existing role assignment settings must reach the ARM request."
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["managed"].parent_id == azurerm_private_endpoint.this["managed"].id && azapi_resource.private_endpoint_locks["unmanaged"].parent_id == azurerm_private_endpoint.this_unmanaged["unmanaged"].id && azapi_resource.private_endpoint_role_assignments["unmanaged-reader"].parent_id == azurerm_private_endpoint.this_unmanaged["unmanaged"].id && azapi_resource.private_endpoint_role_assignments["managed-reader"].parent_id == azurerm_private_endpoint.this["managed"].id
    error_message = "Locks and roles must target the correct managed or unmanaged endpoint."
  }
  assert {
    condition     = azapi_resource.private_endpoint_locks["managed"].type == var.resource_types.authorization_locks && azapi_resource.private_endpoint_role_assignments["managed-reader"].type == var.resource_types.authorization_role_assignments && azapi_resource.private_endpoint_locks["managed"].retry.interval_seconds == 2 && azapi_resource.private_endpoint_role_assignments["managed-reader"].timeouts.create == "10m" && azapi_resource.ampls["scope"].retry.max_interval_seconds == 10 && azapi_resource.ampls["scope"].timeouts.delete == "5m"
    error_message = "AzAPI controls must reach new extension resources and existing root resources."
  }
}

run "none_lock_remains_disabled" {
  command = apply
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints = {
      legacy = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        lock               = { kind = "None" }
      }
    }
  }
  assert {
    condition     = length(azapi_resource.private_endpoint_locks) == 0
    error_message = "The documented None lock setting must not create a management lock."
  }
}

run "invalid_subnet_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints = {
      invalid = { subnet_resource_id = "not-a-subnet-id" }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        private_dns_zone_resource_ids = ["not-a-zone-id"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_asg_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        application_security_group_associations = { invalid = "not-an-asg-id" }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity_is_rejected" {
  command = plan
  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/default"
        role_assignments = {
          invalid = {
            principal_id                           = "33333333-3333-3333-3333-333333333333"
            role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            delegated_managed_identity_resource_id = "not-an-identity-id"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}
