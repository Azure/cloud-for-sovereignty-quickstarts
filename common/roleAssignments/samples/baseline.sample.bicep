// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Baseline deployment sample
DESCRIPTION: Sample Assigns owner-role (8e3af657-a8ff-443c-a75c-2fe8c4bcb635) to a principal with the ID 00000000-0000-0000-0000-000000000000.
The principal ID needs to be changed ot a principal that exists in the target tenant.
Use this sample to deploy the minimum resource configuration.
AUTHOR/S: Cloud for Sovereignty
*/

targetScope = 'managementGroup'

// ----------
// PARAMETERS
// ----------
var roleDefinitionId = '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var assigneeObjectId = '00000000-0000-0000-0000-000000000000'
// ---------
// RESOURCES
// ---------

@description('Baseline resource configuration.')
module baseline_ra '../roleAssignmentManagementGroup.bicep' = {
  name: 'baseline_ra'
  params: {
    parRoleDefinitionId: roleDefinitionId
    parAssigneePrincipalType: 'Group'
    parAssigneeObjectId: assigneeObjectId
    parTelemetryOptOut: true
    parRoleAssignmentNameGuid: guid(managementGroup().name, roleDefinitionId, assigneeObjectId)
  }
}
