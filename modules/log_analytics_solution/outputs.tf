output "resource" {
  description = "The Log Analytics solution, with the attribute names of the `azurerm_log_analytics_solution` resource that earlier versions of this module returned, so that existing references keep working. Prefer `resource_id`."
  value = {
    id       = azapi_resource.this.id
    location = azapi_resource.this.location
    plan = [
      {
        name           = local.name
        product        = var.log_analytics_solution_plan.product
        promotion_code = var.log_analytics_solution_plan.promotion_code == null ? "" : var.log_analytics_solution_plan.promotion_code
        publisher      = var.log_analytics_solution_plan.publisher
      }
    ]
    resource_group_name   = var.log_analytics_solution_resource_group_name
    solution_name         = var.log_analytics_solution_solution_name
    tags                  = azapi_resource.this.tags == null ? tomap({}) : azapi_resource.this.tags
    workspace_name        = var.log_analytics_solution_workspace_name
    workspace_resource_id = var.log_analytics_solution_workspace_resource_id
  }
}

output "resource_id" {
  description = "The resource ID of the Log Analytics solution."
  value       = azapi_resource.this.id
}
