# Variable pour definir la region Azure ou deployer la plateforme
# Pour obtenir la liste des valeurs possible via la ligne de commande Azure, executer la commande suivante :
# az account list-locations
variable "AzureRegion" {
  type    = string
  default = "westeurope"
}

# Variable pour definir le nom du groupe de ressource ou deployer la plateforme
# Variable Resource Group Name
variable "ResourceGroup" {
  type    = string
  default = "SpecialK-RG"
}

