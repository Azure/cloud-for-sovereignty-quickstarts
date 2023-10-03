// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: Logic App to register a resource provider in a subscription
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'resourceGroup'

@description('Name of logic app')
param parLogicAppName string

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
@description('Location for the logic app and its connectors')
param parLocation string

@allowed([
  'Month'
  'Week'
  'Day'
  'Hour'
  'Minute'
  'Second'
])
@description('frequency of recurrence. Default:Hour')
param parFrequency string = 'Hour'

@description('interval of recurrence. default:4')
param parInterval int = 4

@description('User assigned managed identity')
param parManagedIdentityId string

@description('User assigned managed identity name')
param parManagedIdentityName string

resource resLogicapp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: parLogicAppName
  location: parLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities:{
      '${parManagedIdentityId}':{
      }
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: parFrequency
            interval: parInterval
          }
          type: 'Recurrence'
        }
      }
      actions: {
        List_subscriptions: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'GetSubscriptions\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/subscriptions'
            queries: {
              'x-ms-api-version': '2016-06-01'
            }
          }
        }
        Subscription_Loop: {
          foreach: '@body(\'List_subscriptions\')?[\'value\']'
          actions: {
            Register_resource_provider: {
              runAfter: {
              }
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'GetSubscriptions\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/subscriptions/@{encodeURIComponent(items(\'Subscription_Loop\')?[\'subscriptionId\'])}/providers/@{encodeURIComponent(\'Microsoft.ManagedServices\')}/register'
                queries: {
                  'x-ms-api-version': '2016-06-01'
                }
              }
            }
          }
          runAfter: {
            List_subscriptions: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          GetSubscriptions: {
            connectionId: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/GetSubscriptions'
            connectionName: 'GetSubscriptions'
            connectionProperties: {
              authentication: {
                identity: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${parManagedIdentityName}'
                type: 'ManagedServiceIdentity'
              }
            }
            id: '${subscription().id}/providers/Microsoft.Web/locations/${parLocation}/managedApis/arm'
          }
        }
      }
    }
  }
  dependsOn: [
    resGetSubscription
  ]
}

resource resGetSubscription 'Microsoft.Web/connections@2016-06-01' = {
  name: 'GetSubscriptions'
  location: parLocation
  properties: {
    displayName: '${parLogicAppName}-connection'
    customParameterValues: {
    }
    api: {
      id:subscriptionResourceId('Microsoft.Web/locations/managedApis',parLocation,'arm')
    }
    parameterValueType: 'Alternative'
  }
}
