# Variables (ici pour séparer le code de la config)

# Variable pour definir le nom du workspaceOMS (Azure Logs Analytics)
variable "OMSworkspace" {
  type    = "string"
  # default = "OMSWorkspace-ProjetP"
}

# Variable pour la SKU du workspaceOMS (Azure Logs Analytics)
# Possible values : PerNode, Standard, Standalone
# Standalone = Pricing per Gb, PerNode = OMS licence 
# More info : https://azure.microsoft.com/en-us/pricing/details/log-analytics/
  variable "OMSworkspaceSKU" {
  type    = "string"
  default = "Standard"
}

# Variable pour definir le nb de jours de rétention du workspaceOMS (Azure Logs Analytics)
# Possible values : 30 to 730
  variable "OMSworkspaceDaysOfRetention" {
  type    = "string"
  default = "30"
}
