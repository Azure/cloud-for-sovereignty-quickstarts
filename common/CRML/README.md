# Why Does This Directory Exist & Contain Other Bicep Modules?

This directory exists to host modules that are **not** specific to the Azure Landing Zones modules that are contained within the `infra-as-code/bicep/modules` directory.

The modules inside this directory, `infra-as-code/bicep/CRML` are modules that we are potentially planning to remove from this repo and migrate/consume them from the [Common Azure Resource Modules Library repo](https://github.com/Azure/ResourceModules) as part of future releases, and when features such as the Bicep Public Module Registry are available.

> These are plans/aspirations which are not confirmed and might change, but we are sharing them for clarity and planning purposes 👍

These modules are consumed and called by other modules within this repo. For example, the `customerUsageAttribution` module is called in all modules as you can see from each of those modules `.bicep` files.