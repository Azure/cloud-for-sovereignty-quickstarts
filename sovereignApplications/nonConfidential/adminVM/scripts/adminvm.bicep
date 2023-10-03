// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the admin virtual machine bicep script.
DESCRIPTION: This module will create a deployment which will create the admin virtual machine to deploy HR App workload.
AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'subscription'

// Core deployment/location parameters
param parDeploymentLocation string
param parRg string = 'admin-rg-vm'

// Network connectivity parameters
param parHubNetworkRg string
param parHubNetwork string
param parSubnetAddressSpace string = '10.20.100.0/24'
param parSubnetName string = 'AdminVmSubnet'

// VM user
@maxLength(20)
param parAdminUsername string = 'slzadmin'
@secure()
param parAdminPassword string

@description('Timestamp used to date subdeployments.')
param parTimestamp string = utcNow()

// RG in which VM will deploy
resource resRg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: parRg
  location: parDeploymentLocation
}

// Creates a subnet in the SLZ hub vnet for the admin workstation to connect to
module modSubnet '../modules/subnet.bicep' = {
  name: 'AdminVM-Subnet-${parTimestamp}'
  scope: resourceGroup(parHubNetworkRg)
  params: {
    parHubNetwork: parHubNetwork
    parSubnetName: parSubnetName
    parSubnetAddressSpace: parSubnetAddressSpace
  }
}

// Creates the VM
module modWin11Vm '../modules/win11vm.bicep' = {
  scope: resRg
  name: 'AdminVM-VM-${parTimestamp}'
  params: {
    parDeploymentLocation: parDeploymentLocation
    parSubnetId: modSubnet.outputs.outSubnetId
    parAdminUsername: parAdminUsername
    parAdminPassword: parAdminPassword
  }
}

output outVmName string = modWin11Vm.outputs.outVmName
output outVmResourceId string = modWin11Vm.outputs.outVmResourceId
