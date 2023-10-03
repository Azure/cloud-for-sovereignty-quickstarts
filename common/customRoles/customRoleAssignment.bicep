// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to create the custom role assignment.
DESCRIPTION: This module will create a deployment at the management group level which will create the custom role assignment.
AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('Role Definition Id')
param parRoleDefinitionId string

@description('Principal Id of resource for role assignment')
param parPrincipalId string

@description('Service principal type')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param parPrincipalType string

@description('A GUID representing the role assignment name. Default: guid(managementGroup().name, parRoleDefinitionId, parPrincipalId)')
var roleAssignmentName = guid(managementGroup().name, parRoleDefinitionId, parPrincipalId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: managementGroup()
  name: roleAssignmentName
  properties: {
    roleDefinitionId: parRoleDefinitionId
    principalId: parPrincipalId
    principalType:parPrincipalType
     }
  }
