// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
SUMMARY: Module to create the custom role definition.
DESCRIPTION: This module will create a deployment at the management group level which will create the custom role definition.
AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('Array of actions for the roleDefinition')
param actions array = []

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string

@description('Detailed description of the role definition')
param roleDescription string

var roleDefName = guid(managementGroup().id,roleName)

resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefName
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      managementGroup().id
    ]
  }
}

output outRoleDefinitionId string = roleDef.id
