provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "this" {
  for_each = var.infra
  name     = each.key
  location = each.value.location
}

# VNets
resource "azurerm_virtual_network" "this" {
  for_each = merge([
    for rg_name, rg in var.infra : {
      for vnet_name, vnet in rg.vnets :
      "${rg_name}-${vnet_name}" => {
        rg_name       = rg_name
        location      = rg.location
        vnet_name     = vnet_name
        address_space = vnet.address_space
      }
    }
  ]...)

  name                = each.value.vnet_name
  location            = each.value.location
  resource_group_name = azurerm_resource_group.this[each.value.rg_name].name
  address_space       = each.value.address_space
}

# Storage Account
resource "azurerm_storage_account" "this" {
  for_each = var.infra

  name                     = lower(each.value.storage_account.name)
  location                 = each.value.location
  resource_group_name      = azurerm_resource_group.this[each.key].name
  account_tier             = "Standard"
  account_replication_type = each.value.storage_account.sku
  kind                     = each.value.storage_account.kind
  access_tier              = each.value.storage_account.access_tier
}
