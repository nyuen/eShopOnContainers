# ----------------------------------------------------
# Testé le 3 juin 2019 avec Terraform 0.12 et AzureRM Provider 1.29 
# ----------------------------------------------------
# this Terraform defines an Azure Resource Group
# Variable are defined in Var-AzureResourceGroup.tf
# ----------------------------------------------------

# Azure ressource group
# Resource Groupe Azure
resource "azurerm_resource_group" "Terra-RG-SpecialK" {
  name     = var.ResourceGroup
  location = var.AzureRegion
}

