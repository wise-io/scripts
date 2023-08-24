<#
  .SYNOPSIS
    Installs QuickBooks ToolHub
  .EXAMPLE
    InstallQuickBooksToolHub.ps1 -Cache "\\SERVER\QuickBooks\Installers"
  .PARAMETER Cache
    Directory path to QuickBooks ToolHub installer. If not provided, installer will be downloaded from Intuit.
  .NOTES
    Author: Aaron J. Stevenson
#>
param([String]$Cache)

Function Confirm-SystemCheck {
  $CurrentUserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
  if ($CurrentUserSID -eq 'S-1-5-18') {
    Write-Warning 'This script cannot run as SYSTEM. Please run as admin.'
    exit 1
  }
}
Function Install-ToolHub {
  $ToolHubURL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/QBFDT/QuickBooksToolHub.exe'
  $Exe = ($ToolHubURL -Split '/')[-1]
  $Installer = Join-Path -Path $env:TEMP -ChildPath $Exe
  if (Test-Path ("$Cache\$Exe")) { $CacheInstaller = Join-Path -Path $Cache -ChildPath $Exe }

  try {
    if ($CacheInstaller) {
      Write-Output "`nCopying ToolHub installer from cache..."
      Copy-Item -Path $CacheInstaller -Destination $Installer
    }
    else {
      Write-Output "`nDownloading ToolHub installer..."
      Invoke-WebRequest -Uri $ToolHubURL -OutFile $Installer
    }
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/S /v/qn'
    Write-Output 'Installation complete.'
  }
  catch {
    Write-Warning 'Error installing ToolHub:'
    Write-Warning $_
  }
  finally { Remove-Item $Installer -Force -ErrorAction Ignore }

}

# Abort if running as SYSTEM
Confirm-SystemCheck

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Format parameters
if ($Cache) { $Cache = $Cache.TrimEnd('\') }

# Install ToolHub
Install-ToolHub
