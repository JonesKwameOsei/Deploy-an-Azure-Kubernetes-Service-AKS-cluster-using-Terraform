terraform {
  required_version = ">=1.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.14.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.2"
    }
  }
}

provider "azurerm" {
  features {}
}