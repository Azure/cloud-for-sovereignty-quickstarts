# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
<#
.SYNOPSIS
This PowerShell script installs the required softwares in the admin virtual machine.

.DESCRIPTION
- Executes the individual modules to install required softwares in the admin virtual machine.

#>

# Install Powershell modules
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Install-PackageProvider -Name NuGet -Force -Scope AllUsers
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber -Scope AllUsers
Install-Module -Name SQLServer -Repository PSGallery -Force -Scope AllUsers

# Turn off (SLOW) Invoke-WebRequest progress bar
$ProgressPreference = 'SilentlyContinue'

# Download Bicep binary
$bicepInstallDir = $Env:Programfiles + "\Bicep\"
New-Item -ItemType Directory -Path $bicepInstallDir -Force
Invoke-WebRequest -UseBasicParsing "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe" -OutFile "$bicepInstallDir\bicep.exe";

# Add Bicep to PATH
$path = [Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';' |
        Where-Object { $_ -ne $bicepInstallDir }
$path += $bicepInstallDir
$newPath = $path -join ';'
$regkey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
Set-ItemProperty -Path $regkey -Name 'Path' -Value $newPath -Type ExpandString

# Download Git installer to temp folder and execute quietly
$GitInstallerPath = $env:TEMP + "\Git-2.40.0-64-bit.exe"
Invoke-WebRequest -UseBasicParsing "https://github.com/git-for-windows/git/releases/download/v2.40.0.windows.1/Git-2.40.0-64-bit.exe" -OutFile $GitInstallerPath
Start-Process -FilePath $GitInstallerPath -ArgumentList "/verysilent /norestart" -Wait

# Download SSMS installer to temp folder and execute quietly
$SsmsInstallerPath = $env:TEMP + "\SSMS-Setup-ENU.exe"
Invoke-WebRequest -UseBasicParsing "https://aka.ms/ssmsfullsetup" -OutFile $SsmsInstallerPath
Start-Process -FilePath $SsmsInstallerPath -ArgumentList "/install /quiet /norestart" -Wait
