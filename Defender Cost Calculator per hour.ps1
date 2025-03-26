# ============================================================================
# Defender for APIs - Hourly Cost Estimator Script (West Europe Pricing)
# Author: Meezan Khan | Updated: 2025-03-26
# Contact: contact@meezankhan.com
# Description:
#   - Authenticates with Azure using a Service Principal
#   - Retrieves hourly API request metrics for specified APIM instances
#   - Calculates estimated cost for the past 30 days based on Defender hourly pricing
#   - Determines the most cost-effective plan per hour
#   - Outputs a full breakdown CSV with plan used per hour and a summary with totals
# ============================================================================

Set-StrictMode -Version Latest

# ============================
# 1. AUTHENTICATION SETUP
# ============================
$tenantId     = "<YOUR-TENANT-ID>"
$appId        = "<YOUR-APP-ID>"
$clientSecret = "<YOUR-CLIENT-SECRET>"

try {
    $secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($appId, $secureSecret)
    Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $credentials | Out-Null
    Write-Host "✅ Authenticated via Service Principal" -ForegroundColor Green
} catch {
    Write-Error "❌ Auth failed. $_"
    exit
}

# ============================
# 2. MODULE IMPORTS
# ============================
Import-Module Az.Accounts
Import-Module Az.ApiManagement
Import-Module Az.Monitor

# ============================
# 3. PRICING TABLE (West Europe - Hourly)
# ============================
$plans = @(
    @{ Name = "P1"; Rate = 0.2608; Limit = 1000000 },
    @{ Name = "P2"; Rate = 0.9127; Limit = 5000000 },
    @{ Name = "P3"; Rate = 6.5192; Limit = 50000000 },
    @{ Name = "P4"; Rate = 9.1268; Limit = 100000000 },
    @{ Name = "P5"; Rate = 65.1913; Limit = 1000000000 }
)

# ============================
# 4. TARGET CONFIGURATION
# ============================
$targetSubscription = "<YOUR-SUBSCRIPTION-ID>"
$apimTargets = @(
    @{ Name = "znlpo0035am0001"; ResourceGroup = "po_10003" },
    @{ Name = "apim-we-acc"; ResourceGroup = "ao_10003" }
)

Set-AzContext -SubscriptionId $targetSubscription | Out-Null
$results = @()
$breakdown = @()

# ============================
# 5. METRICS & COST ANALYSIS
# ============================
foreach ($apim in $apimTargets) {
    $resourceId = "/subscriptions/$targetSubscription/resourceGroups/$($apim.ResourceGroup)/providers/Microsoft.ApiManagement/service/$($apim.Name)"
    Write-Host "🔎 Processing APIM: $($apim.Name) | RG: $($apim.ResourceGroup)" -ForegroundColor Cyan

    $startTime = (Get-Date).AddDays(-30).ToUniversalTime()
    $endTime   = (Get-Date).ToUniversalTime()
    $hourlyMetrics = Get-AzMetric -ResourceId $resourceId -MetricName "TotalRequests" -StartTime $startTime -EndTime $endTime -TimeGrain ([TimeSpan]::FromHours(1)) -AggregationType Total
    $totalByHour = $hourlyMetrics.Data | Where-Object { $_.TimeStamp } | Sort-Object TimeStamp

    $totalCost = 0
    $planUsage = @{}

    foreach ($hour in $totalByHour) {
        $requests = $hour.Total
        $timestamp = $hour.TimeStamp
        $bestPlan = $null
        $bestCost = [double]::MaxValue

        foreach ($plan in $plans) {
            $cost = if ($requests -le $plan.Limit) {
                $plan.Rate
            } else {
                $plan.Rate + (($requests - $plan.Limit) * ($plan.Rate / $plan.Limit))
            }
            if ($cost -lt $bestCost) {
                $bestCost = $cost
                $bestPlan = $plan.Name
            }
        }

        $totalCost += $bestCost
        $planUsage[$bestPlan] = $planUsage[$bestPlan] + 1

        $breakdown += [PSCustomObject]@{
            SubscriptionID = $targetSubscription
            APIMName       = $apim.Name
            ResourceGroup  = $apim.ResourceGroup
            TimestampUTC   = $timestamp
            TotalRequests  = $requests
            SelectedPlan   = $bestPlan
            HourlyCostEUR  = [math]::Round($bestCost, 4)
        }
    }

    $planUsageSummary = ($planUsage.Keys | Sort-Object) -join ", "
    $results += [PSCustomObject]@{
        SubscriptionID            = $targetSubscription
        APIMName                  = $apim.Name
        ResourceGroup             = $apim.ResourceGroup
        TotalHours_Analyzed       = $totalByHour.Count
        EstimatedTotalCost_EUR    = "€{0:N2}" -f $totalCost
        MostUsedPlans             = ($planUsage.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "$($_.Key): $($_.Value)h" }) -join ", "
        BillingNote               = "Based on per-hour usage. Each hour is matched to the most cost-effective Defender plan."
    }
}

# ============================
# 6. EXPORT TO CSV
# ============================
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$summaryPath = Join-Path -Path $scriptDir -ChildPath "DefenderPlanEstimate_30Days_$timestamp.csv"
$detailPath = Join-Path -Path $scriptDir -ChildPath "DefenderPlanBreakdown_30Days_$timestamp.csv"

$results | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8
$breakdown | Export-Csv -Path $detailPath -NoTypeInformation -Encoding UTF8

Write-Host "`n✅ 30-day hourly-based summary saved to: $summaryPath" -ForegroundColor Green
Write-Host "✅ Hourly plan breakdown saved to: $detailPath" -ForegroundColor Green
