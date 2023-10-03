// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the subnet of virtual network.
DESCRIPTION: This module will create a deployment which will create the subnet of virtual network.
AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'resourceGroup'

param parHubNetwork string
param parSubnetName string
param parSubnetAddressSpace string

resource resVnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing =  {
  name: parHubNetwork
}

resource resSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  name: parSubnetName
  parent: resVnet
  properties:{
    addressPrefix: parSubnetAddressSpace
  }
}

output outSubnetId string = resSubnet.id
