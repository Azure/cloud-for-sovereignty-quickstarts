// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to create the resource group.
DESCRIPTION: This module will create a deployment at subscription level which will create the resource group and add the customer usage attribution (PID) to Subscription deployments.
AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'subscription'

metadata name = 'ALZ Bicep - Resource Group creation module'
metadata description = 'Module used to create Resource Groups'

@sys.description('Azure Region where Resource Group will be created.')
param parLocation string

@sys.description('Name of Resource Group to be created.')
param parResourceGroupName string

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

// Customer Usage Attribution Id
var varCuaid = 'b6718c54-b49e-4748-a466-88e3d7c789c8'

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: parLocation
  name: parResourceGroupName
  tags: parTags
}

module modCustomerUsageAttribution '../CRML/customerUsageAttribution/cuaIdSubscription.bicep' = if (!parTelemetryOptOut) {
  name: 'pid-${varCuaid}-${uniqueString(subscription().subscriptionId, parResourceGroupName)}'
  params: {}
}

output outResourceGroupName string = resResourceGroup.name
output outResourceGroupId string = resResourceGroup.id
