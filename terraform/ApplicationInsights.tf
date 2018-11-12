resource "azurerm_application_insights" "Terra-App-Insights" {
  name                = "${var.AppInsightsName}"
  location            = "${var.AzureRegion}"
  resource_group_name = "${var.ResourceGroup}"
  application_type    = "Web"
}

output "instrumentation_key" {
  value = "${azurerm_application_insights.Terra-App-Insight.instrumentation_key}"
}

output "app_id" {
  value = "${azurerm_application_insights.Terra-App-Insight.app_id}"
}