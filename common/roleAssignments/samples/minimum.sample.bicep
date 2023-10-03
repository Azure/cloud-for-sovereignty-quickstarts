// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Minimum deployment sample
DESCRIPTION: Sample Assigns reader-role (acdd72a7-3385-48ef-bd42-f606fba81ae7) to a principal with the ID 00000000-0000-0000-0000-000000000000.
The principal ID needs to be changed ot a principal that exists in the target tenant.
Use this sample to deploy the minimum resource configuration.
AUTHOR/S: Cloud for Sovereignty
*/

targetScope = 'managementGroup'

// ----------
// PARAMETERS
// ----------


// ---------
// RESOURCES
// ---------

@description('Minimum resource configuration.')
module ra_mg'../roleAssignmentManagementGroup.bicep' = {
  name: 'ra_mg'
  params: {
    parRoleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    parAssigneePrincipalType: 'Group'
    parAssigneeObjectId: '00000000-0000-0000-0000-000000000000'
  }
}
