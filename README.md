# Defender for APIs Hourly Cost Estimator (West Europe)
This PowerShell script calculates the estimated cost of Microsoft Defender for APIs 
using **hourly pricing** based on your **Azure API Management (APIM)** request volume.

It retrieves **per-hour API request metrics** from Azure Monitor and determines the 
most cost-effective Defender Plan (P1–P5) for each hour over the **last 30 days**.

✅ Supports West Europe pricing  
✅ Outputs per-hour breakdown and summary  
✅ Designed for Azure professionals to plan Defender costs  
This PowerShell script calculates the estimated cost of Microsoft Defender for APIs 
using **hourly pricing** based on your **Azure API Management (APIM)** request volume.

It retrieves **per-hour API request metrics** from Azure Monitor and determines the 
most cost-effective Defender Plan (P1–P5) for each hour over the **last 30 days**.

✅ Supports West Europe pricing  
✅ Outputs per-hour breakdown and summary  
✅ Designed for Azure professionals to plan Defender costs  
**Author:** Meezan Khan  
📧 [contact@meezankhan.com](mailto:contact@meezankhan.com)
- Authenticates via Azure Service Principal
- Analyzes traffic from specified APIM instances
- Matches each hour to the most cost-effective Defender Plan
- Calculates 30-day total estimated cost
- Exports:
  - `DefenderPlanEstimate_30Days_<timestamp>.csv` → Summary
  - `DefenderPlanBreakdown_30Days_<timestamp>.csv` → Hourly details


| Plan | Hourly Rate (€) | API Call Limit Per Hour |
|------|------------------|--------------------------|
| P1   | €0.2608          | 1 million                |
| P2   | €0.9127          | 5 million                |
| P3   | €6.5192          | 50 million               |
| P4   | €9.1268          | 100 million              |
| P5   | €65.1913         | 1 billion                |


1. Clone this repo
2. Replace `<YOUR-TENANT-ID>`, `<YOUR-APP-ID>`, `<YOUR-CLIENT-SECRET>`, `<YOUR-SUBSCRIPTION-ID>` in the script
3. Open PowerShell and run:

```powershell
.\DefenderForAPIs_HourlyCostEstimator.ps1



---

#### 7. **Requirements**

```markdown
- PowerShell 5.1 or later
- Modules:
  - Az.Accounts
  - Az.ApiManagement
  - Az.Monitor
- Azure Service Principal with Reader access on the subscription


This project is released under the MIT License.
