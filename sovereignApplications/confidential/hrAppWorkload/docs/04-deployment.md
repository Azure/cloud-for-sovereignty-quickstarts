# Deployment

We have split deployment in three parts:

1. [**Pre-deployment**](#pre-deployment) which consists of downloading the source code on the administration VM, authenticate to Azure, and updating required parameters.
1. [**Deployment**](#deployment-1) with execution of the main script that deploys the app.
1. [**Post-deployment**](#post-deployment) which verifies deployed resources.

You're now connected to the administrative VM workstation. Unless otherwise specified, any subsequent steps should be executed within the administrative VM and **NOT** on your personal workstation.

## Predeployment

1. On the administrative VM, open Windows PowerShell as administrator and run the below commands.

1. Clone the current [Cloud for Sovereignity Apps repository](https://github.com/Azure/cloud-for-sovereignty-quickstarts/). Note that you will be required to authenticate using your GitHub credentials. Follow instructions there by going to `https://github.com/login/device` on your local machine to authenticate your VM via a code.

    ``` powershell
    git clone https://github.com/Azure/cloud-for-sovereignty-quickstarts/
    ```

1. Change directory to cloud-for-sovereignty-quickstarts

    ``` powershell
    cd .\cloud-for-sovereignty-quickstarts\
    ```

1. Run the given commands, one at a time, to authenticate to Azure (note that due to different authentication contexts for the Az and SqlServer PowerShell modules, both of these commands trigger popup sign in prompts). For this authentication, use the deployment tenant credentials and **NOT** your GitHub credentials. <your-subscription-id> is the [subscription created](03.1-subscription.md) under SLZ confidential corp management group in previous step.

    ``` powershell
    Connect-AzAccount -Subscription <your-subscription-id>
    Add-SqlAzureAuthenticationContext -Interactive
    ```

1. Navigate to `cd .\sovereignApplications\confidential\hrAppWorkload\scripts\parameters\` and open ``hrAppWorkload.parameters.json`` file in a text editor, for example VS Code by using `code .`. Update the parameters and save the file. Use table [Parameters](04.1-deployment-parameters.md) for assistance.

## Deployment

1. Change directory to `scripts` and run PowerShell Script following command, where *&lt;DeploymentExecutionLocation&gt;* is the region in which Azure Resource Manager executes the deployment script. This step isn't necessarily where the deployed resources reside and is governed by the parameter *parDeploymentLocation* from the parameters file. If *&lt;DeploymentExecutionLocation&gt;* is left out, the value defaults to "eastus":

    ``` powershell
    cd ..\
     .\hrAppWorkload.ps1 <DeploymentExecutionLocation>
    ```

1. A successful run should end with `>>> Database initialization complete.`

## Post-deployment

1. After the deployment, go to [Azure portal](https://portal.azure.com/) - {your-subscription}-Deployments to verify that deployment was successful. This [image](../media/deployment.png) shows a successful deployment of the sovereign application.

1. Navigate to the resource group that was created (last one on the deployment details list) and notice that the [resources](../media/resources.png) that have been created.

1. Navigate to the virtual machine and copy the private IP address that was allocated to the VM. You'll need [this IP](../media/vm.png) in the next step to navigate to the HR Web App UI.

1. As the subnet was established in this deployment, remember to apply the same of subnet value back to Sovereign Landing Zone using the parCustomSubnets parameter if you choose to deploy the application based on it. Failing to do so may result in an "InUseSubnetCannotBeDeleted" error when rerunning the Sovereign Landing Zone deployment script.

### Next step

* Continue with [Managing application](05-application-management.md)
