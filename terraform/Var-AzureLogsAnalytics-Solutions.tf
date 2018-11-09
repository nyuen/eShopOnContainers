# Variables (ici pour séparer le code de la config)
# - an Azure Logs Analytics : Containers Solution
# - cf. https://www.terraform.io/docs/providers/azurerm/r/log_analytics_solution.html

# Variable pour definir le nom de la solution OMS
variable "OMSSolutionName" {
  type    = "string"
  default = "Containers"
}

# Variable pour definir l editeur de la solution OMS
variable "OMSSolutionPublisher" {
  type    = "string"
  default = "Microsoft"
}

# Variable pour definir le nom du solution pack OMS
variable "OMSProduct" {
  type    = "string"
  default = "OMSGallery/Containers"
}
