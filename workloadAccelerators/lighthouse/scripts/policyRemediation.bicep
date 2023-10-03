// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
/*
  SUMMARY: This file will deploy a policy remediation to a management group.
  AUTHOR/S: Cloud for Sovereignty
*/
targetScope = 'managementGroup'

@description('Exemption Name')
param parPolicyRemediationName string

@description('Policy Set Assignment id')
param parPolicyAssignmentId string

@description('Reference ids of Policy to be remediated')
param parPolicyDefinitionReferenceId string

@allowed([
  'ExistingNonCompliant'
  'ReEvaluateCompliance'
])
@description('Remediation Discovery Mode - ExistingNonCompliant')
param parResourceDiscoveryMode string = 'ExistingNonCompliant'

// Deploy the policy remediation
resource resPolicySetRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = if (empty(parPolicyDefinitionReferenceId) == false) {
  name: take('${parPolicyRemediationName}-${parPolicyDefinitionReferenceId}', 64)
  properties: {
    policyAssignmentId: parPolicyAssignmentId
    policyDefinitionReferenceId: parPolicyDefinitionReferenceId
    resourceDiscoveryMode: parResourceDiscoveryMode
  }
}

resource resPolicyRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = if (empty(parPolicyDefinitionReferenceId)) {
  name: parPolicyRemediationName
  properties: {
    policyAssignmentId: parPolicyAssignmentId
    resourceDiscoveryMode: parResourceDiscoveryMode
  }
}
