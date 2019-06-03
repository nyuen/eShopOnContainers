# ----------------------------------------------------
# Testé le 3 juin 2019 avec Terraform 0.12 et AzureRM Provider 1.29 
# ----------------------------------------------------
# this Terraform File will deploy :
# - an Azure Logs Analytics Workspace (cf. https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-overview)
# - Output all usefull informations including Azure Logs Analytics Portal URL
# more information : https://www.terraform.io/docs/providers/azurerm/r/log_analytics_workspace.html
# Variable are defined in var-AzureLogsAnalytics-Workspace.tf
# ----------------------------------------------------

resource "azurerm_log_analytics_workspace" "Terra-OMSWorkspace-SpecialK" {
  name                = var.OMSworkspace
  location            = azurerm_resource_group.Terra-RG-SpecialK.location
  resource_group_name = azurerm_resource_group.Terra-RG-SpecialK.name

  # Possible values : PerNode, Standard, Standalone
  # Standalone = Pricing per Gb, PerNode = OMS licence 
  # More info : https://azure.microsoft.com/en-us/pricing/details/log-analytics/
  sku = var.OMSworkspaceSKU

  # Possible values : 30 to 730
  retention_in_days = var.OMSworkspaceDaysOfRetention
}

# Output post deployment
output "AzureLogAnalyticsWorkspaceID" {
  value = azurerm_log_analytics_workspace.Terra-OMSWorkspace-SpecialK.id
}

output "AzureLogAnalyticsWorkspaceCustomerID" {
  value = azurerm_log_analytics_workspace.Terra-OMSWorkspace-SpecialK.workspace_id
}

output "AzureLogAnalyticsWorkspaceprimarySharedKey" {
  value = azurerm_log_analytics_workspace.Terra-OMSWorkspace-SpecialK.primary_shared_key
}

output "AzureLogAnalyticsWorkspaceSecondarySharedKey" {
  value = azurerm_log_analytics_workspace.Terra-OMSWorkspace-SpecialK.secondary_shared_key
}

