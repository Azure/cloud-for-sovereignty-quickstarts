# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script serves as the overarching script to deploy the HR Sample App Workload either in its entirety or in a piecemeal manner the below individual modules.

.DESCRIPTION
- Executes the individual modules - hr app sample workload

Prerequisites:

Connect-AzAccount -Subscription %SUBSCRIPTION_ID%
Add-SqlAzureAuthenticationContext -Interactive
#>

using namespace System.Collections
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string] $parRootDeploymentLocation = "eastus",
    [Parameter(Mandatory = $false, Position = 1)]
    [bool] $parInitializeDatabase = $true
)

#reference to common scripts
. "..\..\..\..\common\common.ps1"

# Retry logic parameters (in case of transient errors)
$varMaxTransientErrorRetryAttempts = 3
$varRetryWaitTime = 60

#bicep files
# TODO: Figure out this unusual pathing. Is it a requirement to call this script from a much higher working directory?
$varHrAppWorkload = '.\hrAppWorkload.bicep'
$varHRAppParametersFile = '.\parameters\hrAppWorkload.parameters.json'

<#
.DESCRIPTION
    Deploys HR app Azure resources.
#>
function New-AppResourceDeployment {
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string] $parDeployingUserObjectId,
        [Parameter(Mandatory = $True, Position = 1)]
        [string] $parDeployingUserUpn,
        [Parameter(Mandatory = $False, Position = 2)]
        [bool] $parIsValidation = $False
    )

    $varDonotRetryErrorCodes = Get-DonotRetryErrorCodes '../../../../common/const/doNotRetryErrorCodes.json'
    $varLoopCounter = 0
    while ($varLoopCounter -lt $varMaxTransientErrorRetryAttempts) {
        try {
            Write-Information ">>> Starting deployment of HR App Azure resources." -InformationAction Continue
            $varTimestamp = Get-Date -Format FileDateTimeUniversal
            $varAppDeployment = $null
            $varDeploymentName = "HrApp-$varTimestamp"
            if ($parIsValidation) {
                $varAppDeployment = Test-AzDeployment `
                    -Name $varDeploymentName `
                    -Location $parRootDeploymentLocation `
                    -TemplateFile $varHrAppWorkload `
                    -TemplateParameterFile $varHRAppParametersFile `
                    -parDeployingUserObjectId $parDeployingUserObjectId `
                    -parDeployingUserUpn $parDeployingUserUpn `

                if ($varAppDeployment.Count -gt 0) {
                    Write-Error $varAppDeployment[0].Message -ErrorAction Stop
                }

                Write-Information ">>> Successfully validated input parameter file." -InformationAction Continue
            }
            else {
                $varAppDeployment = New-AzDeployment `
                    -Name $varDeploymentName `
                    -Location $parRootDeploymentLocation `
                    -TemplateFile $varHrAppWorkload `
                    -TemplateParameterFile $varHRAppParametersFile `
                    -parDeployingUserObjectId $parDeployingUserObjectId `
                    -parDeployingUserUpn $parDeployingUserUpn `
                    -WarningAction Ignore `

                if (!$varAppDeployment -or $varAppDeployment.ProvisioningState -eq "Failed") {
                    Write-Error "Error while executing HR App Azure resources deployment." -ErrorAction Stop
                }
                else {
                    Write-Information ">>> Successfully deployed HR App Azure resources." -InformationAction Continue
                }
            }

            return $varAppDeployment
        }
        catch {
            $varLoopCounter++
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            if ($null -ne $varException) {
                $errorCode = $varAppDeployment[0].Code
            }

            Write-Error "$varException \n $varErrorDetails \n $varTrace" -ErrorAction Continue

            if ($varDonotRetryErrorCodes -notcontains $errorCode -and $varLoopCounter -lt $varMaxTransientErrorRetryAttempts) {
                Write-Information ">>> A deployment error occured, see above. The error may be transient. Retrying deployment after waiting for $varRetryWaitTime seconds." -InformationAction Continue
                Start-Sleep -Seconds $varRetryWaitTime
            }
            else {
                if ($varLoopCounter -eq $varMaxTransientErrorRetryAttempts) {
                    Write-Information ">>> Maximum number of retry attempts reached. Cancelling deployment." -InformationAction Continue
                }
                Write-Error ">>> Error occurred in HR App Workload deployment. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

function Initialize-AppDatabase() {
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [PSCustomObject] $parResourceDeploymentOutputs
    )

    $varDeploymentParameters = Get-Content -Path $varHRAppParametersFile | ConvertFrom-Json
    $parSqlAdministratorPassword = $varDeploymentParameters.parameters.parSqlAdministratorLoginPassword.value

    # Get remaining outputs from deployment result
    $varResourceGroupName = $parResourceDeploymentOutputs.outResourceGroupName.value
    $varAttestationProviderName = $parResourceDeploymentOutputs.outAttestationProviderName.value
    $varSqlServerName = $parResourceDeploymentOutputs.outSqlServerName.value
    $varSqlDatabaseName = $parResourceDeploymentOutputs.outSqlDatabaseName.value
    $varVmName = $parResourceDeploymentOutputs.outVmName.value
    $varCmkUrl = $parResourceDeploymentOutputs.outCmkUrl.value
    $parSqlAdministratorLogin = $parResourceDeploymentOutputs.outSqlAdministratorLogin.value

    Write-Information ">>> Initializing app database." -InformationAction Continue
    # Initiate database population (which due to cmdlet version requirements needs to run under PS5)
    $varLoopCounter = 0
    while ($varLoopCounter -lt $varMaxTransientErrorRetryAttempts) {
        $varLoopCounter++
        try {
            .\initializeDatabase.ps1 `
                -parResourceGroupName $varResourceGroupName `
                -parAttestationProviderName $varAttestationProviderName `
                -parSqlServerName $varSqlServerName `
                -parSqlDatabaseName $varSqlDatabaseName `
                -parSqlAdminUser $parSqlAdministratorLogin `
                -parSqlAdminPassword $parSqlAdministratorPassword `
                -parVmServicePrincipalName $varVmName `
                -parColumnMasterKeyUrl $varCmkUrl

            return
        }
        catch {
            $varLoopCounter++
            $varException = $_.Exception
            $varErrorDetails = $_.ErrorDetails
            $varTrace = $_.ScriptStackTrace
            Write-Error "$varException \n $varErrorDetails \n $varTrace" -ErrorAction Continue

            if ($varLoopCounter -eq $varMaxTransientErrorRetryAttempts) {
                Write-Information ">>> Maximum number of retry attempts reached. Cancelling deployment." -InformationAction Continue
                Write-Error ">>> Error occurred in initializing database deployment. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

# Begin execution
# Preliminaries
$varAzContext = Get-AzContext
$varAzContextUserObjectId = $varAzContext.Account.ExtendedProperties.HomeAccountId.Split('.')[0]
$varAzContextAccountId = $varAzContext.Account.Id

#Check the deployment location
$varAllowedLocations = @("eastus", "westus", "northeurope", "westeurope")
$varAppWorkloadParameters = Get-Content -Path $varHRAppParametersFile | ConvertFrom-Json
$varDeploymentLocation = $varAppWorkloadParameters.parameters.psobject.properties | Where-Object { $_.Name -eq "parDeploymentLocation" }
if ($null -eq $varDeploymentLocation -or $varDeploymentLocation.Value.value -notin $varAllowedLocations) {
    Write-Error ">>> parDeploymentLocation in the parameter file can only be eastus or westus or northeurope or westeurope. These are the only locations that support both Azure Confidential Ledger and AMD CVM DCasv5-series." -ErrorAction Stop
}

# Validate the app resource deployment script with the values from parameter file.
New-AppResourceDeployment `
    -parDeployingUserObjectId $varAzContextUserObjectId `
    -parDeployingUserUpn $varAzContextAccountId `
    -parIsValidation $True

Register-Compute

# Create the app resource deployment in Azure and parse the returned object to retrieve outputs
$varAppDeployment = New-AppResourceDeployment `
    -parDeployingUserObjectId $varAzContextUserObjectId `
    -parDeployingUserUpn $varAzContextAccountId

# Load content into the Azure SQL Database (turning on Always Encrypt)
if ($parInitializeDatabase) {
    Initialize-AppDatabase `
        -parResourceDeploymentOutputs $varAppDeployment.Outputs
}
