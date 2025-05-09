<#
  .SYNOPSIS
    Installs Keeper Password Manager
  .DESCRIPTION
    Silently installs the latest Keeper Password Manager desktop application for the logged in user
  .LINK
    https://docs.keeper.io/en/enterprise-guide/deploying-keeper-to-end-users/desktop-application
  .NOTES
    Author: Aaron Stevenson
#>

$Installer = "$env:TEMP\KeeperPasswordManager.appinstaller"
$DownloadURL = 'https://www.keepersecurity.com/desktop_electron/packages/KeeperPasswordManager.appinstaller'

# Adjust Powershell Settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
  # Check for existing install
  $Installed = Get-AppxPackage -Name 'KeeperSecurityInc.KeeperPasswordManager'
  if ($Installed) {
    Write-Output "`nKeeper Password Manager [$($Installed.Version)] already installed for user $env:USERNAME"
    exit 0
  }

  # Download
  Write-Output "`nDownloading Keeper Password Manager..."
  Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer

  # Install
  Write-Output 'Installing...'
  Add-AppxPackage -AppInstallerFile $Installer
  
  # Confirm Installation
  $Installed = Get-AppxPackage -Name 'KeeperSecurityInc.KeeperPasswordManager'
  if ($Installed) { Write-Output "Successfully installed Keeper Password Manager [$($Installed.Version)]" }
  else { throw }
}
catch { Write-Warning 'Error installing Keeper Password Manager' }
finally { 
  Remove-Item -Path $Installer -Force -ErrorAction SilentlyContinue
  exit $LASTEXITCODE
}
