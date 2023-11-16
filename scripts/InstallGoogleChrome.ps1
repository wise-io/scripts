<#
  .SYNOPSIS
    Installs Google Chrome Enterprise
  .DESCRIPTION
    Downloads and installs the latest version of Google Chrome Enterprise silently.
  .NOTES
    Author: Aaron J. Stevenson
#>

$DownloadURL = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
$Installer = Join-Path -Path $env:TEMP -ChildPath ($DownloadURL -Split '/')[-1]

if ([Environment]::Is64BitOperatingSystem) { 
  $DownloadURL = $DownloadURL.Replace('.msi', '64.msi') 
}

# Installer Arguments
$ArgumentList = @(
  '/i',
  "$Installer",
  '/quiet'
)

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
  Write-Output "`nDownloading Google Chrome..."
  Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer
  Write-Output 'Installing Google Chrome...'
  Start-Process -Wait msiexec -ArgumentList $ArgumentList
  Write-Output 'Installation complete.'
}
catch { 
  Write-Warning 'There was an issue installing Google Chrome Enterprise.'
  Write-Warning $_
}
finally { 
  Remove-Item $Installer -Force -ErrorAction Ignore
  exit $LASTEXITCODE
}
