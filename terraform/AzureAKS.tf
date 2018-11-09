# ----------------------------------------------------
# Tested & validated with Terraform 1.11.8 
# 06 nov 2018
# ----------------------------------------------------
# Terraform code to deploy an Azure Kubernetes Service
# with oms agent daemon set connected to an Azure Log 
# Analytics Workspace
# Variable are defined in Var-AzureAKS.tf
# ----------------------------------------------------


# Cluster AKS
# AKS Cluster
resource "azurerm_kubernetes_cluster" "Terra-AKS-Stan1" {
  name                   = "${var.AKS-Name}"
  location               = "${var.AzureRegion}"
  resource_group_name    = "${azurerm_resource_group.Terra-RG-Stan1.name}"
  kubernetes_version     = "${var.KubernetesVersion}"
  dns_prefix             = "${var.DNSPrefix}"
  
  linux_profile {
    admin_username = "${var.AdminName}"

    ssh_key {
      key_data = "${data.azurerm_key_vault_secret.Terra-Datasource-cleSSH.value}"
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = "${var.Nb-NodesKubernetes}"
    vm_size         = "${var.AKSNodeVMSize}"
    os_type         = "${var.AKSNodeOS}"
  }

  service_principal {
    client_id     = "${var.SPNClientID}"
    client_secret = "${var.SPNClientSecret}"
  }

addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = "${azurerm_log_analytics_workspace.Terra-OMSWorkspace-ProjetP.id}"
    }
  }


  tags {
    Environment = "${var.Tag-environnement}"
  }
}

# Output AKS
output "id" {
    value = "${azurerm_kubernetes_cluster.Terra-AKS-Stan1.id}"
}

# output "kube_config" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-Stan1.kube_config_raw}"
# }

# output "client_key" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-Stan1.kube_config.0.client_key}"
# }

# output "client_certificate" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-Stan1.kube_config.0.client_certificate}"
# }

# output "cluster_ca_certificate" {
#   value = "${azurerm_kubernetes_cluster.Terra-AKS-Stan1.kube_config.0.cluster_ca_certificate}"
# }

output "host" {
  value = "${azurerm_kubernetes_cluster.Terra-AKS-Stan1.kube_config.0.host}"
}