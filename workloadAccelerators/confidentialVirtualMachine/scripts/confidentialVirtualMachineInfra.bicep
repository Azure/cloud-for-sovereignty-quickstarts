// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the azure infrastructures for confidential virtual machine template bicep script.
DESCRIPTION: This module will create a deployment which will create the required infrastructures of the confidential virtual machine template.
AUTHOR/S: Cloud for Sovereignty
*/
@description('Location for all resources.')
@allowed([
  'eastus'
  'westus'
  'northeurope'
  'westeurope'
])
param parDeploymentLocation string

@description('Timestamp used to date subdeployments.')
param parTimestamp string = utcNow()

@description('Name of the User Assigned Managed Identity used in some RBAC scenarios (e.g., for the Disk Encryption Set).')
param parManagedIdentityName string

@description('Object ID for the Azure AD user who is set as Key Vault Administrator on Key Vault or Managed HSM.')
param parKeyVaultOrMhsmAdminObjectId string

@description('Object ID for the Azure AD user who is set as Attestation Contributor.')
param parAttestationContributorObjectId string

@description('Attestation providers name')
param parAttestationProvidersName string

@description('Key vault name')
param parKeyVaultName string

@description('Name of the virtual network')
param parVirtualNetworkName string

@description('Name of the network security group')
param parNetworkSecurityGroupName string

@description('Resource tags')
param parTags object

@description('The key size in bits. For example: 2048, 3072, or 4096 for RSA.')
@allowed([
  2048
  3072
  4096
])
param parKeySize int = 2048

@description('The type of key to create')
@allowed([
  'EC'
  'EC-HSM'
  'RSA'
  'RSA-HSM'
])
param parKty string = 'RSA'

@description('Name of the key created for use with VM Disk Encryption Set.')
param parVmDiskEncryptionKeyName string = 'VmDiskEncryptionKey'

@description('Expiry date in seconds since 1970-01-01T00:00:00Z.')
param parKeyExpirationDate int

@description('IP address space of the VNET created for this workload, in  CIDR notation.')
param parVnetAddressPrefix string

@description('IP address space of the VNET child subnet created for this workload, in  CIDR notation.')
param parSubnetAddressPrefix string

@description('Resource ID of the SLZ\'s hub vnet in the <slzprefix>-connectivity subscription.')
param parHubNetworkResourceId string

var varSubnetName = 'subnet'
var varDiskEncryptionSetName = 'diskEncryptionSetVM'

var varRoleIdMapping = {
  KeyVaultCryptoOfficer: '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
  KeyVaultAdministrator: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  AttestationContributor: 'bbf86eb8-f7b4-4cce-96e4-18cddf81d86e'
}

// These computed values are used by the Peering module to connect hub->spoke vnet
var varHubNetworkSubscription = split(parHubNetworkResourceId,'/')[2]
var varHubNetworkResourceGroup = split(parHubNetworkResourceId, '/')[4]
var varHubNetworkName = split(parHubNetworkResourceId, '/')[8]

// The built-in Key Vault Administrator role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-administrator
resource resKeyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: varRoleIdMapping.KeyVaultAdministrator
}

// The built-in Attestation Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#attestation-contributor
resource resAttestationContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: varRoleIdMapping.AttestationContributor
}

resource resManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: parManagedIdentityName
}

resource resAttestationProvider 'Microsoft.Attestation/attestationProviders@2021-06-01' = {
  name: parAttestationProvidersName
  location: parDeploymentLocation
  tags: parTags
  properties: {
  }
}

// Assign the RBAC Attributon Contributor role to the newly minted Attestation Provider.
resource resAttestationContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resAttestationProvider
  name: guid(resAttestationProvider.id, parAttestationContributorObjectId, varRoleIdMapping.AttestationContributor)
  properties: {
    roleDefinitionId: resAttestationContributorRoleDefinition.id
    principalId: parAttestationContributorObjectId
  }
}

// Attestation Provider Private Endpoint
var varAttestationPrivateEndpointName = 'endpoint-${parAttestationProvidersName}'
resource resAttestationProviderEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: varAttestationPrivateEndpointName
  location: parDeploymentLocation
  tags: parTags
  properties: {
    privateLinkServiceConnections: [
      {
        name: varAttestationPrivateEndpointName
        properties: {
          privateLinkServiceId: resAttestationProvider.id
          groupIds: [
            'standard'
          ]
        }
      }
    ]
    subnet: {
      id: resVirtualNetwork.properties.subnets[0].id
    }
    customNetworkInterfaceName: 'nic-${varAttestationPrivateEndpointName}'
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: parKeyVaultName
  location: parDeploymentLocation
  tags: parTags
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: true
    enablePurgeProtection: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: tenant().tenantId
    accessPolicies: []
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource resVmDiskEncryptionKey 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: keyvault
  name: parVmDiskEncryptionKeyName
  tags: parTags
  properties: {
    kty: parKty
    keySize: parKeySize
    attributes: {
      exp: parKeyExpirationDate
    }
  }
  dependsOn: [
	KeyVaultAdminForManagedIdentity
  ]
}

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-03-02' = {
  name: varDiskEncryptionSetName
  location: parDeploymentLocation
  tags: parTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resManagedIdentity.id}': {
      }
    }
  }
  properties: {
    activeKey: {
      sourceVault: {
        id: keyvault.id
      }
      keyUrl: resVmDiskEncryptionKey.properties.keyUriWithVersion
    }
    encryptionType: 'EncryptionAtRestWithPlatformAndCustomerKeys'
    rotationToLatestKeyVersionEnabled: true
  }
  dependsOn: [
	KeyVaultAdminForManagedIdentity
  ]
}

resource KeyVaultAdminForManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyvault
  name: guid(keyvault.id, resManagedIdentity.id, varRoleIdMapping.KeyVaultAdministrator)
  properties: {
    roleDefinitionId: resKeyVaultAdministratorRoleDefinition.id
    principalId: resManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource KeyVaultAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyvault
  name: guid(keyvault.id, parKeyVaultOrMhsmAdminObjectId, varRoleIdMapping.KeyVaultAdministrator)
  properties: {
    roleDefinitionId: resKeyVaultAdministratorRoleDefinition.id
    principalId: parKeyVaultOrMhsmAdminObjectId
  }
}

resource resNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: parNetworkSecurityGroupName
  location: parDeploymentLocation
}

resource resVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: parVirtualNetworkName
  location: parDeploymentLocation
  tags: parTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        parVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: varSubnetName
        properties: {
          addressPrefix: parSubnetAddressPrefix
          networkSecurityGroup: {
            id: resNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Peering from new VNET to the hub network in SLZ -connectivity subscription
module modPeeringToHub '../../../common/modules/module.peering.bicep' = {
  name: 'VentPeering.Outgoing-${parTimestamp}'
  params: {
    parHomeNetworkName: resVirtualNetwork.name
    parRemoteNetworkId: parHubNetworkResourceId
    parAllowGatewayTransit: false
    parUseRemoteGateways: true
  }
}

// Inverse peering from hub network in SLZ -connectivity subscription to the new VNET
module modPeeringFromHub '../../../common/modules/module.peering.bicep' = {
  name: 'VentPeering.Outgoing-${parTimestamp}'
  scope: resourceGroup(varHubNetworkSubscription, varHubNetworkResourceGroup)
  params: {
    parHomeNetworkName: varHubNetworkName
    parRemoteNetworkId: resVirtualNetwork.id
    parAllowGatewayTransit: true
    parUseRemoteGateways: false
  }
}

output outDiskEncryptionSetId string = diskEncryptionSet.id
output outVmkeyId string = resVmDiskEncryptionKey.id
output outVmkeyUrl string = resVmDiskEncryptionKey.properties.keyUriWithVersion
output outVirtualNetworkName string = resVirtualNetwork.name
output outVirtualNetworkId string = resVirtualNetwork.id
output outAttestationProviderName string = resAttestationProvider.name
output outAttestationProviderAttestUri string = resAttestationProvider.properties.attestUri
