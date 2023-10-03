// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the Azure storage account with managed customer keys.
DESCRIPTION: This module will create a deployment which will create the Azure storage account, key vaulter and managed customer keys to store and manage data and logs.
AUTHOR/S: Cloud for Sovereignty
*/
param parLocation string = resourceGroup().location
param parTenantId string = subscription().tenantId

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = uniqueString(utcNow())

param parKeyVaultName string ='vault-${parTimestamp}'
param parKeyVaultKeyName string = 'cmkey'
param parKeyExpirationTime int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y'))
param parStorageAccountName string = 'storage${parTimestamp}'
param parUserAssignedIdentityName string = 'keyVaultOwner${parTimestamp}'

var varRoleAssignmentName = guid(resourceGroup().id, 'owner','compliance')

@description('Docs on supported role GUIDs can be found here https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles.')
var varOwnerRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

resource resUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: parUserAssignedIdentityName
  location: parLocation
}

resource resRoleAssignmentWithScope 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: varRoleAssignmentName
  properties: {
    roleDefinitionId: varOwnerRoleDefinitionId
    principalId: resUserAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource resKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: parKeyVaultName
  location: parLocation
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: true
    enablePurgeProtection: true
    enabledForDiskEncryption: true
    tenantId: parTenantId
    accessPolicies: [
      {
        tenantId: parTenantId
        permissions: {
          keys: [
            'create'
            'get'
            'list'
            'unwrapKey'
            'wrapKey'
          ]
        }
        objectId: resUserAssignedIdentity.properties.principalId
      }
    ]
  }
}

resource resKeyVaultKey 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  parent: resKeyVault
  name: parKeyVaultKeyName
  properties: {
    attributes: {
      enabled: true
      exp: parKeyExpirationTime
    }
    keySize: 4096
    kty: 'RSA'
  }
}

resource resStorageAccountWithCMK 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: parStorageAccountName
  location: parLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resUserAssignedIdentity.id}': {}
    }
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    encryption: {
      identity: {
        userAssignedIdentity: resUserAssignedIdentity.id
      }
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: resKeyVaultKey.name
        keyvaulturi: endsWith(resKeyVault.properties.vaultUri,'/') ? substring(resKeyVault.properties.vaultUri,0,length(resKeyVault.properties.vaultUri)-1) : resKeyVault.properties.vaultUri
      }
      requireInfrastructureEncryption: true
      services: {
        blob: {
          enabled: true
        }
      }
    }
    networkAcls: {
      defaultAction: 'Deny'
    }
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
  }
}
