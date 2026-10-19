mock_provider "azapi" {
  alias = "mocked"
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

run "association_omitted_by_default" {
  command = apply

  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }

  assert {
    condition     = length(azapi_resource.nsp_association) == 0
    error_message = "An omitted NSP association must not create an association."
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this.tags == null
    error_message = "The workspace must retain its null tags default."
  }
}

run "association_inherits_null_tags" {
  command = apply

  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }

  variables {
    network_security_perimeter_association = {
      resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityPerimeters/test-nsp"
      profile_name = "test-profile"
    }
  }

  assert {
    condition     = var.tags == null && azurerm_log_analytics_workspace.this.tags == null && length(azapi_resource.nsp_association[0].tags) == 0
    error_message = "Omitted tags must retain the null workspace default and leave the association untagged."
  }

  assert {
    condition     = azapi_resource.nsp_association[0].body.properties.accessMode == "Learning"
    error_message = "The association must retain the Learning access mode default."
  }
}

run "association_inherits_empty_tags" {
  command = apply

  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }

  variables {
    tags = {}
    network_security_perimeter_association = {
      resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityPerimeters/test-nsp"
      profile_name = "test-profile"
    }
  }

  assert {
    condition     = length(azapi_resource.nsp_association[0].tags) == 0
    error_message = "An empty tags map must remain empty on the association."
  }

  assert {
    condition     = length(azurerm_log_analytics_workspace.this.tags) == 0
    error_message = "An empty tags map must remain empty on the workspace."
  }
}

run "association_inherits_consumer_tags" {
  command = apply

  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }

  variables {
    tags = {
      environment = "test"
      owner       = "consumer"
    }
    network_security_perimeter_association = {
      resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityPerimeters/test-nsp"
      profile_name = "test-profile"
    }
  }

  assert {
    condition     = azapi_resource.nsp_association[0].tags == tomap(var.tags) && azurerm_log_analytics_workspace.this.tags == tomap(var.tags)
    error_message = "The association and workspace must receive the complete, unchanged consumer tags."
  }

  assert {
    condition = (
      length(azapi_resource.nsp_association) == 1 &&
      azapi_resource.nsp_association[0].name == "nsp-assoc-test-workspace" &&
      azapi_resource.nsp_association[0].parent_id == var.network_security_perimeter_association.resource_id &&
      azapi_resource.nsp_association[0].type == "Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview" &&
      azapi_resource.nsp_association[0].body.properties.privateLinkResource.id == azurerm_log_analytics_workspace.this.id &&
      azapi_resource.nsp_association[0].body.properties.profile.id == "${var.network_security_perimeter_association.resource_id}/profiles/test-profile"
    )
    error_message = "Tag propagation must preserve the association address, name, parent, API version and resource/profile bindings."
  }
}

run "association_preserves_explicit_access_mode" {
  command = apply

  providers = {
    azapi   = azapi.mocked
    azurerm = azurerm.mocked

    random = random.mocked
    time   = time.mocked
  }

  variables {
    tags = {
      environment = "production"
    }
    network_security_perimeter_association = {
      resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityPerimeters/test-nsp"
      profile_name = "enforced-profile"
      access_mode  = "Enforced"
    }
  }

  assert {
    condition = (
      azapi_resource.nsp_association[0].tags == tomap(var.tags) &&
      azapi_resource.nsp_association[0].body.properties.accessMode == "Enforced" &&
      azapi_resource.nsp_association[0].body.properties.profile.id == "${var.network_security_perimeter_association.resource_id}/profiles/enforced-profile"
    )
    error_message = "Consumer tags must not change the explicit access mode or profile."
  }
}
