# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script serves as the overarching script to deploy the workload template either in its entirety or in a piecemeal manner the below individual modules.

.DESCRIPTION
- Executes the individual modules - lighthouse

#>

using namespace System.Collections
param (
    $parAttendedLogin = $true
)

#reference to common scripts
. "..\..\..\common\common.ps1"

#Processing parameters from JSON and creating a hash table
$varParameters = @{}

$varWorkloadParameters = Get-Content -Path '.\parameters\lighthouse.parameters.json' | ConvertFrom-Json
$varWorkloadParameters.parameters.psobject.properties | ForEach-Object {
    if ($_.value.Value -eq $null -or $_.value.Value.count -eq 0) {
        $varParameters.add($_.Name, (new-Object PsObject -property @{value = $_.value.defaultValue; defaultValue = $_.value.defaultValue }))
    }
    else {
        $varParameters.add($_.Name, (new-Object PsObject -property @{value = $_.value.Value; defaultValue = $_.value.defaultValue }))
    }
}

#constants
$varMaxRetryAttemptTransientErrorRetry = 3
$varRetry = $true
$varRetryWaitTimeTransientErrorRetry = 60

#bicep files
$varLighthouse = '.\lighthouse.bicep'
$varPolicyRemediation = '.\policyRemediation.bicep'

#Parameters
$varLighthouseParams = @('parDeploymentPrefix', 'parDeploymentLocation', 'parLighthouseManagementTenantId', 'parLighthouseOfferName', 'parLighthouseOfferDescription', 'parPrincipalId', 'parPrincipalIdDisplayName', 'parRoleDefinitionId')

#variables to support retry for known transient errors
$varMaxRetryAttemptTransientErrorRetry = 3
$varRetryWaitTimeTransientErrorRetry = 60

<#
.Description
   Invokes Policy Remediation for existing subscriptions
#>
function Invoke-PolicyRemediation {
    param($varPolicyAssignmentId)
    #policy remediation
    $guid = New-Guid
    $parDeploymentLocation = $varParameters.parDeploymentLocation.value
    $varDeploymentName = ("$guid" + $varPolicySetDefinitionName)
    $deploymentName = $varDeploymentName.Length -ge 64 ? $varDeploymentName.Substring(0, 64) : $varDeploymentName
    $parRemediationName = "rem-" + $deploymentName
    $parManagementGroupId = $varParameters.parManagementGroupId.value
    $varTotalWaitTime = 0
    $varLoopCounter = 0

    $parameters = @{
        parPolicyRemediationName       = $parRemediationName
        parPolicyAssignmentId          = $varPolicyAssignmentId
        parPolicyDefinitionReferenceId = ''
    }

    while ($varTotalWaitTime -lt $varMaxRetryAttemptTransientErrorRetry) {
        try {
            Write-Information ">>> Policy Remediation Started" -InformationAction Continue
            $modLighthousePolicyRemediation = New-AzManagementGroupDeployment `
                -Name $varDeploymentName `
                -Location $parDeploymentLocation `
                -TemplateFile $varPolicyRemediation `
                -ManagementGroupId $parManagementGroupId `
                -TemplateParameterObject $parameters `
                -WarningAction Ignore

            if (!$modLighthousePolicyRemediation -or $modLighthousePolicyRemediation.ProvisioningState -eq "Failed") {
                Write-Error "Error while executing policy remediation deployment" -ErrorAction Stop
            }
            else {
                Write-Information ">>> Policy Remediation Successful" -InformationAction Continue
            }

            return
        }
        catch {
            $varLoopCounter++
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            Write-Error "$varException \n $varErrorDetails \n $varTrace" -ErrorAction Continue

            if ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
                Write-Information ">>> Retrying deployment after waiting for $varRetryWaitTimeTransientErrorRetry secs" -InformationAction Continue
                Start-Sleep -Seconds $varRetryWaitTimeTransientErrorRetry
            }
            else {
                Write-Error ">>> Error occurred in policy remediation deployment. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

<#
.Description
   Invokes Policy evaluation for the lighthouse policy
#>
function Invoke-PolicyEvaluation {
    param($varSubscriptions)
    $varSubscriptionsCount = $varSubscriptions.count
    if ($varSubscriptionsCount -eq 0) {
        Write-Information ">>> No subscriptions to evaluate policies" -ErrorAction Stop
    }

    Write-Information ">>> Policy scan will be executed in synchronous mode. The process may take up to an hour." -InformationAction Continue
    $varCounter = 1
    foreach ($subscription in $varSubscriptions) {
        # register for ManagedServices and PolicyInsights RP
        $subscriptionId = $subscription.subscriptionId;
        $subscriptionAvailable = Get-AzSubscription -SubscriptionId $subscriptionId
        if ($subscriptionAvailable -eq "[]") {
            Write-Error ">>> Please refresh credentials by running following commands: Disconnect-AzAccount and Connect-AzAccount and retry the deployment" -ErrorAction Stop
        }

        # This is not logic requirement, but have to register Microsoft.Network early to avoid Subscription XXXXX-XXXXX-XXXXXXX-XXXXXXX is not registered with NRP because of registration delay.
        Write-Information ">>> Registering Microsoft.Network resource provider for the existing subscription $subscriptionId ..." -InformationAction Continue
        Set-AzContext -Subscription $subscriptionId
        Register-ResourceProvider "Microsoft.Network"

        Write-Information ">>> Registering Managed.Services resource provider for the existing subscription $subscriptionId ..." -InformationAction Continue
        Register-ResourceProvider 'Microsoft.ManagedServices' `

        Write-Information ">>> Registering Managed.PolicyInsights resource provider for the existing subscription $subscriptionId ..." -InformationAction Continue
        Register-ResourceProvider 'Microsoft.PolicyInsights' `

        #run trigger scan for policy evaluation
        Write-Information "Executing policy evaluation scan for subscription id: $subscriptionId. Processing $varCounter subscription out of $varSubscriptionsCount " -InformationAction Continue
        $varCounter++

        Start-AzPolicyComplianceScan
    }
    return
}

<#
.DESCRIPTION
    Deploys lighthouse
#>
function New-Lighthouse {
    param()
    $parDeploymentPrefix = $varParameters.parDeploymentPrefix.value
    $varLighthouseDeploymentName = "$parDeploymentPrefix-deploy-Lighthouse-$vartimeStamp"
    $parManagementGroupId = $varParameters.parManagementGroupId.value
    $varLogicAppName = "$parManagementGroupId-logicapp-$parDeploymentLocation"

    $parameters = @{
        parManagementGroupId              = $parManagementGroupId
        parLocation                      = $varParameters.parDeploymentLocation.value
        parLogicAppName                  = $varLogicAppName
        parDeploymentSubscriptionId      = $varDeploymentSubscriptionId
        parLighthouseManagementTenantId  = $varParameters.parLighthouseManagementTenantId.value
        parLighthouseOfferName           = $varParameters.parLighthouseOfferName.value
        parLighthouseOfferDescription    = $varParameters.parLighthouseOfferDescription.value
        parPrincipalId                   = $varParameters.parPrincipalId.value
        parPrincipalIdDisplayName        = $varParameters.parPrincipalIdDisplayName.value
        parRoleDefinitionId              = $varParameters.parRoleDefinitionId.value
    }

    while ($varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        try {
            Write-Information ">>> Lighthouse deployment started" -InformationAction Continue
            $modLighthouse = New-AzManagementGroupDeployment `
                -Name $varLighthouseDeploymentName `
                -Location $parDeploymentLocation `
                -ManagementGroupId $parManagementGroupId `
                -TemplateFile $varLighthouse `
                -TemplateParameterObject $parameters `
                -WarningAction Ignore

            if (!$modLighthouse -or $modLighthouse.ProvisioningState -eq "Failed") {
                Write-Error "Error while executing lighthouse deployment script" -ErrorAction Stop
            }

            return $modLighthouse
        }
        catch {
            $varLoopCounter++
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            Write-Error "$varException \n $varErrorDetails \n $varTrace" -ErrorAction Continue

            if ($varRetry -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
                Write-Information ">>> Retrying deployment after waiting for $varRetryWaitTimeTransientErrorRetry secs" -InformationAction Continue
                Start-Sleep -Seconds $varRetryWaitTimeTransientErrorRetry
            }
            else {
                Write-Error ">>> Error occurred in Lighthouse deployment. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

Confirm-Parameters($varLighthouseParams)

if ($parAttendedLogin) {
    # Confirm Prerequisites
    Confirm-Prerequisites -parConfirmAZResourceGraphVersion 1
}

#Fetch all existing subscriptions
$parDeploymentPrefix = $varParameters.parDeploymentPrefix.value
$parManagementGroupId = $varParameters.parManagementGroupId.value
$parDeploymentLocation = $varParameters.parDeploymentLocation.value
$varDeploymentSubscriptionId = (Get-AzContext).Subscription.id
$varSubscriptions = Search-AzGraph -Query "ResourceContainers | where type =~ 'microsoft.resources/subscriptions'" -ManagementGroup $parManagementGroupId
$varSubscriptions = $varSubscriptions | Where-Object { $_.properties.state -eq "Enabled" }
$varIsMgSubscription = $varSubscriptions | Where-Object { $_.subscriptionId -eq $varDeploymentSubscriptionId }

if ($null -eq $varIsMgSubscription) {
    Write-Error "The subscription $varDeploymentSubscriptionId does not under the management group $parManagementGroupId or disabled. Please use the subscription which is created by Sovereign Landing Zone." -ErrorAction Stop
}

$modLighthouseOutputs = New-Lighthouse
$varPolicyAssignmentId = $modLighthouseOutputs.Outputs.outPolicyAssignmentId.value

#invoke policy evaluation
Invoke-PolicyEvaluation $varSubscriptions
#invoke policy remediation
Invoke-PolicyRemediation $varPolicyAssignmentId
Write-Information ">>> Lighthouse deployment Successful" -InformationAction Continue
