// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the HR App workload bicep scripts.
DESCRIPTION: This module will create a deployment which will create HR App workload with its azure infrastructures.
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

@description('User Principal Name of the user user executing this deployment (used to set SQL server admin account).')
param parDeployingUserUpn string

@maxLength(10)
@description('The Azure Confidential Ledger Name, e.g., prefix-acl. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes. Note also that due to name length restrictions on ledger resources (24 characters) and due to said suffix that is added, this parameter has a maxlength restriction of 10 characters.')
param parLedgerName string = '${parDeploymentPrefix}-acl'

@maxLength(10)
@description('The Attestation Provider name, e.g., prefixattp. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes.')
param parAttestationProvidersName string = '${parDeploymentPrefix}attp'

@description('Name of Key Vault holding keys for SQL Server encryption, Always Encrypted, and disk encryption of VM disks, e.g., myprefix-kv. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes.')
param parKeyVaultName string = '${parDeploymentPrefix}-kv'

@description('Name of the User Assigned Managed Identity used in some RBAC scenarios (e.g., for the Disk Encryption Set).')
param parManagedIdentityName string = '${parDeploymentPrefix}-id'

@description('Key expiry date in seconds since 1970-01-01T00:00:00Z.  Defaults to December 31, 2024.')
param parKeyExpirationDate int = dateTimeToEpoch('20241231T235959Z')

@description('Resource ID of the SLZ\'s hub vnet in the <slzprefix>-connectivity subscription.')
param parHubNetworkResourceId string

@description('IP address space of the VNET created for this workload, in  CIDR notation.')
param parVnetAddressPrefix string

@description('Name of the Confidential Virtual Machine to be created, e.g., myprefix-vm. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes.')
param parVmName string = '${parDeploymentPrefix}-vm'

@description('OS image for the virtual Machine')
param parOsImageName string = 'Ubuntu 22.04 LTS Gen 2'

@description('The administrator username of the SQL logical server')
param parSqlAdministratorLogin string = 'hrapp-admin'

@description('The administrator password of the SQL logical server.')
@secure()
param parSqlAdministratorLoginPassword string

@description('Username for the virtual machine.')
param parAdminUsername string = 'hrapp-admin'

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
param parTags object = { product: 'hrapp' }

@description('The SQL Server name, e.g., myprefix-sql. Note that deployed resource will have a unique name suffix appended to prevent namespace clashes.')
param parSqlServerName string = '${parDeploymentPrefix}-sql'

@description('The SQL Database name.')
param parSqlDatabaseName string = '${parDeploymentPrefix}-db'

@description('Value that populates CVM OSProfile/customData field (e.g., a cloud-init configuration).')
param parVmCustomData string = loadFileAsBase64('../../contosoHR/config/cloud-init.yaml')

@description('Suffix used to add unique identity to globally namespaced resources.')
var varUniqueSuffix = uniqueString(resResourceGroup.id, parDeploymentLocation)

@description('Key vault name with unique suffix.')
var varUniqueKeyVaultName = '${parKeyVaultName}-${varUniqueSuffix}'

@description('SQL Server name with unique suffix.')
var varUniqueSqlServerName = '${parSqlServerName}-${varUniqueSuffix}'

@description('Virtual Machine name with unique suffix.')
var varUniqueVmName = '${parVmName}-${varUniqueSuffix}'

@description('Confidential Ledger name with unique suffix.')
var varUniqueLedgerName = '${parLedgerName}-${varUniqueSuffix}'

@description('Attestation Provider name with unique suffix.')
var varUniqueAttestationProviderName = '${parAttestationProvidersName}${varUniqueSuffix}'

@description('The database connection string (without authentication details, since we are using service principals for RBAC) that the VM will use to query the SQL server.')
var varVmUserData = '{ "ContosoHRDatabase":"Data Source = ${varUniqueSqlServerName}${environment().suffixes.sqlServerHostname}; Initial Catalog = ${parSqlDatabaseName}; Column Encryption Setting = Enabled;Attestation Protocol = AAS; Enclave Attestation Url = https://sharedwus.wus.attest.azure.net/attest/SgxEnclave; Authentication=Active Directory Managed Identity;","ConfidentialLedgerName": "${varUniqueLedgerName}" }'

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: parDeploymentLocation
  name: parResourceGroupName
  tags: parTags
}

module modManagedIdentity '../../../../common/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'App-Managed-Identity-${parTimestamp}'
  scope: resResourceGroup
  params: {
    parLocation: parDeploymentLocation
    parName: parManagedIdentityName
    parTags: parTags
  }
}

module modCommonInfra './hrAppInfra.bicep' = {
  name: 'App-Workload-Common-${parTimestamp}'
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
    parSubnetAddressPrefix: parVnetAddressPrefix
    parHubNetworkResourceId: parHubNetworkResourceId
    parTimestamp: parTimestamp
    parKeyVaultOrMhsmAdminObjectId: parDeployingUserObjectId
    parAttestationContributorObjectId: parDeployingUserObjectId
    parKeyExpirationDate: parKeyExpirationDate
  }
}

module modSqlServer '../../sqlServer/template.sqlserver.bicep' = {
  name: 'App-Workload-SqlServer-${parTimestamp}'
  scope: resResourceGroup
  params: {
    parTags: parTags
    parKeyVaultName: varUniqueKeyVaultName
    parSqlAdministratorLogin: parSqlAdministratorLogin
    parSqlAdministratorLoginPassword: parSqlAdministratorLoginPassword
    parDeploymentLocation: parDeploymentLocation
    parVirtualNetworkName: parVirtualNetworkName
    parSqlServerName: varUniqueSqlServerName
    parDatabaseName: parSqlDatabaseName
    parSqlKeyName: modCommonInfra.outputs.outSqlkeyName
    parSqlKeyUri: modCommonInfra.outputs.outSqlkeyUrl
    parAttestationProvidersName: varUniqueAttestationProviderName
    parSqlServerDnsZoneId: modCommonInfra.outputs.outSqlServerDnsZoneId
    parAzureAdAdminObjectId: parDeployingUserObjectId
    parAzureAdAdminUpn: parDeployingUserUpn
    parManagedIdentityName: parManagedIdentityName
  }
  dependsOn: [modCommonInfra]
}

module modIntelVM '../../virtualMachines/template.confidentialvm.bicep' = {
  name: 'App-Workload-CVM-${parTimestamp}'
  scope: resResourceGroup
  params: {
    parTags: parTags
    parKeyVaultName: varUniqueKeyVaultName
    parDiskEncryptionSetId: modCommonInfra.outputs.outDiskEncryptionSetId
    parVmkeyId: modCommonInfra.outputs.outVmkeyId
    parVmName: varUniqueVmName
    parOsImageName: parOsImageName
    parAdminUsername: parAdminUsername
    parAdminPasswordOrKey: parAdminPasswordOrKey
    parAuthenticationType: parAuthenticationType
    parDeploymentLocation: parDeploymentLocation
    parAttestationUri: modCommonInfra.outputs.outAttestationProviderAttestUri
    parAttestationProvidersName: varUniqueAttestationProviderName
    parVirtualNetworkName: parVirtualNetworkName
    parVmCustomData: parVmCustomData
    parVmUserData: varVmUserData
  }
  dependsOn: [modCommonInfra]
}

module modConfidentialLedger '../../azureConfidentialLedger/template.acl.bicep' = {
	scope: resResourceGroup
	name: 'App-Workload-ConfidentialLedger-${parTimestamp}'
	params: {
        parDeploymentLocation: parDeploymentLocation
	    parAdministratorUserObjectIds: [parDeployingUserObjectId, modIntelVM.outputs.outVmServicePrincipalObjectId]
	    parLedgerName: varUniqueLedgerName
	    parTags: parTags
	}
}

output outResourceGroupName string = resResourceGroup.name
output outAttestationProviderName string = modCommonInfra.outputs.outAttestationProviderName
output outSqlServerName string = modSqlServer.outputs.outSqlServerName
output outSqlDatabaseName string = modSqlServer.outputs.outSqlDatabaseName
output outVmName string = modIntelVM.outputs.outVmName
output outCmkUrl string = modCommonInfra.outputs.outSqlCmkUrl
output outSqlAdministratorLogin string = parSqlAdministratorLogin
