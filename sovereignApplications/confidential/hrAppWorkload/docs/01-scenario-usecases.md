# Scenario and use cases

## Scenario

A company, working on behalf of a national government, has been growing fast and they need to keep track of the payroll and benefits for all the new people joining them. Their HR data must be protected at rest, in transit, and while in use from unauthorized viewing, access or modification.

## Use cases

The use cases for which the company is audited yearly by a government cybersecurity officer is listed in the [`Managing application`](05-application-management.md) section. We'll experiment a deep walkthrough of these use cases demonstrating the capabilities of Microsoft Cloud for Sovereignty.

The personas and their corresponding roles are listed as follows: 

| **Persona** | **Description** |
| - | - |
| Partner Cloud Administrator | I can successfully deploy a confidential workload into confidential Management Groups | 
| Partner Cloud Administrator | I get blocked by policies when deploying a non-confidential workload into confidential Management Groups |
| Customer Cloud Administrator | I can manage an HR app securely and confidentially via a web application   | 
| Customer Cloud Administrator | I can perform basic operations {list all employees, get employee by id, create a new employee, update salary, delete employee} on an HR app and confidential data will be protected if I don’t have the proper rights |
| HR Administrator | I can view encrypted data using Enable Always Encrypted (column encryption) and Enable secure enclaves options |
| Customer Cloud Administrator | As a malicious SQL database owner, I will be denied access to employee confidential data |
| Cloud Security Officer | I have access to an immutable ledger of transition history for audit and to help meet regulatory compliance |
| Malicious VM Administrator | I will be denied access to application logs and confidential employee data |
| Malicious VM Administrator | With the access to Hypervisor, I will be denied access to the VM, including application binaries and in-memory data |

## Next step

* Learn about [Architecture](02-architecture.md) of this application.
