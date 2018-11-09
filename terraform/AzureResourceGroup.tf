# ----------------------------------------------------
# Tested & validated with Terraform 1.11.8 
# 06 nov 2018
# ----------------------------------------------------
# this Terraform defines an Azure Resource Group
# Variable are defined in Var-AzureResourceGroup.tf
# ----------------------------------------------------

# Azure ressource group
# Resource Groupe Azure
resource "azurerm_resource_group" "Terra-RG-Stan1" {
  name     = "${var.RessourceGroup}"
  location = "${var.AzureRegion}"
}
