# Variables (ici pour séparer le code de la config)

# Variable nom de l'Azure Container Registry
# Variable Azure Container Registry Name
variable "ACR-Name" {
  type    = "string"
  # default = ""
}

# Variable SKU de l'Azure Container Registry
# Variable Azure Container Registry Name
# Possible values : Classic, Basic, Standard, Premium
variable "ACR-SKU" {
  type    = "string"
  default = "Premium"
}

# Variable admin / password for ACR access
# Possible values : true, false
variable "ACR-Admin-Enabled" {
  type    = "string"
  default = "true"
}
