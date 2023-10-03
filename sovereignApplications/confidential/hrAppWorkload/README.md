# Confidential Sample Application

## Motivation and purpose

To ensure and validate [Sovereign Landing Zone](https://github.com/Azure/sovereign-landing-zone) (SLZ) deployed infrastructure serves confidential needs of the customers' workloads, we have designed a Human Resources (HR) confidential sample application to:

* Prevent Microsoft operators from accessing your data at rest, in transit, or in use, when configured as directed.
* Prevent unauthorized access when the workloads are running with [Azure confidential computing resources](https://learn.microsoft.com/azure/confidential-computing/overview-azure-products).
* Allow only customers with the proper access policies to access secret keys stored in protected managed enclaves. Microsoft personnel or anyone else can't access the secret keys. 
* Validate that applied SLZ policies work as expected; policies are applied and enforced, and policies are auditable on change.

Azure confidential computing enhances the security posture of your applications by protecting data and code when in use that is when running and being processed in memory. This extra level of protection elevates the existing security posture in Azure by running applications in hardware-encrypted trusted execution environments.

After completing this tutorial, you'll learn about common confidential use cases validated on an end-to-end sovereign application. Follow these steps in order to complete the tutorial.

1. [Scenario and use cases](docs/01-scenario-usecases.md)
2. [Architecture](docs/02-architecture.md)
3. [Prerequisites](docs/03-prerequisites.md)
4. [Deployment](docs/04-deployment.md)
5. [Managing application](docs/05-application-management.md)
6. [Clean up resources](docs/06-cleanup-resources.md)

## Issues and FAQ

Common known issues and FAQ are listed in our [Known Issues and FAQ](./docs/07-faq.md) page.

If you can't find an answer in the known issues page, log issues to [GitHub issues](https://github.com/Azure/cloud-for-sovereignty-quickstarts/issues)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
