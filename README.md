# Microsoft Cloud for Sovereignty Lifecycle Tools<sup>PREVIEW</sup>, workload templates and sample application for Microsoft Cloud for Sovereignty (including Sovereign Landing Zone)

## Overview

[Sovereign Landing Zone (SLZ) ](https://github.com/Azure/sovereign-landing-zone) provides an environment offering guardrails through policies and policy sets, security-enforcement, and consistent baseline infrastructure for deploying workloads and applications. SLZ is based on [Azure Landing Zones](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/) and extends it with guardrails and security controls specific to sovereignty requirements.

To help accelerate customers time-to-value while assisting them in meeting their compliance objectives, the [Microsoft Cloud for Sovereignty](https://learn.microsoft.com/industry/sovereignty) includes ready-to-use workload templates that can be consistently deployed and operated in a repeatable manner. The workload templates are aligned with [Sovereignty Policy Baseline](https://github.com/Azure/sovereign-landing-zone/blob/main/docs/scenarios/Sovereignty-Policy-Baseline.md), [Cloud for Sovereignty policy portfolio](https://github.com/Azure/cloud-for-sovereignty-policy-portfolio), and [Azure Landing Zone default policies](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Policies).

We're introducing two templates, and a sample sovereign application for learning purposes and to validate the functionality of SLZ policy sets and their enforcement of the confidentiality of services within the Sovereign Landing Zone.

The Microsoft Cloud for Sovereignty Lifecycle Tools<sup>PREVIEW</sup> provides an early look at future functionality that is under consideration. It is deployed as a Virtual Machine in  your Azure tenant. Our goal is to provide an early glimpse into our future work that is under consideration and provide a forum on this repository for users to provide comments and feedback.

You can deploy all applications using the PowerShell and Bicep, and they are fully compatible with SLZ. The Microsoft Cloud for Sovereignty Lifecycle Tools<sup>PREVIEW</sup> can be deployed as a Virtual Machine in your Azure tenant. To learn more about the advantages of using these templates, refer to the following links: 

1. [**Azure Lighthouse template**](./workloadAccelerators/lighthouse/docs/lighthouseAccelerator.md)
2. [**Azure Confidential Virtual Machine AMD-SNP template**](./workloadAccelerators/confidentialVirtualMachine/docs/cvmAccelerator.md)
3. [**Confidential sample application**](./sovereignApplications/confidential/hrAppWorkload/README.md)
4. [**Microsoft Cloud for Sovereignty Lifecycle Tools<sup>PREVIEW</sup>**](./prototypes/deploy-prototypes-1-getting-started.md)

## Shared responsibility and customer responsibilities

To ensure your data is secure and your privacy controls are addressed, we recommend that you follow a set of best practices when deploying into Azure:

- [Azure security best practices and patterns](https://learn.microsoft.com/azure/security/fundamentals/best-practices-and-patterns)
- [Microsoft Services in Cybersecurity](https://learn.microsoft.com/azure/security/fundamentals/cyber-services)

Protecting your data also requires that all aspects of your security and compliance program include your cloud infrastructure and data. The following guidance can help you to secure your deployment.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

## Microsoft Legal Notice.  
The Microsoft Cloud for Sovereignty Quickstarts 1) is not designed, intended, or made available as legal services, (2) is not intended to substitute for professional legal counsel or judgment, and (3) should not be used in place of consulting with a qualified professional legal professional for your specific needs. Microsoft makes no warranty that the Microsoft Cloud for Sovereignty Quickstarts is accurate, up-to-date, or complete. You are wholly responsible for ensuring your own compliance with all applicable laws and regulations. 