# Prerequisites

## Required prerequisites

1. **Deployment subscription** - Owner rights on an active Azure Subscription that is deployed within a Sovereign Landing Zone (SLZ) Management Group. See [SLZ install instructions](https://github.com/Azure/sovereign-landing-zone/blob/main/docs/03-Deployment-Overview.md) to deploy your SLZ. The SLZ has to be deployed with `allowConfidentialLocations` parameter having **eastus**, **westus**, **northeurope** and **westeurope** as values. Azure supports only these regions for confidential services used in this application (e.g. Azure Confidential Ledger)

1. **Subscription creation** - Follow [these instructions](03.1-subscription.md) on how to create a subscription.

1. **Encryption at host** - The Sovereign App uses Confidential Computing, which requires enabling the provider feature "encryptionAtHost" of the "Microsoft.Compute" resource provider.
    * The deployment script will turn on this feature if it isn't already, but this can take some time, in our experience up to 20-30 minutes.
    * The script will wait on this operation to complete, polling Azure at regular intervals to see if it is done.
    * If you wish, you can manually enable this feature yourself at any point after creating the subscription; that would reduce the time you need to wait for the feature when executing the deployment below
    * Documentation on how to do so is available in articles targetting the [Azure PowerShell module](https://learn.microsoft.com/azure/virtual-machines/windows/disks-enable-host-based-encryption-powershell) and the [Azure CLI](https://learn.microsoft.com/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli). You need to run first command to register, and then run the second command which checks the registration state is Registered (takes a few minutes):
    ``` powershell
    Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"

    Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
    ```

1. **Administration VM with prerequisite software** - The deploying workstation needs access to the SLZ hub network and ability to resolve DNS names within the SLZ's Private DNS Zones. It also needs certain software components installed. This is most easily accomplished by running the deployment from a Virtual Machine within the SLZ's provided *-connectivity* subscription; we provide a [admin VM Bicep script](../../../nonConfidential/adminVM/README.md) you can deploy for exactly this purpose.
<br>

## Optional prerequisites

On the admin VM installed earlier, you may want to install your preferred editor to edit configuration parameters and inspect the code. Two good free options are:

* [Visual Studio Code](https://code.visualstudio.com/)
    * [Bicep extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
    * [PowerShell extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)
* [Visual Studio 2022 Community Edition](https://visualstudio.microsoft.com/vs/community/)
    * [Bicep extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.visualstudiobicep)

## Next step

* Continue with [Deployment](04-deployment.md)
