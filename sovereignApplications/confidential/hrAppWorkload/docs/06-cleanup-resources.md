# Clean up resources

1. Delete the resource group created by this application by running the following command in the Windows PowerShell:

``` powershell
    Remove-AzResourceGroup -Name <parDeploymentPrefix>-rg -Force
```

1. Delete the subscription created for this deployment:

``` powershell
    Install-Module Az.Subscription
    Disable-AzSubscription -Id <subscriptionId>
```