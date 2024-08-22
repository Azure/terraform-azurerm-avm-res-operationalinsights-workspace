terraform {
  required_version = "~> 1.5"
  required_providers {
    # TODO: Ensure all required providers are listed here.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.14"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
