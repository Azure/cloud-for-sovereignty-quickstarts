# SLZ Administrative Workstation VM

This script deploys an administrative workstation VM including the software listed to the *Connectivity* subscription of a Sovereign Landing Zone environment. That VM connects to the SLZ hub virtual network and thus have data plane access to administer resources on peered spoke virtual networks. For instance, this admin VM is the recommended deployment platform for [the HR Sovereign App](../../confidential/hrAppWorkload/README.md).

## Deployed Software

* Git
* Bicep
* PowerShell 5 modules:
  * Az
  * SqlServer
* SQL Server Management Studio
  * Including Azure Data Studio

## Prerequisites

* [PowerShell Az module](https://learn.microsoft.com/powershell/azure/install-az-ps)
* [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install#install-manually)

## Instructions

1. Sign in with the following command, where `<SUBSCRIPTION_ID>` is the GUID of the SLZ's *Platform - Connectivity* subscription that the admin VM is added to.

    ``` powershell
    Login-AzAccount

    Connect-AzAccount -Subscription <SUBSCRIPTION_ID>
    ```

2. Change directory to `.\sovereignApplications\nonConfidential\adminVM\scripts`
3. Run ` Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`
4. Configure the parameters in `adminvm.parameters.json` as per the [following table](#deployment-parameters) and save the file.
5. Execute `.\deploy.ps1` from AdminVM folder.
6. When prompted, supply the password to be set on the VM, and press enter.
7. Wait until the script returns, which may take 15-20 minutes. You can track deployment through the *Connectivity* subscription's Deployments page in the Azure portal.
8. The process prompts you to connect to the Admin VM and provide credential info. Follow the illustrations to sign in into the Admin VM: [Admin VM RDP Step1](media/AdminVMRDP-1.jpg), [Admin VM RDP Step2](media/AdminVMRDP-2.jpg), [Admin VM RDP Step3](media/AdminVMRDP-3.jpg)
9. Continue with sovereign app [deployment](../../confidential/hrAppWorkload/docs/04-deployment.md)

> [!NOTE]
> You can connect later to admin VM via Bastion. You can find the VM in the Azure portal, click the `Connect/Go to Bastion`, then enter the login credentials for the administration workstation VM and select Connect. See illustrations [Connect to VM 1](../../confidential/hrAppWorkload/media/connect-to-VM1.png), [Connect to VM 2](../../confidential/hrAppWorkload/media/connect-to-VM2.png).

### Deployment Parameters

The parameters listed must be entered in order to deploy this script. Other parameters are available for further customization, see [adminvm.bicep](./scripts/adminvm.bicep).

> [!NOTE]
> The additional parameter `parSubnetAddressSpace` which defines the subnet IP space used by the admin VM subnet, which needs to be within the hub network ip space but must be disjoint with any other existing subnets (its default value is `10.20.100.0/24`).

 | Parameter           |Description    | Examples               |
 |---------------------|---------------|------------------------|
 | `parDeploymentLocation` | Location of the deployed resources. Needs to be consistent with policy set on SLZ environment. | `eastus`, `westus`, `northeurope`, `westeurope`.  |
 | `parHubNetworkRg` | Name of the resource group in which the SLZ hub virtual network is deployed. | `rg-<SlzPrefix>-hub-network-eastus` |
 | `parHubNetwork` | Name of the SLZ hub virtual network. | `hub-<SlzPrefix>-eastus` |
 | `parAdminUsername` | The name of the admin user account created on the VM. | `slzadmin` |
