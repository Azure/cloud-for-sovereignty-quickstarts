// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the Azure SQL Server and employee database.
DESCRIPTION: This module will create a deployment which will create the Azure SQL Server and employee database.
AUTHOR/S: Cloud for Sovereignty
*/
@description('Location for all resources.')
param parDeploymentLocation string

@description('List of tags to be applied to resources.')
param parTags object

@description('Name of the User Assigned Managed Identity used in some RBAC scenarios (e.g., for the Disk Encryption Set).')
param parManagedIdentityName string

@description('Key vault name')
param parKeyVaultName string

@description('Name of the virtual network')
param parVirtualNetworkName string

@description('The Private DNS zone that the Private Endpoint for this SQL Server will link to.')
param parSqlServerDnsZoneId string

@description('The administrator username of the SQL logical server')
param parSqlAdministratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param parSqlAdministratorLoginPassword string

@description('User Principal Name of the Azure AD user that will be set as admin for this SQL Server.')
param parAzureAdAdminUpn string

@description('Object ID of the Azure AD user that will be set as admin for this SQL Server.')
param parAzureAdAdminObjectId string

@description('Sql Server Name ')
param parSqlServerName string

@description('Database Name')
param parDatabaseName string

@description('Sql Key Name')
param parSqlKeyName string

@description('Sql Key Uri')
param parSqlKeyUri string

@description('Attestation providers name')
param parAttestationProvidersName string

var varSubnetName = 'subnet'
var varSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', parVirtualNetworkName, varSubnetName)
var varSqlServerKeyName = '${parKeyVaultName}_${parSqlKeyName}_${substring(parSqlKeyUri, lastIndexOf(parSqlKeyUri, '/')+1)}'
var varSqlServerPrivateEndpointName = 'endpoint-${parSqlServerName}'

// Existing resources stood up by common module or provided by Azure
resource resKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: parKeyVaultName
}
resource resAttestationProvider 'Microsoft.Attestation/attestationProviders@2021-06-01-preview' existing = {
  name: parAttestationProvidersName
}

// The built-in Key Vault Administrator role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-administrator
resource resKeyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

// The built-in Attestation Reader role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#attestation-reader
resource resAttestationProviderAttestationReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'fd1bd22b-8476-40bc-a0bc-69b95687b9f3'
}

resource resManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: parManagedIdentityName
}

resource resSqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: parSqlServerName
  location: parDeploymentLocation
  tags: parTags
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${resManagedIdentity.id}': {
      }
    }
  }
  properties: {
    keyId: parSqlKeyUri
    administratorLogin: parSqlAdministratorLogin
    administratorLoginPassword: parSqlAdministratorLoginPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      login: parAzureAdAdminUpn
      sid: parAzureAdAdminObjectId
      principalType: 'User'
      tenantId: tenant().tenantId
    }
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    primaryUserAssignedIdentityId: resManagedIdentity.id
  }
}

// Assign the SQL Server service principal full rights on key vault. Could probably be tightened.
resource resSqlServerKeyVaultAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resKeyVault.id, parSqlServerName, resKeyVaultAdministratorRoleDefinition.id)
  scope: resKeyVault
  properties: {
    principalId: resSqlServer.identity.principalId
    roleDefinitionId: resKeyVaultAdministratorRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Assign the SQL Server service principal reader rights on attestation provider.
resource resSqlServerAttestationProviderAttestationReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resKeyVault.id, parSqlServerName, resAttestationProviderAttestationReaderRoleDefinition.id)
  scope: resAttestationProvider
  properties: {
    principalId: resSqlServer.identity.principalId
    roleDefinitionId: resAttestationProviderAttestationReaderRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

resource resSqlServerNameDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: resSqlServer
  name: parDatabaseName
  location: parDeploymentLocation
  tags: parTags
  sku: {
    name: 'GP_DC_2'
    tier: 'GeneralPurpose'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    sampleName: 'AdventureWorksLT'
    zoneRedundant: false
    licenseType: 'LicenseIncluded'
    readScale: 'Disabled'
    highAvailabilityReplicaCount: 0
    isLedgerOn: false
  }
}

resource resSqlServerKey 'Microsoft.Sql/servers/keys@2021-11-01' = {
  parent: resSqlServer
  name: varSqlServerKeyName
  properties: {
    serverKeyType: 'AzureKeyVault'
    uri: parSqlKeyUri
  }
}

resource resDevOpsAuditingSettingsSqlServerNameDefault 'Microsoft.Sql/servers/devOpsAuditingSettings@2021-11-01' = {
  parent: resSqlServer
  name: 'default'
  properties: {
    isAzureMonitorTargetEnabled: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource resSqlServerNameDatabaseDefault 'Microsoft.Sql/servers/databases/advancedThreatProtectionSettings@2022-05-01-preview' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    state: 'Disabled'
  }
}

resource resAuditingPoliciesSqlServerNameDatabaseDefault 'Microsoft.Sql/servers/databases/auditingPolicies@2014-04-01' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    auditingState: 'Disabled'
  }
}

resource resAuditingSettingsSqlServerNameDatabaseDefault 'Microsoft.Sql/servers/databases/auditingSettings@2022-05-01-preview' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    retentionDays: 0
    auditActionsAndGroups: []
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: false
    isManagedIdentityInUse: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource resBackupLongTermRetentionPoliciesSqlServerNameDatabaseDefault 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2022-05-01-preview' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    weeklyRetention: 'PT0S'
    monthlyRetention: 'PT0S'
    yearlyRetention: 'PT0S'
    weekOfYear: 1
  }
}

resource resBackupShortTermRetentionPoliciesSqlServerNameDatabaseDefault 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2022-05-01-preview' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    retentionDays: 7
    diffBackupIntervalInHours: 12
  }
}

resource resExtendedAuditingSettingsSqlServerNameDatabaseDefault 'Microsoft.Sql/servers/databases/extendedAuditingSettings@2022-05-01-preview' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    retentionDays: 0
    auditActionsAndGroups: []
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: false
    isManagedIdentityInUse: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource resVulnerabilityAssessmentsSqlServerNameDatabaseDefault 'Microsoft.Sql/servers/databases/vulnerabilityAssessments@2022-05-01-preview' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    recurringScans: {
      isEnabled: false
      emailSubscriptionAdmins: true
      emails: []
    }
  }
}

resource resSqlServerNameCurrent 'Microsoft.Sql/servers/encryptionProtector@2022-05-01-preview' = {
  parent: resSqlServer
  name: 'current'
  properties: {
    autoRotationEnabled: true
    serverKeyName: varSqlServerKeyName
    serverKeyType: 'AzureKeyVault'
  }
  dependsOn: [
    resSqlServerKey
  ]
}

resource resExtendedAuditingSettingsSqlServerNameDefault 'Microsoft.Sql/servers/extendedAuditingSettings@2021-11-01' = {
  parent: resSqlServer
  name: 'default'
  properties: {
    retentionDays: 0
    auditActionsAndGroups: []
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: false
    isManagedIdentityInUse: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource resGeoBackupPoliciesSqlServerNameDatabaseNameDefault 'Microsoft.Sql/servers/databases/geoBackupPolicies@2021-11-01' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    state: 'Enabled'
  }
}

resource resSecurityAlertPoliciesSqlServerNameDatabaseNameDefault 'Microsoft.Sql/servers/databases/securityAlertPolicies@2021-11-01' = {
  parent: resSqlServerNameDatabase
  name: 'default'
  properties: {
    state: 'Disabled'
    disabledAlerts: [
      ''
    ]
    emailAddresses: [
      ''
    ]
    emailAccountAdmins: false
    retentionDays: 0
  }
}

resource resSqlServerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: varSqlServerPrivateEndpointName
  location: parDeploymentLocation
  tags: parTags
  properties: {
    subnet: {
      id: varSubnetRef
    }
    customNetworkInterfaceName: 'nic-${varSqlServerPrivateEndpointName}'
    privateLinkServiceConnections: [
      {
        name: varSqlServerPrivateEndpointName
        properties: {
          privateLinkServiceId: resSqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Register Private Endpoint with Private DNS zone to allow DNS resolution on SLZ VNets
resource resSqlServerPrivateEndpointZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = {
  name: 'default'
  parent: resSqlServerPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-database-windows-net'
        properties: {
          privateDnsZoneId: parSqlServerDnsZoneId
        }
      }
    ]
  }
}

output outSqlServerName string = resSqlServer.name
output outSqlDatabaseName string = resSqlServerNameDatabase.name
