resource "azurerm_log_analytics_solution" "this" {
  location              = var.log_analytics_solution_location
  resource_group_name   = var.log_analytics_solution_resource_group_name
  solution_name         = var.log_analytics_solution_solution_name
  workspace_name        = var.log_analytics_solution_workspace_name
  workspace_resource_id = var.log_analytics_solution_workspace_resource_id
  tags                  = var.log_analytics_solution_tags

  dynamic "plan" {
    for_each = [var.log_analytics_solution_plan]
    content {
      product        = plan.value.product
      publisher      = plan.value.publisher
      promotion_code = plan.value.promotion_code
    }
  }
  dynamic "timeouts" {
    for_each = var.log_analytics_solution_timeouts == null ? [] : [var.log_analytics_solution_timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}