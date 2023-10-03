# HR sovereign application - Frequently Asked Questions

This document answers the most common questions related to the HR Sovereign application.

1. Deployment fails with error `Code:CreateDatabaseAttemptedWithRotationInProgress`. See image for exact [error message](../media/database-tde-error.png), you need to wait and retry the same deployment script. 

    * **Reason**: This error message indicates that the database creation operation can't be performed at this time due to ongoing TDE key rotation on the server. You may need to wait until the TDE key rotation process is complete before attempting to create the database again.
    * **Resolution**: You need to wait and retry the same deployment script. Rerun the script `.\hrAppWorkload.ps1` from `cloud-for-sovereignty-quickstarts\sovereignApplications\confidential\hrAppWorkload` folder.
<br>
<br>
1. Deployment fails with error `ParameterBindingException`. See image for exact [error message](../media/parameter-binding-error.png)

    * **Reason**: This error message indicates that your Azure authentication has expired, and your Azure SQL authentication
    * **Resolution**: Rerun the scripts to authenticate from [predeployment](../docs/04-deployment.md#pre-deployment) and then continue with [deployment](../docs/04-deployment.md#deployment-1) steps.

    ``` Powershell  
    Connect-AzAccount -Subscription <your-subscription-id-from-previous-step>
    Add-SqlAzureAuthenticationContext -Interactive
    ```

To report issues or get support, submit a ticket through [GitHub Issues](https://github.com/Azure/cloud-for-sovereignty-quickstarts/issues)

