resource "azurerm_application_insights" "Terra-App-Insights" {
  name                = "${var.AppInsightsName}"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.Terra-RG-SpecialK.name}"
  application_type    = "Web"
}

output "instrumentation_key" {
  value = "${azurerm_application_insights.Terra-App-Insights.instrumentation_key}"
}

output "app_id" {
  value = "${azurerm_application_insights.Terra-App-Insights.app_id}"
}