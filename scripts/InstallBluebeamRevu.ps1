<#
  .SYNOPSIS
    Installs Bluebeam Revu
  .DESCRIPTION
    Installs the latest version of Bluebeam Revu.
    This script will abort if Bluebeam Revu is currently running (to avoid data loss).
    This script will abort if a perpetually licensed version of Bluebeam Revu is detected.
  .EXAMPLE
    .\InstallBluebeamRevu.ps1
  .NOTES
    Author: Aaron J. Stevenson
#>
function Get-InstalledVersion {
  param([Parameter(Mandatory = $true)][String]$AppName)

  $RegPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )

  $App = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "$AppName*" } | Select-Object
  if ($App) { Return $App[-1].DisplayVersion }
}

function Invoke-PreinstallChecks {
  # Check if running
  $Running = Get-Process 'Revu' -ErrorAction SilentlyContinue
  if ($Running) {
    Write-Warning "`nBluebeam Revu is currently running. Aborting script to avoid data loss..."
    exit 1
  }

  # Version check to avoid updating over non-subscription versions
  if ($OldVersion -and $OldVersion -lt '21') {
    Write-Warning "`nBluebeam Revu $OldVersion is perpetually licensed."
    Write-Warning 'Aborting script due to lack of subscription version...'
    exit 1
  }
}

function Install-BluebeamRevu {
  try {
    Write-Output "`nInstalling Bluebeam Revu..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer
    Start-Process $Installer -ArgumentList '/silent IGNORE_RBT=1' -Wait
    $NewVersion = Get-InstalledVersion -AppName 'Bluebeam Revu'
    if ($NewVersion -gt $OldVersion) { Write-Output "Bluebeam Revu [$NewVersion] successfully installed." }
    else { throw "Encountered unexpected version after installation.`nOld Version: $OldVersion`nNew Version:$NewVersion" }
  }
  catch {
    Write-Warning "`nUnable to install Bluebeam Revu."
    Write-Warning $_
    exit 1
  }
  finally { Remove-Item -Path $Installer -Force -ErrorAction SilentlyContinue }
}

$DownloadURL = 'https://bluebeam.com/FullRevuTRIAL'
$Installer = "$env:TEMP\BluebeamRevu.exe"
$OldVersion = Get-InstalledVersion -AppName 'Bluebeam Revu'

# Adjust PowerShell settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Invoke-PreinstallChecks
Install-BluebeamRevu
