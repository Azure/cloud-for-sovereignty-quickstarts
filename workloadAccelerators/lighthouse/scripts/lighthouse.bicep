// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This Bicep file deploys a Logic App that will be used to register the Lighthouse Managed Services Provider (MSP) offer in a tenant.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('The tenant ID for Lighthouse.')
param parLighthouseManagementTenantId string

@description('The management group id')
@minLength(2)
@maxLength(10)
param parManagementGroupId string

@minLength(1)
@maxLength(20)
@description('The Lighthouse MSP offer name.')
param parLighthouseOfferName string

@description('The Lighthouse MSP offer description.')
param parLighthouseOfferDescription string

@description('The principal ID for authorizations.')
param parPrincipalId string

@description('The principal ID display name for authorizations.')
param parPrincipalIdDisplayName string

@description('Timestamp with format yyyyMMddTHHmmssZ. Default value set to Execution Timestamp to avoid deployment contention.')
param parTimestamp string = utcNow()

@description('Subscription where logic app will be deployed')
param parDeploymentSubscriptionId string

@description('Name of Logic App')
param parLogicAppName string

@description('Role that will be assigned to service provider ')
param parRoleDefinitionId string

@description('Name of the User Assigned Managed Identity used in some RBAC scenarios (e.g., for the Disk Encryption Set).')
param parManagedIdentityName string = '${parManagementGroupId}-Lighthouse-id'

@description('Deployment location')
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
param parLocation string

@description('Name of resource group')
var varResourceGroupName = '${parManagementGroupId}-rg-lighthouse-${parLocation}'

// module to create lighthouse resource group
module modLighthouseResourceGroup '../../../common/resourceGroup/resourceGroup.bicep' = {
  name: take('${parManagementGroupId}-Lighthouse-rg-${parLocation}-${parTimestamp}', 64)
  scope: subscription(parDeploymentSubscriptionId)
  params: {
    parLocation: parLocation
    parResourceGroupName: varResourceGroupName
    parTelemetryOptOut: true
  }
}

//create managed identity
module modManagedIdentity '../../../common/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'LogicApp-Managed-Identity-${parTimestamp}'
  scope: resourceGroup(parDeploymentSubscriptionId,varResourceGroupName)
  dependsOn:[
    modLighthouseResourceGroup
  ]
  params: {
    parLocation: parLocation
    parName: parManagedIdentityName
  }
}

//Create Logic app in lighthouse resource group
module modLighthouseLogicApp 'logicApp.bicep' = {
  scope:resourceGroup(parDeploymentSubscriptionId,varResourceGroupName)
  dependsOn:[
    modLighthouseResourceGroup
  ]
  name: take('${parManagementGroupId}-LogicApp-${parLocation}-${parTimestamp}', 64)
  params:{
    parLogicAppName:parLogicAppName
    parLocation:parLocation
    parManagedIdentityId: modManagedIdentity.outputs.outResourceId
    parManagedIdentityName: parManagedIdentityName
  }
}

// Module - deploy logicapp role definition
module modLogicAppRoleDefinition '../../../common/customRoles/customRoleDefinition.bicep' = {
  scope: managementGroup(parManagementGroupId)
  name: take('${parManagementGroupId}-LogicApp-RoleDefintion-${parLocation}-${parTimestamp}', 64)
  params:{
    roleName:'${parManagementGroupId} RP Register Role ${parLocation}'
    actions:[
      'Microsoft.ManagedServices/register/action'
    ]
    roleDescription:'To register managed services resource provider'

  }
}

// Module - deploy logicapp role assignment
module modRoleAssignmentManagementGroup '../../../common/customRoles/customRoleAssignment.bicep' = {
  name: take('${parManagementGroupId}-deploy-Lighthouse-Role-Assignment-${parTimestamp}', 64)
  scope: managementGroup(parManagementGroupId)
  params: {
    parRoleDefinitionId: modLogicAppRoleDefinition.outputs.outRoleDefinitionId
    parPrincipalId:modManagedIdentity.outputs.outPrincipalId
    parPrincipalType: 'ServicePrincipal'
  }
  dependsOn:[
    modLogicAppRoleDefinition
    modLighthouseLogicApp
  ]
}

// Module - create lighthouse custom policy definition and assignment
module modLighthousePolicy 'policy.bicep' = {
  scope: managementGroup(parManagementGroupId)
  name: take('${parManagementGroupId}-Lighthouse-policy-${parLocation}-${parTimestamp}', 64)
  params: {
    parManagementGroupId:parManagementGroupId
    parManagedByName:parLighthouseOfferName
    parManagedByDescription:parLighthouseOfferDescription
    parManagedByTenantId:parLighthouseManagementTenantId
    parManagedByAuthorizations:[
      {
        principalId: parPrincipalId
        principalIdDisplayName: parPrincipalIdDisplayName
        roleDefinitionId: parRoleDefinitionId

      }
    ]
    parLocation:parLocation
  }
}

output outPolicyDefinitionId string = modLighthousePolicy.outputs.outPolicyDefinitionId
output outPolicyAssignmentId string = modLighthousePolicy.outputs.outPolicyAssignmentId
output outLogicAppIdentityId string = modManagedIdentity.outputs.outPrincipalId
output outLighthouseResourceGroupId string = modLighthouseResourceGroup.outputs.outResourceGroupId
