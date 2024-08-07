<#
  .SYNOPSIS
    Windows 11 Update Installer
  .DESCRIPTION
    This script downloads and silently executes the Windows 11 Installation Assistant to install the latest Windows 11 Feature Update.
    Logs for the upgrade process will be redirected to $Logs. For Installation Asssistant Logs:
    https://learn.microsoft.com/en-us/windows/deployment/upgrade/log-files
  .NOTES
    Author: Aaron J. Stevenson
#>

$DownloadURL = 'https://go.microsoft.com/fwlink/?linkid=2171764' 

$Path = "$env:SystemDrive\W11Upgrade"
$Logs = Join-Path -Path $Path -ChildPath 'Logs'
$Installer = Join-Path -Path $Path -ChildPath 'Windows11InstallationAssistant.exe'

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Create directories
if (!(Test-Path $Path -PathType Container)) {
  New-Item $Path -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}

if (!(Test-Path $Logs -PathType Container)) {
  New-Item $Logs -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}

# Download Installation Assistant
try { 
  Write-Output 'Downloading Windows 11 Installation Assistant...'
  Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer 
}
catch {
  Write-Error 'Could not download the Installation Assistant.'
  Exit 1
}

# Run Installation Assistant
try { 
  Write-Output 'Running Installation Assistant...'
  $Arguments = @('/quietinstall', '/skipeula', '/auto', 'upgrade', '/copylogs', $Logs)
  Start-Process -FilePath $Installer -ArgumentList $Arguments -Wait -NoNewWindow 
}
catch {
  Write-Error 'The Windows 11 Installation Assistant failed.'
  Exit 1
}
