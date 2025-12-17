# Query Packs Deployment Example

This example demonstrates how to deploy Azure Monitor Query Packs and Queries using the `query_packs` module.

It deploys the following resources:
- A **Log Analytics Workspace** as the foundational resource.
- A **Query Pack** named `my-query-pack` tagged for a dev environment and protected with a `CanNotDelete` lock.
- A **Monitor Query** named `My Query` inside the pack:
  - Executes `Heartbeat | take 10`.
  - Categorized under "monitor".
  - Automatically assigned a UUID if one is not provided.
