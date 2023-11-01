# Azure Confidential Virtual Machine AMD-SNP template

Confidential Virtual Machines (Confidential VMs) are an offering within Azure Confidential Computing, designed for customers with demanding security and confidentiality requirements.

The Azure Confidential Virtual Machine AMD-SNP template offers Confidential VMs based on [AMD processors with SEV-SNP technology](https://learn.microsoft.com/azure/confidential-computing/virtual-machine-solutions-amd). These VMs provide a hardware-enforced boundary to help meet customer security needs. Customers can use confidential VMs for migration without making changes to the code, with the platform protecting their VM's state from being read or modified.

The template requires two prerequisites:
* Active subscription to deploy this template
* Owner or write permissions on the subscription in which the confidential VM should be deployed to

There's no hard dependency of [Sovereign Landing Zone (SLZ)](https://github.com/Azure/sovereign-landing-zone), however we have implemented and tested this template under the SLZ confidential management group where existing confidential policies are enforced.

> [!NOTE]
> Common known issues and FAQ are listed in our [Known Issues and FAQ](faq.md) page. If you cannot find an answer in the known issues page, then please log issues to [GitHub issues](https://github.com/Azure/cloud-for-sovereignty-quickstarts/issues)

## Deploy Azure Confidential Virtual Machine AMD-SNP template

1. Open **PowerShell 7.x**.

1. Clone repo [cloud for sovereignty apps](https://github.com/Azure/cloud-for-sovereignty-quickstarts)

    ``` powershell
    git clone https://github.com/Azure/cloud-for-sovereignty-quickstarts
    ```

1. Create a [subscription](../../../sovereignApplications/confidential/hrAppWorkload/docs/03.1-subscription.md) if you don't have an existing one.

1. Run the following commands to authenticate to Azure and to set the subscription for which you want this deployment to be hosted.

    ``` powershell
    Login-AzAccount

    Connect-AzAccount -Subscription <your-subscription-id-from-previous-step>
    ```

1. Navigate to `cloud-for-sovereignty-quickstarts\workloadAccelerators\confidentialVirtualMachine\scripts\parameters\` and open `confidentialVirtualMachine.parameters` in a text editor, for example VS Code.

    ``` powershell
    cd .\cloud-for-sovereignty-quickstarts\workloadAccelerators\confidentialVirtualMachine\scripts\parameters\
    ```

    ``` powershell
    code .
    ```

1. Update the parameters and save the file. Use table [Parameters](#parameters) for assistance.

1. Change directory to scripts and run deployment PowerShell command to deploy the template.

    ``` powershell
    cd ..
    .\confidentialVirtualMachineAccelerator.ps1
    ```

1. A successful deployment finishes with the following statements:

    ``` powershell
    >>> Confidential VM deployment successful
    ```

1. Confirm deployment completion by connecting to the Azure Portal
    * Connect to Azure Portal and search for your subscription in the main "Search resources, services, and docs"
    * Type your subscription name that you have provided above
    * Once you have identified your subscription, verify in `Deployments` the last deployment succeeded.
    * Navigate to Resource Groups and find {parDeploymentPrefix}-rg
    * Inspect all resources created.

1. Confirm deployment completion by connecting to the Confidential VM
    * Connect to your VM through the *Connect/Bastion* link on its page in the Azure Portal.
    * Find the VM in the Azure portal, click the *Connect/Go to Bastion*, then enter the login credentials for the VM and selet *Connect*. See [Connect to VM Screen 1](../../../sovereignApplications/confidential/hrAppWorkload/media/connect-to-VM1.png) and [Connect to VM Screen 2](../../../sovereignApplications/confidential/hrAppWorkload/media/connect-to-VM2.png) for illustration. You provided the admin username in the parameters file `parAdminUsername`, and you provided the password in the parameter `parAdminPasswordOrKey`

1. As the subnet was established in this deployment, remember to apply the same of subnet value back to Sovereign Landing Zone using the parCustomSubnets parameter if you choose to deploy the application based on it. Failing to do so may result in an "InUseSubnetCannotBeDeleted" error when rerunning the Sovereign Landing Zone deployment script. Below is the parCustomSubnets parameter example in Sovereign Landing Zone:

    "parCustomSubnets":{
    "type":"array",
    "usedBy":"all and platform",
    "value":[
        {
            "name":"AdminVmSubnet",
            "ipAddressRange":"10.20.100.0/24"
        }
    ],
    "description":"List of other subnets to deploy on the hub VNET and their CIDR ranges."
    }

## Parameters

Descriptions and accepted values for all parameters within the ``confidentialVirtualMachine.parameters.json`` file are described as follows:

We provide default values for most available parameters, but you must set the parameters that are required. Refer to the table or to parameter definitions in the [bicep script](../scripts/confidentialVirtualMachineApp.bicep) for allowed values. All parameters marked with ``*`` are required. Per JSON syntax, strings are delimited by quotes, whereas numeric values and boolean values aren't.

### Required parameters

| Parameter           |Description                              | Examples | Default value |
|---------------------|-----------------------------------------|----------|--------|
| parDeploymentPrefix* | Prefix that is added to all resources created by this deployment. | Five characters or less, lowercase, for example: mcfs |  |
| parDeploymentLocation* | Location of the deployment. | for example: northeurope |  |
| parHubNetworkResourceId* | Resource ID of the SLZ's hub virtual network from the *%slzprefix%-connectivity* subscription. For more information of where to retrieve this parameter value, see [image](../../../sovereignApplications/confidential/hrAppWorkload/media/slz-virtual-network.png). Navigate to your SLZ's connectivity subscription -> Resource Groups. Select the Resource Group, which isn't NetworkWatcherRG. On the Resources page, select the virtual network resource and go to its Properties page. | /subscriptions/`<sub-id`>/resourceGroups<br>/rg-aslz-hub-network-eastus/<br>providers/Microsoft.Network/<br>virtualNetworks/hub-aslz-eastus | "" |
 | parAdminPasswordOrKey* | Password or public key (see option `parAuthenticationType`) for the admin user created on Confidential VM. If password, must fulfill password complexity requirements set by SLZ policy. | P4$$w0rd!!! |  |
 | parVnetAddressPrefix* | IP address space of the virtual network created for this workload, in  CIDR notation. Must be unique across all vnets peered against the SLZ hub vnet as referenced above. For example, if SLZ's parHubNetworkAddressPrefix is 10.20.0.0/16, then this parameter can't be the same, for example it can be 10.21.0.0/16 | 10.21.0.0/16 | |


### Optional parameters

| Parameter           |Description                              | Examples | Default value |
|---------------------|-----------------------------------------|----------|--------|
| parVmName | Name of the Confidential VM to be created. The deployed resource has a unique name suffix appended to prevent namespace clashes. | cvm | {parDeploymentPrefix}<br>-vm-{unique-suffix} | |
| parAdminUsername | Admin user name for the virtual machine | test-admin | {parDeploymentPrefix}-admin |
| parVmSize | Size of the Confidential VM to be created. For more information, see [supported sizes](https://learn.microsoft.com/azure/virtual-machines/dcasv5-dcadsv5-series) | Standard_DC2as_v5 | Standard_DC2as_v5 |
| parOsImageName | OS image for the virtual machine. Allowed values are: 'Windows Server 2022 Gen 2', 'Windows Server 2019 Gen 2', 'Ubuntu 22.04 LTS Gen 2', 'Ubuntu 20.04 LTS Gen 2'| Ubuntu 22.04 LTS Gen 2 | Ubuntu 22.04 LTS Gen 2 |
| parAttestationProvidersName | Attestation provider name. The deployed resource has a unique name suffix appended to prevent namespace clashes. | testattp | {parDeploymentPrefix}<br>attp{unique-suffix} |
| parKeyVaultName | Azure Key Vault name to hold the keys for the Disk Encryption Set used for the VM disks. The deployed resource has a unique name suffix appended to prevent namespace clashes. | test-kv | {parDeploymentPrefix}-kv |
| parManagedIdentityName | Name of the User Assigned Managed Identity used in some RBAC scenarios (for example, for the Disk Encryption Set). | test-id | {parDeploymentPrefix}-id |
| parVirtualNetworkName | Virtual network name of this VM| - | {parDeploymentPrefix}-vnet |
| parTags | List of tags to be applied to some resources. | {'product': 'cvm-template'} | {'product': 'cvm-template'} |

### Adding parameters to override optional ones

In case you want to override an available [optional parameter](#optional-parameters) from the table with a value that isn't in the parameter file, just add a JSON fragment corresponding to the value already there, for example:

``` json
  "parAdminUsername": {
    "value": "AdminUser"
  },
```
