// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the confidential virtual machine bicep script.
DESCRIPTION: This module will create a deployment which will create the confidential virtual machine.
AUTHOR/S: Cloud for Sovereignty
*/
@description('Location for all resources.')
param parDeploymentLocation string

@description('List of tags to be applied to resources.')
param parTags object

@description('Key vault name')
param parKeyVaultName string

@description('Virtual network that the Confidential VM connects to.')
param parVirtualNetworkName string

@description('The name of the Confidential VM (resource and host name).')
param parVmName string

@description('Is the AMD Confidential VM.')
param parIsAMDVM bool = true

@description('The size of the virtual machine')
@allowed([
  'Standard_DC2s_v2'
  'Standard_DC2as_v5'
  'Standard_DC4as_v5'
])
param parVmSize string = 'Standard_DC2as_v5'

@description('OS image for the virtual Machine')
@allowed([
  'Windows Server 2022 Gen 2'
  'Windows Server 2019 Gen 2'
  'Ubuntu 22.04 LTS Gen 2'
  'Ubuntu 20.04 LTS Gen 2'
])
param parOsImageName string

@description('OS disk type of the VM.')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
])
param parOsDiskType string = 'StandardSSD_LRS'

@description('Username for the virtual machine.')
param parAdminUsername string

@description('Password for the virtual machine. The password must be at least 12 characters long and have lower case, upper characters, digit and a special character (Regex match)')
@secure()
param parAdminPasswordOrKey string

@description('Type of authentication to use on the virtual machine. SSH Public key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param parAuthenticationType string

@description('Boolean value indicating whether the VM supports secured boot, e.g., true.')
param parSecureBoot bool = true

@description('Boolean value indicating whether the VM is using virtualized version of a hardware Trusted Platform Module,e.g., true.')
param parVTPM bool = true

@description('Disk Encryption Set Id.')
param parDiskEncryptionSetId string

@description('Virtual Machine Key Id')
param parVmkeyId string

@description('Virtual machine Properties/userData block. Carries a string that the VM can access thorugh the IMDS service, see https://learn.microsoft.com/en-us/azure/virtual-machines/user-data.')
param parVmUserData string

@description('Attestation Provider URI to attest to.')
param parAttestationUri string

@description('Attestation providers name')
param parAttestationProvidersName string

var parDiskName = '${parVmName}-osDisk'
var varDataDiskName = '${parVmName}-dataDisk'
var varImageList = {
  'Windows Server 2022 Gen 2': {
    publisher: 'microsoftwindowsserver'
    offer: 'windowsserver'
    sku: '2022-datacenter-smalldisk-g2'
    version: 'latest'
  }
  'Windows Server 2019 Gen 2': {
    publisher: 'microsoftwindowsserver'
    offer: 'windowsserver'
    sku: '2019-datacenter-smalldisk-g2'
    version: 'latest'
  }
  'Ubuntu 22.04 LTS Gen 2': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-confidential-vm-jammy'
    sku: '22_04-lts-cvm'
    version: 'latest'
  }
  'Ubuntu 20.04 LTS Gen 2': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-confidential-vm-focal'
    sku: '20_04-lts-cvm'
    version: 'latest'
  }
}
var varImageReference = varImageList[parOsImageName]
var varAscReportingEndpoint = resAttestationProvider.properties.attestUri
var varDisableAlerts = 'false'
var varExtensionName = 'GuestAttestation'
var varExtensionPublisher = varIsWindows ? 'Microsoft.Azure.Security.WindowsAttestation' : 'Microsoft.Azure.Security.LinuxAttestation'
var varExtensionVersion = '1.0'
var varMaaTenantName = 'GuestAttestation'
var varUseAlternateToken = 'false'
var varIsWindows = contains(parOsImageName, 'Windows')
var varLinuxConfiguration = {
  disablePasswordAuthentication: 'true'
  ssh: {
    publicKeys: [
      {
        keyData: parAdminPasswordOrKey
        path: '/home/${parAdminUsername}/.ssh/authorized_keys'
      }
    ]
  }
}
var varWindowsConfiguration = {
  enableAutomaticUpdates: 'true'
  provisionVmAgent: 'true'
}

var varEncryptionOperation = 'EnableEncryption'
var varKeyEncryptionAlgorithm = 'RSA-OAEP'
var varKeyVaultResourceID = resourceId(resourceGroup().name, 'Microsoft.KeyVault/vaults/', parKeyVaultName)

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

// Virtual network and subnet from common module
resource resVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: parVirtualNetworkName
}

// Virtual machine
resource resVm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: parVmName
  location: parDeploymentLocation
  tags: parTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    userData: base64(parVmUserData)
    hardwareProfile: {
      vmSize: parVmSize
    }
    osProfile: {
      computerName: length(parVmName) <= 15 ? parVmName : replace(take(parVmName,15),'-','') // If vm name is too long, reduce for compliance with Windows naming.
      adminUsername: parAdminUsername
      adminPassword: parAdminPasswordOrKey
      linuxConfiguration: ((parAuthenticationType == 'password') ? null : varLinuxConfiguration)
      windowsConfiguration: (varIsWindows ? varWindowsConfiguration : null)
    }
    storageProfile: {
      osDisk: {
        name: parDiskName
        createOption: 'FromImage'
        managedDisk: {
          securityProfile: {
            securityEncryptionType: 'VMGuestStateOnly'
          }
          storageAccountType: parOsDiskType
          diskEncryptionSet: {
            id: parDiskEncryptionSetId
          }
        }
      }
      dataDisks: [
        {
          name: varDataDiskName
          diskSizeGB: 128
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
            diskEncryptionSet: {
              id: parDiskEncryptionSetId
            }
          }
        }
      ]
      imageReference: varImageReference
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resNIC.id
        }
      ]
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: parSecureBoot
        vTpmEnabled: parVTPM
      }
      securityType: 'ConfidentialVM'
    }
  }
}

// Assign the Confidential VM service principal full rights on key vault. Could probably be tightened.
resource resKeyVaultAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resKeyVault.id, parVmName, resKeyVaultAdministratorRoleDefinition.id)
  scope: resKeyVault
  properties: {
    principalId: resVm.identity.principalId
    roleDefinitionId: resKeyVaultAdministratorRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Assign the Confidential VM service principal reader rights on attestation provider.
resource resAttestationProviderAttestationReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resKeyVault.id, parVmName, resAttestationProviderAttestationReaderRoleDefinition.id)
  scope: resAttestationProvider
  properties: {
    principalId: resVm.identity.principalId
    roleDefinitionId: resAttestationProviderAttestationReaderRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// VM NIC
resource resNIC 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: 'nic-${parVmName}'
  location: parDeploymentLocation
  tags: parTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resVnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource vmName_extension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = if (parVTPM && parSecureBoot && parIsAMDVM == false) {
  parent: resVm
  name: varExtensionName
  location: parDeploymentLocation
  tags: parTags
  properties: {
    publisher: varExtensionPublisher
    type: varExtensionName
    typeHandlerVersion: varExtensionVersion
    autoUpgradeMinorVersion: true
    forceUpdateTag: '1.0'
    settings: {
      maaEndpoint: parAttestationUri
      maaTenantName: varMaaTenantName
      ascReportingEndpoint: varAscReportingEndpoint
      useAlternateToken: varUseAlternateToken
      disableAlerts: varDisableAlerts
      EncryptionOperation: varEncryptionOperation
      KeyVaultURL: reference(varKeyVaultResourceID, '2022-07-01').vaultUri
      KeyVaultResourceId: varKeyVaultResourceID
      KeyEncryptionKeyURL: reference(parVmkeyId, '2022-07-01', 'Full').properties.keyUriWithVersion
      KekVaultResourceId: varKeyVaultResourceID
      KeyEncryptionAlgorithm: varKeyEncryptionAlgorithm
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
}

output outVmName string = resVm.name
output outVmServicePrincipalObjectId string = resVm.identity.principalId
