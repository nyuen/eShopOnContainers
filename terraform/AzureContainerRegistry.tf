# ----------------------------------------------------
# Tested & validated with Terraform 1.11.8 
# 06 nov 2018
# ----------------------------------------------------
# Terraform code to deploy an Azure Container Registry
# Variable are defined in Var-AzureContainerRegistry.tf
# ----------------------------------------------------

# Azure Container Registry
resource "azurerm_container_registry" "Terra-ACR-SpecialK" {
  name                = "${var.ACR-Name}"
  resource_group_name = "${azurerm_resource_group.Terra-RG-SpecialK.name}"
  location            = "${azurerm_resource_group.Terra-RG-SpecialK.location}"
  admin_enabled       = "${var.ACR-Admin-Enabled}"
  sku                 = "${var.ACR-SKU}"
}


#Data source for the Service Principal referenced in the AKS configuration
data "azurerm_azuread_service_principal" "AKS-SPN" {
  application_id = "${var.SPNClientID}"
}

#Role Assignment to give AKS the access to ACR through AAD
resource "azurerm_role_assignment" "AKS-ACR-Role" {
  scope                = "${azurerm_container_registry.Terra-ACR-SpecialK.id}"
  role_definition_name = "Reader"
  principal_id         = "${data.azurerm_azuread_service_principal.AKS-SPN.object_id}"
}