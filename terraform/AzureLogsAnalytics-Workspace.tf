# ----------------------------------------------------
# Tested & validated with Terraform 1.11.8 
# 06 nov 2018
# ----------------------------------------------------
# this Terraform File will deploy :
# - an Azure Logs Analytics Workspace (cf. https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-overview)
# - Output all usefull informations including Azure Logs Analytics Portal URL
# more information : https://www.terraform.io/docs/providers/azurerm/r/log_analytics_workspace.html
# Variable are defined in var-AzureLogsAnalytics-Workspace.tf
# ----------------------------------------------------

resource "azurerm_log_analytics_workspace" "Terra-OMSWorkspace-ProjetP" {
  name                = "${var.OMSworkspace}"
  location            = "${azurerm_resource_group.Terra-RG-Stan1.location}"
  resource_group_name = "${azurerm_resource_group.Terra-RG-Stan1.name}"
  # Possible values : PerNode, Standard, Standalone
  # Standalone = Pricing per Gb, PerNode = OMS licence 
  # More info : https://azure.microsoft.com/en-us/pricing/details/log-analytics/
  sku                 = "${var.OMSworkspaceSKU}"
  # Possible values : 30 to 730
  retention_in_days   = "${var.OMSworkspaceDaysOfRetention}"
}

# Output post deployment
output "Azure Log Analytics Workspace ID" {
    value="${azurerm_log_analytics_workspace.Terra-OMSWorkspace-ProjetP.id}"
}

output "Azure Log Analytics Workspace Customer ID" {
    value="${azurerm_log_analytics_workspace.Terra-OMSWorkspace-ProjetP.workspace_id}"
}

output "Azure Log Analytics Workspace primary Shared Key " {
    value="${azurerm_log_analytics_workspace.Terra-OMSWorkspace-ProjetP.primary_shared_key}"
}

output "Azure Log Analytics Workspace Secondary Shared Key " {
    value="${azurerm_log_analytics_workspace.Terra-OMSWorkspace-ProjetP.secondary_shared_key}"
}
