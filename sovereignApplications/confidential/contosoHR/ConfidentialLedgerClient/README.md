# Confidential Ledger Client

This tool connects to an Azure Confidential Ledger and retrieves and prints the contents of all entries under the "ContosoHrSqlLogs" collection.

## Prerequisites

To build and run this CLI client you need the .NET 6 SDK installed, which you can download from the [.NET website](https://dotnet.microsoft.com/download/dotnet). Alternatively, if you are on a machine that has the Windows Package Manager (winget), you can install it through a one-line command:

```
winget install Microsoft.DotNet.SDK.6
```

> [!NOTE]
> After installing .NET you may need to close and reopen any terminal windows, to ensure your PATH is updated to include the `dotnet` command.

### ADO Users

If you downloaded this code from a source that enforces the use of a particular nuget package stream and if you must authenticate to access that package stream (e.g., Azure DevOps), you may need to take additional steps to successfully build the client.

1. Install the *Azure Artifacts Credential Provider* as follows:
    ``` powershell
    iex "& { $(irm https://aka.ms/install-artifacts-credprovider.ps1) }"
    ```
2. 
3. Restore your project with the `--interactive` flag and go through the browser-based authentication flow to generate a token granting access to the package stream:
    ```
    dotnet restore --interactive
    ```
4. Note that this login is used to access the package stream; it may be different from the login subsequently used to read the ledger.

## Usage

Connect to the Azure subscription that contains the ledger you want to read, then run the client with the name of the ledger as the only argument:

```
Connect-AzAccount -Subscription <SubscriptionId>
dotnet run <LedgerName>
```

## Known issue

The `ConfidentialLedger.ConfidentialLedgerClient` will occasionally fail to connect to the ledger due to an SSL connection issue that is as yet unresolved. If this happens, retries often work.