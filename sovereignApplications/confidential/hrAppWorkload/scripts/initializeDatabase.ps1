# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script initializes database which is called by hrAppWorkload.ps1.
.DESCRIPTION
- Executes the individual modules - hr app sample workload

Prerequisites:

Connect-AzAccount -Subscription %SUBSCRIPTION_ID%
Add-SqlAzureAuthenticationContext -Interactive
#>

Param(
    [Parameter(Mandatory=$True,Position=0)]
    [String] $parResourceGroupName,
    [Parameter(Mandatory=$True,Position=1)]
    [String] $parAttestationProviderName,
    [Parameter(Mandatory=$True,Position=2)]
    [String] $parSqlServerName,
    [Parameter(Mandatory=$True,Position=3)]
    [String] $parSqlDatabaseName,
    [Parameter(Mandatory=$True,Position=4)]
    [String] $parSqlAdminUser,
    [Parameter(Mandatory=$True,Position=5)]
    [String] $parSqlAdminPassword,
    [Parameter(Mandatory=$True,Position=6)]
    [String] $parVmServicePrincipalName,
    [Parameter(Mandatory=$True,Position=7)]
    [String] $parColumnMasterKeyUrl
)

$erroractionPreference = "Stop"

Write-Information ">>> Waiting 3 minutes for Azure DNS propagation to take place." -InformationAction Continue
Start-Sleep -Seconds 180

try {
    # Load required PS modules
    Import-Module Az.Attestation
    Import-Module SqlServer

    # Configure attestation provider policy
    Write-Information ">>> Setting Attestation Provider policy." -InformationAction Continue
    $varPolicyFile = "../../../../common/attestationpolicy.txt"
    $varTeeType = "SgxEnclave"
    $varPolicyFormat = "Text"
    $varPolicy=Get-Content -path $varPolicyFile -Raw
    Set-AzAttestationPolicy -Name $parAttestationProviderName `
     -ResourceGroupName $parResourceGroupName `
     -Tee $varTeeType `
     -Policy $varPolicy `
     -PolicyFormat  $varPolicyFormat

    # SQL server details
    $varSqlServerFQDN="${parSqlServerName}.database.windows.net"
    $varDbConnectionString="Server=tcp:$varSqlServerFQDN,1433;Initial Catalog=$parSqlDatabaseName;Persist Security Info=False;Column Encryption Setting = Enabled;User ID=$parSqlAdminUser;Password=$parSqlAdminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

    # Assign database read access to the VM service principal identity
    # New AAD users can only be added by the AAD admin, so we get a token for that user first
    Write-Information ">>> Adding database user for CVM service principal." -InformationAction Continue
    $varAccessToken=(Get-AzAccessToken -ResourceUrl https://database.windows.net/).Token
    $varParams = @{
        'Database' = $parSqlDatabaseName
        'ServerInstance' = $varSqlServerFQDN
        'AccessToken' = $varAccessToken
        'Query' = "CREATE USER [$parVmServicePrincipalName] FROM EXTERNAL PROVIDER; ALTER ROLE db_owner ADD MEMBER [$parVmServicePrincipalName];"
    }
    Invoke-Sqlcmd @varParams

    # Create schema
    Write-Information ">>> Creating database schema." -InformationAction Continue
    $varParams = @{
        'ConnectionString' = $varDbConnectionString
        'Query' = "CREATE SCHEMA [HR];"
    }
    Invoke-Sqlcmd @varParams

    # Create table
    Write-Information ">>> Creating database table." -InformationAction Continue
    $varParams = @{
        'ConnectionString' = $varDbConnectionString
        'InputFile' = "../../contosoHR/data/schema.sql"
    }
    Invoke-Sqlcmd @varParams

    # Upload data
    Write-Information ">>> Uploading database contents." -InformationAction Continue
    $varParams = @{
        'ConnectionString' = $varDbConnectionString
        'InputFile' = "../../contosoHR/data/data.sql"
    }
    Invoke-Sqlcmd @varParams

    # Generate CMK settings using key from key vault
    $keyVaultAccessToken = (Get-AzAccessToken -ResourceUrl https://vault.azure.net).Token
    $varCmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $parColumnMasterKeyUrl -AllowEnclaveComputations -KeyVaultAccessToken $keyVaultAccessToken

    # Provision CMK and CEK to SQL Server
    Write-Information ">>> Provisioning Always Encrypted keys." -InformationAction Continue
    $Database = Get-SqlDatabase -ConnectionString $varDbConnectionString
    New-SqlColumnMasterKey -Name "CMK1" -InputObject $Database -ColumnMasterKeySettings $varCmkSettings
    New-SqlColumnEncryptionKey -Name "CEK1" -InputObject $Database -ColumnMasterKey "CMK1" -KeyVaultAccessToken $keyVaultAccessToken

    # Encrypt the selected columns
    Write-Information ">>> Encrypting SSN and Salary columns." -InformationAction Continue
    $CES = @()
    $CES += New-SqlColumnEncryptionSettings -ColumnName "HR.Employees.SSN" -EncryptionType "Randomized" -EncryptionKey "CEK1"
    $CES += New-SqlColumnEncryptionSettings -ColumnName "HR.Employees.Salary" -EncryptionType "Randomized" -EncryptionKey "CEK1"
    Set-SqlColumnEncryption -InputObject $Database -ColumnEncryptionSettings $CES -UseOnlineApproach -LogFileDirectory . -KeyVaultAccessToken $keyVaultAccessToken

    Write-Information ">>> Database initialization complete." -InformationAction Continue
}
catch {
    $errorMessage = ""
    $exception = $_.Exception.ToString()
    if ($null -ne $exception) {
        $errorMessage = $exception
    }
    else {
        $errorMessage = $error[0].ToString()
    }

    throw $errorMessage
}
