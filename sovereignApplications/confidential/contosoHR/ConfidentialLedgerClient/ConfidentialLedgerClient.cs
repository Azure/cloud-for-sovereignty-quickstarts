// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using Azure.Identity;
using Azure.Security.ConfidentialLedger;
using System.Text.Json;

/// <summary>
/// This tool connects to an Azure Confidential Ledger.
/// And retrieves logs under the "ContosoHrSqlLogs" collection.
/// </summary>

if (args.Length != 1)
{
    Console.WriteLine("Usage: dotnet run <LedgerName>");
    Environment.Exit(1);
}

string ledgerName = args[0];
var ledgerUri = $"https://{ledgerName}.confidential-ledger.azure.com";
var ledgerClient = new ConfidentialLedgerClient(new Uri(ledgerUri), new DefaultAzureCredential());

await foreach (var data in ledgerClient.GetLedgerEntriesAsync("ContosoHrSqlLogs"))
{
    JsonElement result = JsonDocument.Parse(data.ToStream()).RootElement;
    Console.WriteLine(result.GetProperty("contents").ToString());
}
