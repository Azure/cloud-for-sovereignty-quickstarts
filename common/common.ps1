# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script serves common functions to deploy sample apps and Workload templates.

.DESCRIPTION
- Executes the individual modules - lighthouse

#>

using namespace System.Collections

param (
    $parAttendedLogin = $true
)

#variables to support incremental delay for azure resource validation checks (All time in seconds)
$varMaxIntervalResourceExistsCheck = 60
$varIntervalMultiplierResourceExistsCheck = 5

<#
.Description
    Login to Azure portal
#>
function Enter-Login {
    Write-Information ">>> Initiating a login" -InformationAction Continue
    Connect-AzAccount
}

<#
.Description
    Get details of user
#>
function Get-SignedInUser {

    $varSignedInUserDetails = Get-AzADUser -SignedIn

    if (!$varSignedInUserDetails) {
        Write-Information ">>> No logged in user found." -InformationAction Continue
    }
    else {
        return $varSignedInUserDetails.UserPrincipalName
    }

    return $null

}

<#
.Description
   Confirm the user is owner at the root scope
#>
function Confirm-UserOwnerPermission {
    if ($null -ne $varSignedInUser) {

        Write-Information "`n>>> Checking the owner permissions for user: $varSignedInUser at '/' scope"  -InformationAction Continue
        $varRetrieveOwnerPermissions = Get-AzRoleAssignment `
            -SignInName $varSignedInUser `
            -Scope "/" `
            -RoleDefinitionName "Owner"

        if ($varRetrieveOwnerPermissions.RoleDefinitionName -ne "Owner") {
            Write-Information "Signed in user: $varSignedInUser does not have owner permission to the root '/' scope."  -InformationAction Continue
            return $false
        }
        else {
            Write-Information "Signed in user: $varSignedInUser has owner permissions at the root '/' scope."  -InformationAction Continue
        }
        return $true
    }
    else {
        Write-Error "Logged in user details are empty." -ErrorAction Stop
    }
}

function Set-UserOwnerPermission {
    Write-Host ">>> Assigning user with Owner permissions."

    # Assign "Owner" role to the signed-in user at the root scope "/"
    New-AzRoleAssignment `
        -SignInName $varSignedInUser `
        -Scope "/" `
        -RoleDefinitionName "Owner"
}

function Invoke-UserPermissionsConfirmation {
    param($parPermissionType)
    Write-Host "`n>>> Confirming user's permissions. This might trigger an auto log out and require the user to login back in a few times"

    $varWaitTime = 10
    $varLoopCounter = 0

    while ($varTotalWaitTime -lt $varMaxWaitTimeResourceExistsCheck -and $varUserPermissions -eq $false) {
        try {
            # Log out to refresh the session
            Get-AzContext | Remove-AzContext -Confirm:$false
            Connect-AzAccount

            # check owner permissions of the user
            $varUserPermissions = Confirm-UserOwnerPermission

            if ($varUserPermissions -ne $true) {
                Write-Host ">>> Checking the permissions after waiting for $varWaitTime secs. Please ensure that you are logged into the appropriate tenant and did not log in to a different tenant during the script execution."
                $varLoopCounter++
                $varWaitTime = New-IncrementalDelay $varWaitTime $varLoopCounter
                $varTotalWaitTime += $varWaitTime
                Start-Sleep -Seconds $varWaitTime
            }
        }
        catch {
            $_.Exception
            Write-Host ">>> Retrying after waiting for $varWaitTime secs. To stop the retry press Ctrl+C."
            $varLoopCounter++
            $varWaitTime = New-IncrementalDelay $varWaitTime $varLoopCounter
            $varTotalWaitTime += $varWaitTime
            Start-Sleep -Seconds $varWaitTime
        }
    }
}

<#
.Description
   Caclulates and returns the number of seconds to wait
#>
function New-IncrementalDelay {
    param($parDelay, $parDelayIterator)
    $parDelay = $parDelay + ($parDelayIterator * $varIntervalMultiplierResourceExistsCheck)
    if ($parDelay -ge $varMaxIntervalResourceExistsCheck) {
        $parDelay = $varMaxIntervalResourceExistsCheck
    }
    return $parDelay
}

<#
.Description
   Confirm parameters
#>
function Confirm-Parameters($parParameters) {
    $varMissingParameters = New-Object Collections.Generic.List[String]
    $varArrayParameters = @("parAllowedLocations", "parAllowedLocationsForConfidentialComputing", "parPolicyDefinitionReferenceIds")
    Foreach ($varParameter in $parParameters) {
        if ($varParameter -in $varArrayParameters -and $varParameters.$varParameter.value.count -eq 0) {
            if (!$parAttendedLogin) {
                $varMissingParameters.add($varParameter)
            }
            else {
                [string[]] $varArray = @()
                $varArray = Read-Host "Please enter the list of $varParameter with a comma between each"
                if ($varArray[0] -eq "") {
                    Write-Error "$varParameter value not found" -ErrorAction Stop
                }
                $varParameters.$varParameter.value = $varArray.Split(',')
            }
        }
        elseif (($null -eq $varParameters.$varParameter.value) -or [string]::IsNullOrEmpty($varParameters.$varParameter.value) -or ($varParameters.$varParameter.value -eq "{}")) {
            $varParameters.$varParameter.value = $null
            if (!$parAttendedLogin) {
                $varMissingParameters.add($varParameter)
            }
            else {
                $varParameters.$varParameter.value = $(Read-Host -prompt "Please provide the value for $varParameter")
                if ($varParameters.$varParameter.value -eq "") {
                    Write-Error "$varParameter value not found" -ErrorAction Stop
                }
            }
        }
        elseif ($varParameters.$varParameter.value.count -gt 1) {
            $varValue = $varParameters.$varParameter.value
            if ($varValue -is [array]) {
                foreach ($varElement in $varValue) {
                    $varResult = Confirm-ObjectType($varElement)
                    if ($varResult -eq $false) {
                        $varMissingParameters.add($varParameter)
                    }
                }
            }
            elseif ($varValue -is [object]) {
                $varResult = Confirm-ObjectType($varValue)
                if ($varResult -eq $false) {
                    $varMissingParameters.add($varParameter)
                }
            }
            elseif (($null -eq $varValue) -or [string]::IsNullOrEmpty($varValue) -or ($varValue -eq "{}")) {
                $varParameters.$varParameter.value = $null
                return $false
            }
        }
    }
    if ($varMissingParameters.count -gt 0) {
        Write-Error "Following parameters are missing : $varMissingParameters" -ErrorAction Stop
    }

    $varTenantId = (Get-AzTenant).Id

    if ($varTenantId -eq $varParameters.parConfidentialVirtualMachineManagementTenantId.value ) {
        Write-Error "The value of parameter named parConfidentialVirtualMachineManagementTenantId should not be the same as the tenant id $varTenantId where the ConfidentialVirtualMachine script is being deployed. Please use different tenant id for the parConfidentialVirtualMachineManagementTenantId." -ErrorAction Stop
    }
}

<#
.Description
    Checks the required Object type parameters are passed based on the deployment.
#>
function Confirm-ObjectType($parParameter) {
    if (($null -eq $parParameter)) {
        return $false
    }

    $varMembers = $parParameter.PSObject.Properties | Select-Object Name, Value
    foreach ($varMember in $varMembers) {
        if (($null -eq $varMember.value) -or [string]::IsNullOrEmpty($varMember.value) -or ($varMember.value -eq "")) {
            return $false
        }
    }

    return $true
}


<#
.Description
   Register Microsoft.Compute namespace.
#>
function Register-Compute {
    Write-Information ">>> Registering EncryptionAtHost feature. This may take up to 30 minutes." -InformationAction Continue
    Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
    while ((Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute").RegistrationState -ne "Registered") {
        Write-Information ">>> Waiting on feature registration to complete, checking again in $varRetryWaitTime seconds." -InformationAction Continue
        Start-Sleep -Seconds $varRetryWaitTime
    }
    Write-Information ">>> EncryptionAtHost feature registered." -InformationAction Continue
}

<#
.Description
    Register resource provider.
#>
function Register-ResourceProvider {
    param($varProviderNamespace)

    $varResourceProvider = $null
    $varLoopCounter = 0

    $varJob = Register-AzResourceProvider -ProviderNamespace $varProviderNamespace -AsJob
    $varJob | Wait-Job > $null

    $varResourceProvider = Get-AzResourceProvider -ProviderNamespace $varProviderNamespace
    while ($null -eq $varResourceProvider -and $varLoopCounter -lt $varMaxRetryAttemptTransientErrorRetry) {
        Start-Sleep -Seconds $varRetryWaitTimeTransientErrorRetry
        $varResourceProvider = Get-AzResourceProvider -ProviderNamespace $varProviderNamespace
        $varLoopCounter++
    }
}

<#
.Description
    Checks Prerequisites for the deployment.
#>
function Confirm-Prerequisites {
    param(
        [int]$parConfirmAZResourceGraphVersion = 0
    )

    Write-Information ">>> Checking Prerequisites for the deployment" -InformationAction Continue
    $varConfirmPrerequisites = '..\..\..\common\confirm-prerequisites.ps1'
    & $varConfirmPrerequisites -parAttendedLogin $parAttendedLogin -parConfirmAZResourceGraphVersion $parConfirmAZResourceGraphVersion -ErrorAction Stop
    Write-Information ">>> Checking Prerequisites is complete." -InformationAction Continue
    return
}

<#
.Description
   Load all the Do not retry error codes from the json file in a hashtable
#>
function Get-DonotRetryErrorCodes {
    param ($parFilePath)

    $varList = New-Object Collections.Generic.List[String]
    $varFile = Get-Content -Path $parFilePath | ConvertFrom-Json
    $varFile.errorCodes | ForEach-Object {
        $varList.add($_.code)
    }

    return $varList
}
