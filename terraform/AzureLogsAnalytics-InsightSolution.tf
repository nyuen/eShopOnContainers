# ----------------------------------------------------
# Tested & validated with Terraform 1.11.8 
# 06 nov 2018
# ----------------------------------------------------
# this Terraform File defines :
# - an Azure Logs Analytics Solution : Containers Insight
# - cf. https://www.terraform.io/docs/providers/azurerm/r/log_analytics_solution.html
# - cf. https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html 

resource "azurerm_log_analytics_solution" "Terra-Containers-Insight" {
  solution_name         = "ContainerInsights"
  location              = "${var.AzureRegion}"
  resource_group_name   = "${var.RessourceGroup}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.Terra-OMSWorkspace-ProjetP.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.Terra-OMSWorkspace-ProjetP.name}"

  plan {
    publisher = "${var.OMSSolutionPublisher}"
    product   = "OMSGallery/ContainerInsights"
  }
}
