<#
  .SYNOPSIS
    Installs or updates to the latest PowerShell 7 release.
  .NOTES
    Author: Aaron Stevenson
    Date: 7/20/2023
#>
function Get-DownloadURL {
  param(
    [Parameter(Mandatory = $true)][String]$Repo,
    [Parameter(Mandatory = $true)][String]$Extension
  )
  
  # Get OS Architecture
  if ([System.Environment]::Is64BitOperatingSystem) { $OSArch = 'x64' } else { $OSArch = 'x86' }
  
  $RepoURL = "https://api.github.com/repos/$Repo/releases/latest"
  $DownloadURLs = (Invoke-RestMethod -Uri $RepoURL -UseBasicParsing).assets.browser_download_url | Where-Object { $_.EndsWith("$Extension") }
  $Script:DownloadURL = $DownloadURLs | Where-Object { $_ -like ("*$OSArch*" + "$Extension" ) }
}
function Get-InstalledVersion {
  param([Parameter(Mandatory = $true)][String]$AppName)

  $RegPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )

  $App = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "$AppName*" } | Select-Object
  if ($App) { $Script:InstalledVersion = $App[-1].DisplayVersion }
}
function Install-PowerShell {
  $PackageName = Split-Path $Script:DownloadURL -Leaf
  $PackagePath = "$env:TEMP\$PackageName"
  $ArgumentList = @(
    '/i',
    "$PackagePath",
    '/quiet',
    'ADD_PATH=1',
    'REGISTER_MANIFEST=1',
    'USE_MU=1',
    'ENABLE_MU=1'
  )

  try {
    Invoke-WebRequest -Uri $Script:DownloadURL -OutFile $PackagePath
    Start-Process msiexec -ArgumentList $ArgumentList -Wait
  }
  catch {
    Write-Warning "Unable to install PowerShell [$Script:LatestVersion]."
    Write-Warning $_
    exit 1
  }
  finally { Remove-Item -Path $PackagePath -Force -ErrorAction SilentlyContinue }
}

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Set PowerShell to TLS 1.2 (https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/)
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Get-DownloadURL -Repo 'powershell/powershell' -Extension '.msi'
Get-InstalledVersion -AppName 'PowerShell'
$Script:LatestVersion = if ($Script:DownloadURL -match '\/v(\d*\.\d*\.\d*)\/') { $matches[1] }

if ($Script:InstalledVersion -lt $Script:LatestVersion) {
  Write-Output "`nInstalling PowerShell [$LatestVersion]..."
  Install-PowerShell
  Write-Output 'Installation complete.'
}
else { Write-Output "`nPowerShell [$Script:InstalledVersion] installed and up to date." }
