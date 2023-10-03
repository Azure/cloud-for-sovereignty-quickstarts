# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script serves as the overarching script to deploy the workload template either in its entirety or in a piecemeal manner the below individual modules.

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
    [Parameter(Mandatory = $false, Position = 0)]
    [bool] $parAttendedLogin = $true
)

#reference to common scripts
. "..\..\..\common\common.ps1"

# Retry logic parameters (in case of transient errors)
$varMaxTransientErrorRetryAttempts = 3
$varRetryWaitTime = 60

#bicep files
$varConfidentialVirtualMachineApp = 'confidentialVirtualMachineApp.bicep'
$varAppParametersFile = './parameters/confidentialVirtualMachine.parameters.json'

<#
.DESCRIPTION
    Deploys confidential virtual machine template Azure resources.
#>
function New-AppResourceDeployment {
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string] $parDeployingUserObjectId,
        [Parameter(Mandatory = $False, Position = 2)]
        [bool] $parIsValidation = $False
    )

    $varDonotRetryErrorCodes = Get-DonotRetryErrorCodes '../../../common/const/doNotRetryErrorCodes.json'
    $varLoopCounter = 0
    while ($varLoopCounter -lt $varMaxTransientErrorRetryAttempts) {
        try {
            Write-Information ">>> Starting deployment of confidential virtual machine template Azure resources." -InformationAction Continue
            $varTimestamp = Get-Date -Format FileDateTimeUniversal
            $varAppDeployment = $null
            $varDeploymentName = "App-$varTimestamp"
            if ($parIsValidation) {
                $varAppDeployment = Test-AzDeployment `
                    -Name $varDeploymentName `
                    -Location $parRootDeploymentLocation `
                    -TemplateFile $varConfidentialVirtualMachineApp `
                    -TemplateParameterFile $varAppParametersFile `
                    -parDeployingUserObjectId $parDeployingUserObjectId `

                if ($varAppDeployment.Count -gt 0) {
                    Write-Error $varAppDeployment[0].Message -ErrorAction Stop
                }

                Write-Information ">>> Successfully validated input parameter file." -InformationAction Continue
            }
            else {
                $varAppDeployment = New-AzDeployment `
                    -Name $varDeploymentName `
                    -Location $parRootDeploymentLocation `
                    -TemplateFile $varConfidentialVirtualMachineApp `
                    -TemplateParameterFile $varAppParametersFile `
                    -parDeployingUserObjectId $parDeployingUserObjectId `

                if (!$varAppDeployment -or $varAppDeployment.ProvisioningState -eq "Failed") {
                    Write-Error "Error while executing confidential virtual machine template deployment." -ErrorAction Stop
                }
                else {
                    Write-Information ">>> Successfully deployed confidential virtual machine template Azure resources." -InformationAction Continue
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
                Write-Error ">>> Error occurred in confidential virtual machine template. Please try after addressing the error : $varException \n $varErrorDetails \n $varTrace" -ErrorAction Stop
            }
        }
    }
}

# Begin execution
# Preliminaries
$varAzContext = Get-AzContext
$varAzContextUserObjectId = $varAzContext.Account.ExtendedProperties.HomeAccountId.Split('.')[0]

if ($parAttendedLogin) {
    # Confirm Prerequisites
    Confirm-Prerequisites
}

# Validate the app resource deployment script with the values from parameter file.
$varAppDeployment = New-AppResourceDeployment `
    -parDeployingUserObjectId $varAzContextUserObjectId `
    -parIsValidation $True

Register-Compute
# Create the App resource deployment in Azure and parse the returned object to retrieve outputs
$varAppDeployment = New-AppResourceDeployment `
    -parDeployingUserObjectId $varAzContextUserObjectId

# Final message for successful deployment
Write-Information ">>> Confidential VM deployment Successful" -InformationAction Continue
