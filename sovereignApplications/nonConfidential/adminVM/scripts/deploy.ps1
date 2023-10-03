# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script deploy the admin virtual machine.

.DESCRIPTION
- Executes the individual modules to read parameter values and create the admin virtual machine.

#>
$varParameters = Get-Content -Path .\parameters\adminvm.parameters.json | ConvertFrom-Json
$varTimestamp = Get-Date -Format FileDateTimeUniversal
$parDeploymentLocation = $varParameters.parameters.parDeploymentLocation.value

$varVmDeployResult = New-AzDeployment -Name AdminVM-$varTimestamp `
    -Location $parDeploymentLocation `
    -TemplateFile ".\adminvm.bicep" `
    -TemplateParameterFile ".\parameters\adminvm.parameters.json" `
    -ErrorAction Stop

$varBastion = Get-AzBastion
$varBastionName = $varBastion.Name
$varBastionResourceGroupName = $varBastion.ResourceGroupName
$varBastionSubscriptionId = $varBastion.Id.Substring(15, 36)
$varVmResourceId = $varVmDeployResult.Outputs.outVmResourceId.value

az login
az account set --subscription $varBastionSubscriptionId
az network bastion update --name $varBastionName --resource-group $varBastionResourceGroupName --enable-tunneling true --sku "Standard"
az network bastion rdp --name $varBastionName --resource-group $varBastionResourceGroupName --target-resource-id $varVmResourceId
Write-Information ">>> Admin virtual machine deployment Successful" -InformationAction Continue
