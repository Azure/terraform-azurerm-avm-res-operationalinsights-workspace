data "azapi_client_config" "current" {}

locals {
  # Azure requires both the solution and its plan to be named `SolutionName(WorkspaceName)`.
  name = "${var.log_analytics_solution_solution_name}(${var.log_analytics_solution_workspace_name})"
  solution_timeouts = {
    create = try(coalesce(try(var.log_analytics_solution_timeouts.create, null), try(var.timeouts.create, null)), null)
    delete = try(coalesce(try(var.log_analytics_solution_timeouts.delete, null), try(var.timeouts.delete, null)), null)
    read   = try(coalesce(try(var.log_analytics_solution_timeouts.read, null), try(var.timeouts.read, null)), null)
    update = try(coalesce(try(var.log_analytics_solution_timeouts.update, null), try(var.timeouts.update, null)), null)
  }
}

resource "azapi_resource" "this" {
  location  = var.log_analytics_solution_location
  name      = local.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.log_analytics_solution_resource_group_name}"
  type      = var.resource_types.operationsmanagement_solutions
  body = {
    plan = {
      name = local.name
      # Azure rejects a plan without a promotion code. The AzureRM provider sent an empty one when none was set.
      promotionCode = var.log_analytics_solution_plan.promotion_code == null ? "" : var.log_analytics_solution_plan.promotion_code
      product       = var.log_analytics_solution_plan.product
      publisher     = var.log_analytics_solution_plan.publisher
    }
    properties = {
      workspaceResourceId = var.log_analytics_solution_workspace_resource_id
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.operationsmanagement_solutions) > 0 ? var.ignore_body_changes.operationsmanagement_solutions : null
  ignore_casing       = true
  # The AzureRM provider replaced the solution when one of these settings changed. While the prior value is
  # null, as it is straight after upgrading from AzureRM, nothing is replaced.
  replace_triggers_external_values = {
    product               = var.log_analytics_solution_plan.product
    promotion_code        = var.log_analytics_solution_plan.promotion_code
    publisher             = var.log_analytics_solution_plan.publisher
    workspace_resource_id = lower(var.log_analytics_solution_workspace_resource_id)
  }
  response_export_values = []
  retry                  = var.retry
  tags                   = var.log_analytics_solution_tags

  dynamic "timeouts" {
    for_each = var.log_analytics_solution_timeouts == null && var.timeouts == null ? [] : [local.solution_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
