# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script executes the below list of prerequisite checks to confirm before execution.

- Verify PowerShell Verion
- Verify Azure PowerShell version
- Verify Azure CLI version
- Update Bicep version
- Check the user executing has the owner permission on the root ("/") scope of the tenant and assign root ("/") permission if the user is missing the same

AUTHOR/S: Cloud for Sovereignty
#>

param ()

$varSignedInUser = $null;

#reference to individual scripts
. "..\..\..\common\common.ps1"

function Confirm-PowerShellVersion {
    <#

    .SYNOPSIS
    This function checks the current version of PowerShell and prompts the user to install the latest version if the current version is not compatible with the script.
    .EXAMPLE
    Confirm-PowerShellVersion
    .EXAMPLE
    Confirm-PowerShellVersion -parMajorVersion 7 -parMinorVersion 1
    .PARAMETER parMajorVersion
    The major version of PowerShell to check for
    .PARAMETER parMinorVersion
    The minor version of PowerShell to check for

    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$parMajorVersion = 7,

        [Parameter(Mandatory = $false)]
        [int]$parMinorVersion = 1
    )
    $varVersion = $PSVersionTable.PSVersion
    Write-Information "`n>>> Checking if the current version of PowerShell $varVersion is compatible with the script- " -InformationAction Continue

    if ($varVersion.Major -eq $parMajorVersion -and $varVersion.Minor -ge $parMinorVersion) {
        Write-Information "The installed version of PowerShell is compatible with the script." -InformationAction Continue
        return $true
    }
    else {
        Write-Warning "The installed version of PowerShell is not compatible with the script. Please upgrade to the latest version." -WarningAction Continue
        $varConfirmLatestPSInstalled = $(Read-Host -prompt "Do you want to install the latest version of PowerShell (Y/N)?")
        if ($varConfirmLatestPSInstalled -eq 'Y' -or $varConfirmLatestPSInstalled -eq 'y') {
            Write-Information "Installing the latest version of PowerShell" -InformationAction Continue
            if (Get-Command winget -errorAction SilentlyContinue) {
                winget install --id Microsoft.Powershell --source winget *> $null
                Write-Information "To continue with the next steps, please switch to the latest version of installed PowerShell. Exiting the script." -InformationAction Continue
                Exit
            }
            else {
                Start-Process "https://aka.ms/install-powershell"
            }
            return $true
        }
        return $false
    }
}
function Confirm-AZPSVersion {
    <#

    .SYNOPSIS
    This function checks the current version of Azure PowerShell module and prompts the user to install the latest version if the current version is not compatible with the script.
    .EXAMPLE
    Confirm-AZPSVersion
    .EXAMPLE
    Confirm-AZPSVersion -parMajorVersion 9
    .PARAMETER parMajorVersion
    The major version of Azure PowerShell module to check for

    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$parMajorVersion = 9
    )
    try {
        $varAzPsVersion = (Get-InstalledModule -Name Az).Version
    }
    catch {
        Write-Information "Installing the latest version of Azure AZ PowerShell module. This could take up to 5 minutes. You will be prompted with next step when this installation completes." -InformationAction Continue
        Install-Module -Name Az -AllowClobber -Force
    }
    $varAzPsVersion = (Get-InstalledModule -Name Az).Version
    $varCompatibleVersionInstalled = [Version]$varAzPsVersion -ge [Version]"$parMajorVersion.0.0"
    if ($varCompatibleVersionInstalled) {
        Write-Information "The installed version of Azure AZ PowerShell module is compatible with the script." -InformationAction Continue
    }
    else {
        Write-Warning "The installed version of Azure AZ PowerShell module ($varAzPsVersion) is not compatible with the script. Please upgrade to the latest version." -WarningAction Continue
        $confirmLatestAzureAZModuleInstalled = $(Read-Host -prompt "Do you want to install the latest version of Azure AZ PowerShell module (Y/N)?")
        if ($confirmLatestAzureAZModuleInstalled -eq 'Y' -or $confirmLatestAzureAZModuleInstalled -eq 'y') {
            Write-Information "Installing the latest version of Azure AZ PowerShell module. This could take up to 5 minutes. You will be prompted with next step when this installation completes." -InformationAction Continue
            Install-Module -Name Az -AllowClobber -Force
        }
    }
    return $varCompatibleVersionInstalled
}

function Confirm-AZCLIVersion {
    <#
        .SYNOPSIS
        This function checks the current version of Azure CLI and prompts the user to install the latest version if the current version is not compatible with the script.
        .EXAMPLE
        Confirm-AZCLIVersion
        .EXAMPLE
        Confirm-AZCLIVersion -parMajorVersion 2 -parMinorVersion 40
        .PARAMETER parMajorVersion
        The major version of Azure CLI to check for
        .PARAMETER parMinorVersion
        The minor version of Azure CLI to check for
    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$parMajorVersion = 2,

        [Parameter(Mandatory = $false)]
        [int]$parMinorVersion = 40
    )
    Write-Information "`n>>> Check the current version of azure cli installed - " -InformationAction Continue
    $varHasCompatibleVersion = $false
    if (Get-Command "az" -errorAction SilentlyContinue) {
        $azversion = ((az version -o tsv) -split "\t")[0] -split "\."
        $varCompatibleVersionInstalled = $azversion[0] -eq $parMajorVersion -and $azversion[1] -ge $parMinorVersion
        if ($varCompatibleVersionInstalled) {
            $varHasCompatibleVersion = $true
            Write-Information "The installed version of Azure CLI is compatible with the script." -InformationAction Continue
        }
        else {
            Write-Warning "The installed version of Azure CLI is not compatible with the script. Please upgrade to the latest version." -WarningAction Continue
        }
    }

    if ($varHasCompatibleVersion -eq $false) {
        $confirmLatestAzureCLIInstalled = $(Read-Host -prompt "Do you want to install the latest version of Azure CLI (Y/N)?")
        if ($confirmLatestAzureCLIInstalled -eq 'Y' -or $confirmLatestAzureCLIInstalled -eq 'y') {
            Write-Information "Installing the latest version of Azure CLI" -InformationAction Continue
            Start-Process "https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest"
            return $true
        }
        return $false
    }
    return $true
}

function Confirm-BicepVersion {
    <#
        .SYNOPSIS
        This function checks the current version of Azure Bicep and prompts the user to install the latest version
        .EXAMPLE
        Confirm-BicepVersion
    #>
    Write-Information "`n>>> Check the current version of Azure Bicep installed - " -InformationAction Continue

    $varHasCompatibleVersion = $false
    $varCurrentBicepVersion = ""
    $varCurrentBicepVersion = ((az bicep version) -split " ")[3]

    if (($varCurrentBicepVersion -ne "") -and ($null -ne $varCurrentBicepVersion)) {
        ##when az bicep version command is run, platform already prints the latest version of the Azure Bicep, so no need to print it again.
        Write-Information "The installed version of Azure Bicep: $varCurrentBicepVersion" -InformationAction Continue

        $latestAvailableBicepVersion = ((az bicep list-versions | ConvertFrom-Json)[0]).Replace("v", "")
        if ($varCurrentBicepVersion -eq $latestAvailableBicepVersion) {
            $varHasCompatibleVersion = $true
            Write-Information "The installed version of Azure Bicep is latest." -InformationAction Continue
        }
        else {
            Write-Warning "The installed version of Azure Bicep is not latest. Please upgrade to the latest version $latestAvailableBicepVersion to continue." -WarningAction Continue
        }
    }
    else {
        Write-Information "Azure Bicep is not installed currently." -InformationAction Continue
    }

    if ($varHasCompatibleVersion -eq $false) {
        $varConfirmLatestAzureBicep = $(Read-Host -prompt "Do you want to install the latest version of Azure Bicep? (Y/N)?")
        if ($varConfirmLatestAzureBicep -eq 'Y' -or $varConfirmLatestAzureBicep -eq 'y') {
            Write-Information "Installing the latest version of Azure Bicep" -InformationAction Continue
            if ($varCurrentBicepVersion -eq "") {
                az bicep install
            }
            else {
                az bicep upgrade
            }
        }
        else {
            Write-Warning "The installed version of Azure Bicep is not compatible with the script. Please upgrade to the latest version." -WarningAction Continue
            return $false
        }
    }
    return $true
}
function Confirm-AZResourceGraphVersion {
    <#
    .SYNOPSIS
    This function checks the current version of Az.ResourceGraph module and prompts the user to install the latest version if the current version is not compatible with the script.
    #>
    param()
    $varRgVersion = $null
    try {
        $varRgVersion = (Get-InstalledModule -Name Az.ResourceGraph).Version
        if ($null -eq $varRgVersion) {
            Install-Module -Name Az.ResourceGraph -AllowClobber -Force
            $varRgVersion = (Get-InstalledModule -Name Az.ResourceGraph).Version
        }
    }
    catch {
        Write-Information "Installing the latest version of Azure Az.ResourceGraph PowerShell module. This could take up to 5 minutes. You will be prompted with next step when this installation completes." -InformationAction Continue
        Install-Module -Name Az.ResourceGraph -AllowClobber -Force
        $varRgVersion = (Get-InstalledModule -Name Az.ResourceGraph).Version
    }

    Write-Information "The version of Az.ResourceGraph module is $varRgVersion" -InformationAction Continue
    return
}

<#
    .SYNOPSIS
    This function Confirm the pre-requisites to be executed
    .EXAMPLE
    Confirm-PreRequisites
#>
function Confirm-PreRequisites {
    param(
        [bool]$parConfirmPsVersion = $true,
        [bool]$parConfirmAzPsVersion = $true,
        [bool]$parConfirmAzCliVersion = $true,
        [bool]$parConfirmBicepVersion = $true,
        [bool]$parConfirmAzResGraphVersion = $false
    )

    if ($parConfirmPsVersion) {
        $varPsVerCompatible = Confirm-PowerShellVersion
    }

    if ($parConfirmAzPsVersion) {
        $varAzPsVerCompatible = Confirm-AZPSVersion
    }

    if ($parConfirmAzCliVersion) {
        $varAzCliVerCompatible = Confirm-AZCLIVersion
    }

    if ($parConfirmBicepVersion) {
        $varBicepVerCcompatible = Confirm-BicepVersion
    }

    if ($parConfirmAzResGraphVersion) {
        Confirm-AZResourceGraphVersion
    }

    if ($varPsVerCompatible -eq $false -or $varAzPsVerCompatible -eq $false -or $varAzCliVerCompatible -eq $false -or $varBicepVerCcompatible -eq $false) {
        Write-Error "Please install the latest version of PowerShell, Azure PowerShell module, Azure CLI and bicep and try again." -ErrorAction Stop
    }

    $varSignedInUser = Get-SignedInUser

    # if user is not signed in trigger login
    if ($null -eq $varSignedInUser) {
        Enter-Login
        $varSignedInUser = Get-SignedInUser
    }

    # check owner permissions of the user
    $varUserPermissions = Confirm-UserOwnerPermission

    # if user does not have owner permissions.
    if ($varUserPermissions -ne $true) {
        Write-Error "`n>>> Signed in user: $varSignedInUser doesn't have the necessary permissions." -ErrorAction Stop
    }

    Write-Information "`n>>> Signed in user: $varSignedInUser has the necessary permissions." -InformationAction Continue
    Write-Information "`n>>> Please go ahead and execute - deployment script" -InformationAction Continue
    Write-Information "`n>>> Please remember to review the parameters.json file before deployment." -InformationAction Continue
}

try {
    Confirm-PreRequisites -parConfirmAzResGraphVersion $parConfirmAZResourceGraphVersion
}
catch {
    Write-Error $_
}
