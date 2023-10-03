#  Azure Confidential Virtual Machine AMD-SNP template - Frequently Asked Questions

This document answers the most common questions related to the Azure Confidential Virtual Machine AMD-SNP template

1. Deployment fails with error `Code: InUseSubnetCannotBeUpdated`, see image for exact [error message](media/in-use-subnet.png)
    * **Reason**: This error message indicates that the subnet parVnetAddressPrefix you've chosen for this app is in use by other application and you need to choose another prefix.
    * **Resolution**: Delete the entire resource group that was created and redeploy the application with a new parVnetAddressPrefix which doesn't collide with existing subnets.

To report issues or get support, please submit a ticket through [GitHub Issues](https://github.com/Azure/cloud-for-sovereignty-quickstarts/issues)

