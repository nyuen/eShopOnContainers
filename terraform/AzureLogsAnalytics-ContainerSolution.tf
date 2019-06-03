# ----------------------------------------------------
# Testé le 3 juin 2019 avec Terraform 0.12 et AzureRM Provider 1.29 
# ----------------------------------------------------
# this Terraform File defines :
# - an Azure Logs Analytics Solution
# Variables are defined in Var-AzureLogsAnalytics-Solutions.tf
# - cf. https://www.terraform.io/docs/providers/azurerm/r/log_analytics_solution.html

resource "azurerm_log_analytics_solution" "Terra-Containers-Solution" {
  solution_name         = var.OMSSolutionName
  location              = var.AzureRegion
  resource_group_name   = var.ResourceGroup
  workspace_resource_id = azurerm_log_analytics_workspace.Terra-OMSWorkspace-SpecialK.id
  workspace_name        = azurerm_log_analytics_workspace.Terra-OMSWorkspace-SpecialK.name

  plan {
    publisher = var.OMSSolutionPublisher
    product   = var.OMSProduct
  }
}

