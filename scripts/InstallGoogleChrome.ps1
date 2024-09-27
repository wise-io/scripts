<#
  .SYNOPSIS
    Installs Google Chrome
  .DESCRIPTION
    Downloads and installs the latest version of Google Chrome silently.
  .NOTES
    Author: Aaron J. Stevenson
#>

$DownloadURL = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise.msi'
$Installer = Join-Path -Path $env:TEMP -ChildPath ($DownloadURL -Split '/')[-1]

function Get-InstallStatus {
  param(
    [Parameter(Mandatory = $true)]
    [String]$Name
  )

  $RegPaths = (
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )

  # Wait for registry to update
  Start-Sleep -Seconds 5

  $Program = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -match $Name } | Select-Object
  if ($Program) { Write-Output "`nInstalled $Name [$($Program.DisplayVersion)]" }
  else { Write-Warning "`n$Name not detected." }
}

function Install-GoogleChrome {
  
  # Adjust download URL
  if ([Environment]::Is64BitOperatingSystem) { 
    $DownloadURL = $DownloadURL.Replace('.msi', '64.msi') 
  }
  
  # Installer Arguments
  $ArgumentList = @(
    '/i',
    "$Installer",
    '/quiet'
  )

  try {
    Write-Output "`nDownloading Google Chrome..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer
    Write-Output 'Installing...'
    Start-Process -Wait msiexec -ArgumentList $ArgumentList
    Get-InstallStatus 'Google Chrome'
  }
  catch { 
    Write-Warning 'There was an issue installing Google Chrome.'
    Write-Warning $_
  }
  finally { 
    Remove-Item $Installer -Force -ErrorAction Ignore
    exit $LASTEXITCODE
  }
}

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Install-GoogleChrome
