<#
  .SYNOPSIS
    Installs Zoom Workplace
  .DESCRIPTION
    Silently installs the latest Zoom Workplace client from Zoom.
  .EXAMPLE
    ./InstallZoom.ps1
  .NOTES
    Author: Aaron Stevenson
#>

$Installer = "$env:temp\ZoomInstallerFull.msi"
$DownloadURL = 'https://www.zoom.us/client/latest/ZoomInstallerFull.msi'

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

function Install-Zoom {

  # Set Installer Arguments
  $ArgumentList = @(
    '/i',
    $Installer,
    'ALLUSERS=1',
    '/quiet',
    '/qn',
    '/norestart',
    'ZoomAutoUpdate="true"',
    'zNoDesktopShortCut=True'
  )

  try {
    # Adjust URL for OS Architecture
    $ArchType = if ([System.Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    if ($ArchType -eq 'x64') { $DownloadURL = $DownloadURL + '?archType=x64' }

    # Download Zoom
    Write-Output "`nDownloading Zoom Workplace ($ArchType)..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer

    # Install Zoom
    Write-Output 'Installing...'
    Start-Process -Wait msiexec.exe -ArgumentList $ArgumentList
    Get-InstallStatus 'Zoom Workplace'
  }
  catch { Write-Warning 'Unable to install Zoom Workplace.' }
  finally { 
    Remove-Item -Path $Installer -Force -ErrorAction SilentlyContinue
    exit $LASTEXITCODE
  }
}

# Adjust Powershell Settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Install-Zoom
