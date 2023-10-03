// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the confidential virtual machine template bicep script.
DESCRIPTION: This module will create a deployment which will create the confidential virtual machine template with its required infrastructures.
AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'subscription'

@description('The prefix that will be added to all resources created by this deployment.')
@minLength(2)
@maxLength(5)
param parDeploymentPrefix string

@description('Deployment location for all resources.')
@allowed([
  'eastus'
  'westus'
  'northeurope'
  'westeurope'
])
param parDeploymentLocation string

@description('Timestamp used to date subdeployments.')
param parTimestamp string = utcNow()

@description('The Resource Group in which this sample workload will be deployed.')
param parResourceGroupName string = '${parDeploymentPrefix}-rg'

@description('Object ID of the user executing this deployment (used for RBAC assignments supporting later scripted steps).')
param parDeployingUserObjectId string

@maxLength(10)
@description('The Attestation Provider name, e.g., prefixattp. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes.')
param parAttestationProvidersName string = '${parDeploymentPrefix}attp'

@description('Name of Key Vault holding keys for disk encryption of VM disks, e.g., myprefix-kv. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes.')
param parKeyVaultName string = '${parDeploymentPrefix}-kv'

@description('Name of the User Assigned Managed Identity used in some RBAC scenarios (e.g., for the Disk Encryption Set).')
param parManagedIdentityName string = '${parDeploymentPrefix}-id'

@description('Key expiry date in seconds since 1970-01-01T00:00:00Z.  Defaults to December 31, 2024.')
param parKeyExpirationDate int = dateTimeToEpoch('20241231T235959Z')

@description('Resource ID of the SLZ\'s hub vnet in the <slzprefix>-connectivity subscription.')
param parHubNetworkResourceId string

@description('IP address space of the VNET created for this workload, in CIDR notation.')
param parVnetAddressPrefix string

@description('IP address space of the VNET subnet created for this workload, in  CIDR notation.')
param parSubnetAddressPrefix string = parVnetAddressPrefix

@description('Name of the Confidential Virtual Machine to be created, e.g., myprefix-vm. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes.')
param parVmName string = '${parDeploymentPrefix}-rg'

@description('Size of the Confidential Virtual Machine to be created. See link for supported sizes https://learn.microsoft.com/en-us/azure/virtual-machines/dcasv5-dcadsv5-series')
param parVmSize string = 'Standard_DC2as_v5'

@description('OS image for the virtual Machine')
param parOsImageName string = 'Ubuntu 22.04 LTS Gen 2'

@description('Username for the virtual machine.')
param parAdminUsername string = '${parDeploymentPrefix}-admin'

@description('Password for the virtual machine. The password must be at least 12 characters long and have lower case, upper characters, digit and a special character (Regex match)')
@secure()
param parAdminPasswordOrKey string

@description('Type of authentication to use on the virtual machine. SSH Public key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param parAuthenticationType string = 'password'

@description('The virtual network name for this deployment, e.g., myprefix-vnet.')
param parVirtualNetworkName string = '${parDeploymentPrefix}-vnet'

@description('The network security group used for virtual network, e.g., myprefix-nsg.')
param parNetworkSecurityGroupName string = '${parDeploymentPrefix}-nsg'

@description('List of tags to be applied to resources.')
param parTags object = { product: 'cvm-accelerator' }

@description('Suffix used to add unique identity to globally namespaced resources.')
var varUniqueSuffix = uniqueString(resResourceGroup.id, parDeploymentLocation)

@description('Key vault name with unique suffix.')
var varUniqueKeyVaultName = '${parKeyVaultName}-${varUniqueSuffix}'

@description('Virtual Machine name with unique suffix.')
var varUniqueVmName = '${parVmName}-${varUniqueSuffix}'

@description('Attestation Provider name with unique suffix.')
var varUniqueAttestationProviderName = '${parAttestationProvidersName}${varUniqueSuffix}'

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: parDeploymentLocation
  name: parResourceGroupName
  tags: parTags
}

module modManagedIdentity '../../../common/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'App-Managed-Identity-${parTimestamp}'
  scope: resResourceGroup
  params: {
    parLocation: parDeploymentLocation
    parName: parManagedIdentityName
    parTags: parTags
  }
}

module modCommonInfra 'confidentialVirtualMachineInfra.bicep' = {
  name: 'CVMApp-Workload-${parTimestamp}'
  scope: resResourceGroup
  params: {
    parManagedIdentityName: modManagedIdentity.outputs.outName
    parAttestationProvidersName: varUniqueAttestationProviderName
    parKeyVaultName: varUniqueKeyVaultName
    parDeploymentLocation: parDeploymentLocation
    parVirtualNetworkName: parVirtualNetworkName
    parNetworkSecurityGroupName: parNetworkSecurityGroupName
    parTags: parTags
    parVnetAddressPrefix: parVnetAddressPrefix
    parSubnetAddressPrefix: parSubnetAddressPrefix
    parHubNetworkResourceId: parHubNetworkResourceId
    parKeyVaultOrMhsmAdminObjectId: parDeployingUserObjectId
    parAttestationContributorObjectId: parDeployingUserObjectId
    parKeyExpirationDate: parKeyExpirationDate
  }
}

module modVM 'confidentialVirtualMachine.bicep' = {
  name: 'App-Workload-CVM-${parTimestamp}'
  scope: resResourceGroup
  params: {
    parTags: parTags
    parKeyVaultName: varUniqueKeyVaultName
    parDiskEncryptionSetId: modCommonInfra.outputs.outDiskEncryptionSetId
    parVmkeyId: modCommonInfra.outputs.outVmkeyId
    parVmName: varUniqueVmName
    parVmSize: parVmSize
    parOsImageName: parOsImageName
    parAdminUsername: parAdminUsername
    parAdminPasswordOrKey: parAdminPasswordOrKey
    parAuthenticationType: parAuthenticationType
    parDeploymentLocation: parDeploymentLocation
    parAttestationUri: modCommonInfra.outputs.outAttestationProviderAttestUri
    parAttestationProvidersName: varUniqueAttestationProviderName
    parVirtualNetworkName: parVirtualNetworkName
    parVmUserData: '{}'
  }
}

output outResourceGroupName string = resResourceGroup.name
output outAttestationProviderName string = modCommonInfra.outputs.outAttestationProviderName
output outVmName string = modVM.outputs.outVmName
