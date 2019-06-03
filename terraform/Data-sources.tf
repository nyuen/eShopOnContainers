# ----------------------------------------------------
# Testé le 3 juin 2019 avec Terraform 0.12 et AzureRM Provider 1.29 
# ----------------------------------------------------
# Get a secret (here a public SSH Key stored in an Azure KeyVault)
# If you don't have an Azure Key Vault, you can use a variable (look in Var-Azure-AKS.tf)
data "azurerm_key_vault_secret" "Terra-Datasource-cleSSH" {
  # This is a secret in Azure Key Vault that contains my SSH Key
  name = "clePubliqueSSH"

  # This is my vault so you need to replace the following uri by the uri of your Azure Key Vault
  vault_uri = var.KeyVaultUrl
}

output "clePubliqueSSH" {
  value = data.azurerm_key_vault_secret.Terra-Datasource-cleSSH.value
}

variable "KeyVaultUrl" {
  type = string
}

