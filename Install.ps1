<#
.SYNOPSIS
    Installs the System Security Studio or App Control Studio MSIX Bundle with a self-signed certificate.

.DESCRIPTION
    This script automates the installation process for self-signed MSIX packages.
    1. Checks for Administrator privileges (auto-elevates if needed).
    2. Installs the included 'OFFSECHQ_CodeSigning.cer' to the Trusted People store.
    3. Finds the .msixbundle in the same directory and installs it.

.NOTES
    Author: OFFSECHQ
#>

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$ErrorActionPreference = 'Stop'
$ScriptPath = $PSScriptRoot

Write-Host "=== System Security Studio Installer ===" -ForegroundColor Cyan

# 1. Install Certificate
$CertPath = Join-Path $ScriptPath "OFFSECHQ_CodeSigning.cer"

if (Test-Path $CertPath) {
    Write-Host "Installing Code Signing Certificate..." -ForegroundColor Yellow
    try {
        Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null
        Write-Host "Certificate installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install certificate: $_"
        Read-Host "Press Enter to exit..."
        Exit
    }
}
else {
    Write-Warning "Certificate 'OFFSECHQ_CodeSigning.cer' not found in script directory. Attempting installation anyway (will fail if not already trusted)."
}

# 2. Find and Install MSIX Bundle
$BundlePath = Get-ChildItem -Path $ScriptPath -Filter "*.msixbundle" | Select-Object -First 1

if ($null -eq $BundlePath) {
    Write-Error "No .msixbundle file found in the script directory."
    Read-Host "Press Enter to exit..."
    Exit
}

Write-Host "Found package: $($BundlePath.Name)" -ForegroundColor Cyan
Write-Host "Installing..." -ForegroundColor Yellow

try {
    Add-AppxPackage -Path $BundlePath.FullName -ForceUpdateFromAnyVersion
    Write-Host "`nInstallation Successful! You can now launch the app from the Start Menu." -ForegroundColor Green
}
catch {
    Write-Error "`nInstallation Failed: $_"
    Write-Host "`nTip: Attempting to use ForceApplicationShutdown..." -ForegroundColor Gray
    try {
        Add-AppxPackage -Path $BundlePath.FullName -ForceUpdateFromAnyVersion -ForceTargetApplicationShutdown
        Write-Host "Installation Successful (on retry)!" -ForegroundColor Green
    }
    catch {
        Write-Error "Installation Failed again: $_"
    }
}

Read-Host "Press Enter to exit..."
