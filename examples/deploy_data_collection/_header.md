# Data Collection Deployment Example

This example demonstrates how to deploy a complete Data Collection setup using the `data_collection` module.

It deploys the following resources:
- A **Log Analytics Workspace** to store the collected data.
- A **Data Collection Endpoint (DCE)** named `dce-avm-test` with public network access disabled and a `CanNotDelete` lock.
- A **Data Collection Rule (DCR)** named `dcr-avm-test` configured for Windows environments.
  - Collects **Performance Counters** (Processor Time, Committed Bytes).
  - Collects **Windows Event Logs** (Security events).
  - Sends data to the deployed Log Analytics Workspace.
  - Protected with a `CanNotDelete` lock.
- **Data Collection Rule Associations** (demonstrated with placeholder VM IDs) linking resources to the DCR and DCE.
