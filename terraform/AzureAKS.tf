# ----------------------------------------------------
# Testé le 3 juin 2019 avec Terraform 0.12 et AzureRM Provider 1.29 
# ----------------------------------------------------
# Terraform code to deploy an Azure Kubernetes Service
# with oms agent daemon set connected to an Azure Log 
# Analytics Workspace
# Variable are defined in Var-AzureAKS.tf
# ----------------------------------------------------

# Cluster AKS
# AKS Cluster
resource "azurerm_kubernetes_cluster" "Terra-AKS-SpecialK" {
  name                = var.AKS-Name
  location            = var.AzureRegion
  resource_group_name = azurerm_resource_group.Terra-RG-SpecialK.name
  kubernetes_version  = var.KubernetesVersion
  dns_prefix          = var.DNSPrefix

  linux_profile {
    admin_username = var.AdminName

    ssh_key {
      key_data = data.azurerm_key_vault_secret.Terra-Datasource-cleSSH.value
    }
  }

  agent_pool_profile {
    name    = "default"
    count   = var.Nb-NodesKubernetes
    vm_size = var.AKSNodeVMSize
    os_type = var.AKSNodeOS
  }

  service_principal {
    client_id     = var.SPNClientID
    client_secret = var.SPNClientSecret
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.Terra-OMSWorkspace-SpecialK.id
    }
  }

  tags = {
    Environment = var.Tag-environnement
  }
}

# Output AKS
output "id" {
  value = azurerm_kubernetes_cluster.Terra-AKS-SpecialK.id
}

# output "kube_config" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-SpecialK.kube_config_raw}"
# }

# output "client_key" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-SpecialK.kube_config.0.client_key}"
# }

# output "client_certificate" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-SpecialK.kube_config.0.client_certificate}"
# }

# output "cluster_ca_certificate" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-SpecialK.kube_config.0.cluster_ca_certificate}"
# }

output "host" {
  value = azurerm_kubernetes_cluster.Terra-AKS-SpecialK.kube_config[0].host
}

