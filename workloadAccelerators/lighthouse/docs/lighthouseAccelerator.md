# Azure Lighthouse template

Azure Lighthouse is a management service that enables service providers to manage Azure resources for multiple customers from a single control plane.

The Azure Lighthouse template empowers customers to grant service providers access to their tenant for the management of Azure services like [Azure Policy](https://learn.microsoft.com/azure/lighthouse/how-to/policy-at-scale), [Microsoft Sentinel](https://learn.microsoft.com/azure/lighthouse/how-to/manage-sentinel-workspaces), [Azure Arc](https://learn.microsoft.com/azure/lighthouse/how-to/manage-hybrid-infrastructure-arc), and more. The [activity logs](https://learn.microsoft.com/azure/lighthouse/how-to/view-service-provider-activity) are stored in the customer's tenant, enabling them to monitor changes to their tenant.

For more information, see [Azure Lighthouse](https://learn.microsoft.com/azure/lighthouse/overview). If you don't wish to grant tenant access to any service provider, you don't need to install this template.

The template requires two prerequisites:
* Active subscription to deploy this template
* [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner) permissions on the management group in the managed tenant under which Azure Lighthouse should manage subscriptions

There's no hard dependency of [Sovereign Landing Zone (SLZ)](https://github.com/Azure/sovereign-landing-zone), however we have implemented and tested this template given an SLZ management group hierarchy and existing policies.

We have created a policy to enforce Lighthouse on subscriptions under the scope of the given management group. If newer subscriptions are added after deployment, the Azure Lighthouse template will integrate those subscriptions via a logic application that triggers every four hours.

## Deploy Azure Lighthouse template

> [!NOTE]
> This deployment is only supported for the \'Owner\' role now. We're working on adding roles with more granular permissions in future releases.**

1. Open PowerShell 7.x. command shell.

1. Clone the [cloud for sovereignty apps](https://github.com/Azure/cloud-for-sovereignty-quickstarts) repo.

    ``` powershell
     git clone https://github.com/Azure/cloud-for-sovereignty-quickstarts
    ```

3. Run commands to authenticate to Azure, where `subscription-id` is the subscription ID where the deployment occurs. We recommend running it under the `Management` subscription ID under the `Platform` management group. See [image](images/LighthouseSubscriptionID.png) to identify the `Management` subscription ID.

    ``` powershell
    Login-AzAccount

    Connect-AzAccount -Subscription <subscription-id>
    ```

1. Navigate to `cloud-for-sovereignty-quickstarts\workloadAccelerators\lighthouse\scripts\parameters\` and open ``lighthouse.parameters.json`` in a text editor, for example VS Code.
    ``` powershell
    cd .\cloud-for-sovereignty-quickstarts\workloadAccelerators\lighthouse\scripts\parameters\
    ```

    ``` powershell
    code .
    ```

1. Update the parameters and save the file. Use the [Parameters](#parameters) table for
    assistance.

1. Change directory to scripts and run deployment PowerShell script.
    ``` powershell
    cd ..
    .\lighthouseAccelerator.ps1
    ```

1. A successful deployment finishes with the following statements:
    ``` powershell
    >>> Policy Remediation Started
    >>> Policy Remediation Successful
    >>> Lighthouse deployment Successful
    ```

1. Confirm deployment completion on providers by navigating to the Azure portal [Service providers](https://portal.azure.com/#view/Microsoft_Azure_CustomerHub/ServiceProvidersBladeV2/~/providers) offers page in your tenant where you want to manage services for your organization.

    - Search for the offer name that you specified in the parameters file ``parLighthouseOfferName``.
    - Search also under ``Service providers - Delegations`` tab to access on-demand auditing and reporting across all service providers actions. For more information, see [image](./images/LighthouseServiceProviders.png).

1. Confirm deployment completion for customers by navigating to the Azure portal [My customers - Customers](https://portal.azure.com/#view/Microsoft_Azure_CustomerHub/MyCustomersBladeV2/~/customers)  page.
    - Make sure you have the ``Show only delegation selected in the global subscriptions filter`` checked.
    - You should find the customer's name as the tenant you deployed your Lighthouse in, and ``Delegations`` for existing subscriptions with the assigned ``parRoleDefinitionId`` role in the config parameter.
    - From here, you can select each subscription that you want to manage and see all related resources. For more information, see [image](./images/LighthouseCustomers.png).

## Parameters

The Parameters table shows the descriptions and accepted values for all parameters within the ``lighthouse.parameters.json`` file. All parameters marked with ``*`` are required.

| Parameter           |Description    | Guidance, examples               |
|---------------------|---------------|----------------------------------|
| parDeploymentPrefix* | Deployment prefix used for creating deployment resource group and resources. If you're deploying the template on an SLZ, we recommend having this prefix match the SLZ’s prefix. | Five characters or less, lowercase, for example: mcfs |
| parManagementGroupId* | The Id of the top level management group where we enable Lighthouse on all subscriptions under it. In case you are deploying on SLZ, it's the top level management group of the SLZ| Maximum 10 characters, for example {slz-name} |
| parDeploymentLocation* | Location of the deployment. Location must be part of the [allowed locations list](../scripts/lighthouse.bicep) if deploying this on an SLZ deployment.| for example: northeurope |
| parLighthouseManagementTenantId* | The tenant ID of the service provider. **Note: This value can't be the same as the tenant ID where this template is being deployed.* | In the Azure portal, sign in to the service provider tenant. Navigate to Azure AD to find the tenant ID. For more information, see [image](./images/LightHouseTenantID.png) for help with finding this information. |
| parLighthouseOfferName* | Name of the service provider offer. | Maximum 20 characters, for example: "Lighthouse offer" |
| parLighthouseOfferDescription* | Brief description of the offer. | for example: “Lighthouse description” |
| parPrincipalId*| The principal ID value of the user, group, or service principal in the service provider tenant, which gives access to your tenant. | From the Azure AD, locate the ObjectId for the user, group, or service principal in the service provider's tenant. |
| parPrincipalIdDisplayName* | Display name to identify the principal ID. | Group or user or service principal name |
| parRoleDefinitionId* | Role to be assigned for service provider, all built-in roles are currently supported with Azure Lighthouse, but with the some exceptions. Note:Lighthouse does not support owner role. <br /> For more information on predefined roles, navigate to [Azure RBAC roles](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) and reference [Roles for Azure Lighthouse scenarios](https://learn.microsoft.com/azure/lighthouse/concepts/tenants-users-roles#role-support-for-azure-lighthouse) for restrictions on role usage.| Contributor Role is the default value
