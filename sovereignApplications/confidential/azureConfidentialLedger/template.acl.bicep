// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to create the azure confidential ledger.
DESCRIPTION: This module will create a deployment which will create the azure confidential ledger.
AUTHOR/S: Cloud for Sovereignty
*/
@description('Azure Confidential Ledger Name')
@minLength(3)
@maxLength(24)
param parLedgerName string

@description('Resource tags')
param parTags object

@description('Set of Object IDs for Azure AD users who are set as admins on the Confidential Ledger.')
param parAdministratorUserObjectIds array

@description('Deployment location for all resources.')
param parDeploymentLocation string

resource resLedger 'Microsoft.ConfidentialLedger/ledgers@2022-05-13' = {
  name: parLedgerName
  location: parDeploymentLocation
  tags: parTags
  properties: {
    ledgerType: 'Public'
    aadBasedSecurityPrincipals: [for objectId in parAdministratorUserObjectIds: {
        principalId: objectId
        ledgerRoleName: 'Administrator'
      }]
  }
}
