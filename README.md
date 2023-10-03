# Workload templates and sample application for Sovereign Landing Zone

## Overview

[Sovereign Landing Zone (SLZ) ](https://github.com/Azure/sovereign-landing-zone) provides an environment offering guardrails through policies and policy sets, security-enforcement, and consistent baseline infrastructure for deploying workloads and applications. SLZ is based on [Azure Landing Zones](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/) and extends it with guardrails and security controls specific to sovereignty requirements.

To help accelerate customers time-to-value while assisting them in meeting their compliance objectives, the [Microsoft Cloud for Sovereignty](https://learn.microsoft.com/industry/sovereignty) includes ready-to-use workload templates that can be consistently deployed and operated in a repeatable manner. The workload templates are aligned with [Sovereignty Policy Baseline](https://github.com/Azure/sovereign-landing-zone/blob/main/docs/scenarios/Sovereignty-Policy-Baseline.md), [Cloud for Sovereignty policy portfolio](https://github.com/Azure/cloud-for-sovereignty-policy-portfolio), and [Azure Landing Zone default policies](https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Policies).

We're introducing two templates, and a sample sovereign application for learning purposes and to validate the functionality of SLZ policy sets and their enforcement of the confidentiality of services within the Sovereign Landing Zone.

You can deploy all applications using the PowerShell and Bicep, and they are fully compatible with SLZ. To learn more about the advantages of using these templates, refer to the following links: 

1. [**Azure Lighthouse template**](./workloadAccelerators/lighthouse/docs/lighthouseAccelerator.md)
2. [**Azure Confidential Virtual Machine AMD-SNP template**](./workloadAccelerators/confidentialVirtualMachine/docs/cvmAccelerator.md)
3. [**Confidential sample application**](./sovereignApplications/confidential/hrAppWorkload/README.md)

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

## Preview Notice

**Preview Terms**. The Sovereign Landing Zone workload templates and sample application preview (the "PREVIEW") are licensed to you as part of your [Azure subscription](https://azure.microsoft.com/support/legal/) and subject to terms applicable to "Previews" as detailed in the Universal License Terms for Online Services section of the <u></u>Microsoft Product Terms and the [Microsoft Products and Services Data Protection Addendum ("DPA")](https://www.microsoft.com/licensing/terms/welcome/welcomepage). AS STATED IN THOSE TERMS, PREVIEWS ARE PROVIDED "AS-IS," "WITH ALL FAULTS," AND "AS AVAILABLE," AND ARE EXCLUDED FROM THE SERVICE LEVEL AGREEMENTS AND LIMITED WARRANTY. Previews may employ lesser or different privacy and security measures than those typically present in Azure Services. Unless otherwise noted, you should not use Previews to process Personal Data or other data that is subject to legal or regulatory compliance requirements. The following terms in the [DPA](https://www.microsoft.com/licensing/docs/view/Microsoft-Products-and-Services-Data-Protection-Addendum-DPA) do not apply to Previews: Processing of Personal Data; GDPR, Data Security, and HIPAA Business Associate. We may change or discontinue Previews at any time without notice. We also may choose not to release a Preview into General Availability.