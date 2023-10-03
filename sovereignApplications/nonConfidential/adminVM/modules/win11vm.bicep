// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to deploy the admin virtual machine.
DESCRIPTION: This module will create a deployment which will create the admin virtual machine to execute the scripts.
AUTHOR/S: Cloud for Sovereignty
*/

// Location + connectivity
param parDeploymentLocation string
param parSubnetId string

// VM user
@maxLength(20)
param parAdminUsername string = 'slzadmin'
@secure()
param parAdminPassword string

// Default VM hw parameters
@maxLength(15)
param parVmName string = 'admin-vm'
param parVmSize string = 'Standard_D2s_v3'
param parDiskType string = 'Standard_LRS'

// OS choice
var varOsImagePublisher = 'MicrosoftWindowsDesktop'
var varOsImageOffer = 'windows-11'
var varOsImageSku = 'win11-22h2-pro'

resource resNic 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: '${parVmName}-nic'
  location: parDeploymentLocation
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: parSubnetId
          }
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource resVm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: parVmName
  location: parDeploymentLocation
  properties: {
    osProfile: {
      computerName: parVmName
      adminUsername: parAdminUsername
      adminPassword: parAdminPassword
      allowExtensionOperations: true
      windowsConfiguration: {
        patchSettings: {
          assessmentMode: 'ImageDefault'
          patchMode: 'AutomaticByOS'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: true
      }
    }
    hardwareProfile: {
      vmSize: parVmSize
    }
    storageProfile: {
      imageReference: {
        publisher: varOsImagePublisher
        offer: varOsImageOffer
        sku: varOsImageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: parDiskType
        }
        deleteOption: 'Delete'
        diskSizeGB: 127
      }
      dataDisks: []
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resNic.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
  }
}

resource resVmCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: '${parVmName}-SoftwareInstaller'
  location: parDeploymentLocation
  parent: resVm
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://hrwebapp.blob.${environment().suffixes.storage}/contosohr/adminVmSoftwareInstaller.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File adminVmSoftwareInstaller.ps1'
    }
  }
}

output outVmName string = resVm.name
output outVmResourceId string = resVm.id
