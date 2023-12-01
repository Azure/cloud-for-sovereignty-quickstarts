# Managing application

At this point, [HR application architecture](../media/architecture-current.png) was deployed in your Sovereign Landing Zone.
Now, let's go over some of the scenarios of managing the application.

1. As an HR authorized user, connect to ContosoHR Web App to perform basic operations on HR app:

    * Connect to your admin VM and open a browser.
    * Navigate to https://{VM-IP-address}:5001. On first run, you see a TLS/SSL warning, telling you that the connection may not be secure. This warning is to be expected and is because we're using a self-signed certificate for the ContosoHR service. Select through this warning; the connection is assuredly secure despite it (though in the general case, on the public Internet, you would do right to be *cautious if such a warning shows up!)
    * You should see the [Employee List](../media/contosoHR-list.png)
    * The SSN and Salary columns on the SQL Server has been encrypted with a Column Encryption Key (CEK) using [SQL Server Always Encrypted](https://learn.microsoft.com/sql/relational-databases/security/encryption/configure-always-encrypted-keys-using-ssms?view=sql-server-ver16). That CEK has in turn been encrypted by a Column Master Key (CMK) which is stored on a deployed Azure Key Vault entirely separate from the SQL Server. This design ensures that the encryption keys and encrypted sensitive data are kept separate, such that even a malicious SQL Server administrator is unable to decrypt the latter.
    * The Confidential VM connects to the SQL Server using a service principal identity; that identity has read access to the Key Vault on which the CMK is stored. At runtime, the SQL driver on the Confidential VM retrieves the CMK, uses it to decrypt the CEK, and finally, uses the CEK to decrypt the encrypted data that is returned from the SQL server.
    * For the sake of ease-of-illustration, the columns FirstName and LastName haven't been encrypted. The values can be retrieved in plaintext by a normal SQL query, by a user with sufficient querying privileges.
    * Next you can manage the list of employees such as filter by their salary range, search by any of the columns or sort by columns.
    * You can also navigate to Employees tab to create new employees, [edit employee](../media/contosoHR-employee-edit.png) or delete existing.

1. As an HR Admin authorized user using `Enable Always Encrypted (column encryption)` and `Enable secure enclaves` options, I can view encrypted data
    * Stay on the same admin VM and OpenSQL Server Management Studio (SSMS).
    * Connect with your account that ran the deployment and authenticate with tenant credentials, and choose the database. Use an Azure attestation provider to connect to SGX enclaves on SQL Server Always Encrypted, for example, https://sharedwus.wus.attest.azure.net. Follow these steps shown in images: [SQL Connect 1](../media/connect-to-sql-1.png), [SQL Connect 2](../media/connect-to-sql-2.png), [SQL Connect 3](../media/connect-to-sql-3.png), [SQL Choose DB ](../media/sql-server-choose-db.png)
    
    > [!NOTE] 
    > In a real-world scenario, users have to create their [attestation provider with signed policies](https://learn.microsoft.com/azure/attestation/quickstart-portal#create-and-configure-the-provider-with-signed-policies)

    * Once you connected, expand Databases - {your-db} - HR.Employees table. Right select on the table and Select top 1000 Rows
    * You should be able to see clear text for SSN and Salary as shown in the image [SQL Query Plain](../media/query-sql-plain.png)

1. As a malicious SQL database admin/owner (or cloud operator), I can't see employee confidential data if I don't use `Enable Always Encrypted (column encryption)` and `Enable secure enclaves` options with the correct enclave attestation service Url.
    * Connect with the SqlAdministratorLogin: `hrapp-admin` and the password that you have set in the parameter file, and uncheck `Enable Always Encrypted (column encryption)` and `Enable secure enclaves` in the Always Encrypted tab, as shown in the images [SQL Connect 5](../media/connect-to-sql-5.png), [SQL Connect 4](../media/connect-to-sql-4.png)

    * Once you connected, expand Databases - {your-db} - HR.Employees table. Right select on the table and Select top 1000 Rows
    * You should see cipher text for SSN and Salary as shown in the image [SQL Query Cipher](../media/query-sql-cipher.png)

1. As HR Admin authorized user, I have access to an immutable ledger of transition history for audit and to help meet regulatory compliance. Logs are streamed to Confidential Ledger.

    * To retrieve your logs from the Azure Confidential Ledger, use the [Confidential Ledger Client](../../contosoHR/ConfidentialLedgerClient/README.md) provided for this purpose.
    * To run the client, you need to connect to admin VM, then you need to build it, as documented in the link earlier. Then step into the Confidential Ledger Client directory and execute the following commands:
    `dotnet run %LEDGER_NAME%`, where `%LEDGER_NAME%` is the resource name of your ledger as seen in the Azure portal, for example, `hrapp-acl-pwm5h3hwyh3ra`.
    * You may need to authenticate to Azure in a pop-up window; if so, use the deployment tenant credentials, **NOT** your Microsoft credentials.
    * If all goes well, the client retrieves the ledger entries and output to the console.

1. Deploy a nonconfidential service (Azure Storage) and get rejected by policies:

    * In the same Windows PowerShell where you deployed your application (assuming you are in `cloud-for-sovereignty-quickstarts` folder), run the following commands, one by one:

        ``` powershell
            cd .\sovereignApplications\nonConfidential\storageAccount\scripts
            Connect-AzAccount -Subscription <your_subscription_id>
            $groupName = "rg-test"
            $location = "<your-deployment-location>"
            New-AzResourceGroup -Name $groupName -Location $location
            # The below command should fail with a code indicating RequestDisallowedByPolicy
            New-AzResourceGroupDeployment -Name "PolicyFailingStorageAccountDeployment" -ResourceGroupName $groupName -TemplateFile "template.storageaccountcmk.bicep"
        ```

    * It's expected to get a [policy violation error](../media/policy-violation.png), which is enforced by SLZ policies of not allowing nonconfidential services into subscriptions located in confidential management groups.
    * Clean up this test by removing the test resource group:

        ``` powershell
            Remove-AzResourceGroup -Name $groupName
        ```

1. Explore the SLZ Dashboard compliance for your subscription, which has the sovereign workload application deployed
    * Navigate to your SLZ Dashboard. The Sovereign Landing Zone Compliance Dashboard  can be accessed in the Dashboards section of the Azure portal. The naming convention follows the pattern ${parDeploymentPrefix}-Sovereign-Landing-Zone-Dashboard-${parDeploymentLocation}, utilizing the parameters provided during SLZ deployment.
    * Notice that the `Overall resources compliance rate` and `Overall confidential compliance score` have changed as you have deployed a confidential application, which is compliant with `SLZ Confidential Policies`, which can be found under `Confidential Corp` confidential policies. See [image](../media/slz-compliance-dashboard.png) for details.


## Next step

* Continue with [Clean up resources](06-cleanup-resources.md)
