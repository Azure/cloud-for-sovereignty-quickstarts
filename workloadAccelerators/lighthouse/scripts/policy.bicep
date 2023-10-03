// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This is a file that deploys a policy definition and assignment to enforce Lighthouse on subscriptions.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('The management group id')
@minLength(2)
@maxLength(10)
param parManagementGroupId string

@description('Add the tenant id provided by the MSP')
param parManagedByTenantId string

@minLength(1)
@maxLength(20)
@description('Add the tenant name of the provided MSP')
param parManagedByName string

@description('Add the description of the offer provided by the MSP')
param parManagedByDescription string

@description('Add the authZ array provided by the MSP')
param parManagedByAuthorizations array

@allowed([
  'asia'
  'asiapacific'
  'australia'
  'australiacentral'
  'australiacentral2'
  'australiaeast'
  'australiasoutheast'
  'brazil'
  'brazilsouth'
  'brazilsoutheast'
  'canada'
  'canadacentral'
  'canadaeast'
  'centralindia'
  'centralus'
  'centraluseuap'
  'centralusstage'
  'eastasia'
  'eastasiastage'
  'eastus'
  'eastus2'
  'eastus2euap'
  'eastus2stage'
  'eastusstage'
  'eastusstg'
  'europe'
  'france'
  'francecentral'
  'francesouth'
  'germany'
  'germanynorth'
  'germanywestcentral'
  'global'
  'india'
  'japan'
  'japaneast'
  'japanwest'
  'jioindiacentral'
  'jioindiawest'
  'korea'
  'koreacentral'
  'koreasouth'
  'northcentralus'
  'northcentralusstage'
  'northeurope'
  'norway'
  'norwayeast'
  'norwaywest'
  'qatarcentral'
  'singapore'
  'southafrica'
  'southafricanorth'
  'southafricawest'
  'southcentralus'
  'southcentralusstage'
  'southcentralusstg'
  'southeastasia'
  'southeastasiastage'
  'southindia'
  'swedencentral'
  'switzerland'
  'switzerlandnorth'
  'switzerlandwest'
  'uae'
  'uaecentral'
  'uaenorth'
  'uk'
  'uksouth'
  'ukwest'
  'unitedstates'
  'unitedstateseuap'
  'westcentralus'
  'westeurope'
  'westindia'
  'westus'
  'westus2'
  'westus2stage'
  'westus3'
  'westusstage'
])
@description('Location')
param parLocation string

@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
])
@description('Policy Identity. Default:SystemAssigned')
param parPolicyIdentity string = 'SystemAssigned'

@description('Lighthouse Policy Assignment Name')
param policyAssignmentName string = take('${parManagedByName} LH', 24)

var varUniquePolicyDefintiion = uniqueString(parManagedByAuthorizations[0].principalId,parManagedByTenantId)
var varPolicyDefinitionName = take('${parManagedByName}-${varUniquePolicyDefintiion}',64)

@allowed([
  'Group'
  'ServicePrincipal'
])
@description('Principal Type. Default:ServicePrincipal')
param parPrinicpalType string = 'ServicePrincipal'

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = utcNow()

@description('Role Definition Ids')
var varRBACRoleDefinitionIDs = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  networkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  aksContributor: 'ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'
}

resource resPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: varPolicyDefinitionName
  properties: {
    description: 'Policy to enforce Lighthouse on subscriptions'
    displayName: 'Enforce Lighthouse for ${parManagedByName}'
    mode: 'All'
    policyType: 'Custom'
    parameters: {
      managedByTenantId: {
        type: 'string'
        defaultValue: parManagedByTenantId
        metadata: {
          description: 'Add the tenant id provided by the MSP'
        }
      }
      managedByName: {
        type: 'string'
        defaultValue: parManagedByName
        metadata: {
          description: 'Add the tenant name of the provided MSP'
        }
      }
      managedByDescription: {
        type: 'string'
        defaultValue: parManagedByDescription
        metadata: {
          description: 'Add the description of the offer provided by the MSP'
        }
      }
      managedByAuthorizations: {
        type: 'array'
        defaultValue: parManagedByAuthorizations
        metadata: {
          description: 'Add the authZ array provided by the MSP'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions'
          }
        ]
      }
      then: {
        effect: 'deployIfNotExists'
        details: {
          type: 'Microsoft.ManagedServices/registrationDefinitions'
          deploymentScope: 'Subscription'
          existenceScope: 'Subscription'
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/${varRBACRoleDefinitionIDs.owner}'
          ]
          existenceCondition: {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.ManagedServices/registrationDefinitions'
              }
              {
                field: 'Microsoft.ManagedServices/registrationDefinitions/managedByTenantId'
                equals: '[parameters(\'managedByTenantId\')]'
              }
            ]
          }
          deployment: {
            location: parLocation
            properties: {
              mode: 'incremental'
              parameters: {
                managedByTenantId: {
                  value: '[parameters(\'managedByTenantId\')]'
                }
                managedByName: {
                  value: '[parameters(\'managedByName\')]'
                }
                managedByDescription: {
                  value: '[parameters(\'managedByDescription\')]'
                }
                managedByAuthorizations: {
                  value: '[parameters(\'managedByAuthorizations\')]'
                }
              }
              template: {
                '$schema': 'https://schema.management.azure.com/2018-05-01/subscriptionDeploymentTemplate.json#'
                contentVersion: '1.0.0.0'
                parameters: {
                  managedByTenantId: {
                    type: 'string'
                  }
                  managedByName: {
                    type: 'string'
                  }
                  managedByDescription: {
                    type: 'string'
                  }
                  managedByAuthorizations: {
                    type: 'array'
                  }
                }
                variables: {
                  managedByRegistrationName: '[guid(parameters(\'managedByName\'))]'
                  managedByAssignmentName: '[guid(parameters(\'managedByName\'))]'
                }
                resources: [
                  {
                    type: 'Microsoft.ManagedServices/registrationDefinitions'
                    apiVersion: '2019-06-01'
                    name: '[variables(\'managedByRegistrationName\')]'
                    properties: {
                      registrationDefinitionName: '[parameters(\'managedByName\')]'
                      description: '[parameters(\'managedByDescription\')]'
                      managedByTenantId: '[parameters(\'managedByTenantId\')]'
                      authorizations: '[parameters(\'managedByAuthorizations\')]'
                    }
                  }
                  {
                    type: 'Microsoft.ManagedServices/registrationAssignments'
                    apiVersion: '2019-06-01'
                    name: '[variables(\'managedByAssignmentName\')]'
                    dependsOn: [
                      '[resourceId(\'Microsoft.ManagedServices/registrationDefinitions/\', variables(\'managedByRegistrationName\'))]'
                    ]
                    properties: {
                      registrationDefinitionId: '[resourceId(\'Microsoft.ManagedServices/registrationDefinitions/\',variables(\'managedByRegistrationName\'))]'
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  }
}


//Policy Assignment
resource resPolicyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyAssignmentName
  properties: {
      policyDefinitionId: resPolicyDefinition.id
      displayName:'Enforce Lighthouse for ${parManagedByName}'
  }
  identity: {
      type: parPolicyIdentity
    }
  location:parLocation
}

module modRoleAssignment '../../../common/roleAssignments/roleAssignmentManagementGroup.bicep' = {
  name: take('${parManagementGroupId}-deploy-Role-Assignment-${parTimestamp}', 64)
  scope: managementGroup(parManagementGroupId)
  params: {
    parAssigneeObjectId: resPolicyAssignment.identity.principalId
    parAssigneePrincipalType: parPrinicpalType
    parRoleDefinitionId: varRBACRoleDefinitionIDs.owner
    parTelemetryOptOut: true
  }
}

output outPolicyAssignmentId string = resPolicyAssignment.id
output outPolicyDefinitionId string = resPolicyDefinition.id
