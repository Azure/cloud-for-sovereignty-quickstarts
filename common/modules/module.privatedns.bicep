// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to create the private DNS.
DESCRIPTION: This module will create a deployment which will create the Private DNS zones and Link Attestation Provider DNS zone to hub network and ContosoHR network.
AUTHOR/S: Cloud for Sovereignty
*/
@description('Resource ID of the hub network in which the Private DNS zones will be deployed.')
param parHubNetworkId string

@description('Resource ID of the ContosoHR VNet from ContosoHR.Common, to which the Private DNS zones will be linked.')
param parSpokeNetworkId string

// Private DNS Zones for Attestation Provider and SQL Server services.
// See reference listing at https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
var varAttestationProviderZoneName = 'privatelink.attest.azure.net'
resource resAttestationPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: varAttestationProviderZoneName
  location: 'global'
}

var varSqlServerZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
resource resSqlServerPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: varSqlServerZoneName
  location: 'global'
}

// Link Attestation Provider DNS zone to hub network
resource resAttestationDnsZoneHubVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-${uniqueString(resAttestationPrivateDnsZone.id, parHubNetworkId)}'
  parent: resAttestationPrivateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: parHubNetworkId
    }
    registrationEnabled: false
  }
}

// Link Attestation Provider DNS zone to ContosoHR network
resource resAttestationDnsZoneSpokeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-${uniqueString(resAttestationPrivateDnsZone.id, parSpokeNetworkId)}'
  parent: resAttestationPrivateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: parSpokeNetworkId
    }
    registrationEnabled: false
  }
}

// Link SQL Server DNS zone to ContosoHR network
// Note that this DNS zone is NOT linked to the Hub network in this module
// -- because it is already set up and linked there by the installer by default
resource resSqlServerDnsZoneSpokeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-${uniqueString(resSqlServerPrivateDnsZone.id, parSpokeNetworkId)}'
  parent: resSqlServerPrivateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: parSpokeNetworkId
    }
    registrationEnabled: false
  }
}

output outAttestationDnsZoneId string = resAttestationPrivateDnsZone.id
output outSqlServerDnsZoneId string = resSqlServerPrivateDnsZone.id
