// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
using Azure;
using Azure.Core;
using Azure.Security.ConfidentialLedger;
using System;
using System.Diagnostics;

/// <summary>
/// Send log to confidential ledger.
/// </summary>
namespace ContosoHR.Util
{
    public class ConfidentialLedgerLogger
    {
        readonly string ledgerUri;
        readonly string collectionId;
        readonly ConfidentialLedgerClient ledgerClient;

        public ConfidentialLedgerLogger(string ledgerName, string collectionId, TokenCredential credential)
        {
            ledgerUri = $"https://{ledgerName}.confidential-ledger.azure.com";
            this.collectionId = collectionId;
            ledgerClient = new ConfidentialLedgerClient(new Uri(ledgerUri), credential);
        }

        public void Log(string message)
        {
            RequestContent content = RequestContent.Create(new { contents = message });
            ledgerClient.PostLedgerEntryAsync(WaitUntil.Started, content, collectionId);
            Debug.WriteLine($"Posted the following to {ledgerUri}: \n{message}");
        }
    }
}
