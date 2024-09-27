<#
  .SYNOPSIS
    Installs TSPrint Client
  .DESCRIPTION
    Silently installs the latest TSPrint Client from Terminalworks.
  .EXAMPLE
    ./InstallTSPrint.ps1
  .NOTES
    Author: Aaron Stevenson
#>

param ([switch]$Force)

$DownloadURL = 'https://www.terminalworks.com/downloads/tsprint/TSPrint_client.exe'
$Installer = "$env:temp\TSPrint_client.exe"

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

function Install-TSPrintClient {
  try {
    Write-Output "`nDownloading TSPrint Client..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer
  
    Write-Output 'Installing...'
    Start-Process -Wait $Installer -ArgumentList '/VERYSILENT /NORESTART'
    Get-InstallStatus 'TSPrint Client'
  }
  catch {
    Write-Warning 'Unable to install TSPrint Client.'
    Write-Warning $_
  }
  finally { 
    Remove-Item -Path $Installer -Force -ErrorAction SilentlyContinue
    exit $LASTEXITCODE
  }
}

function Stop-RDP {
  # Check for active RDP sessions
  $RDP = Get-Process -Name 'mstsc' -ErrorAction Ignore
  if ($RDP -and $Force) {
    Write-Output "`nTerminating RDP sessions..."
    try { $RDP | Stop-Process }
    catch { 
      Write-Warning 'Unable to terminate active RDP sessions.'
      throw $_
    }
  }
  elseif ($RDP) {
    Write-Output "`nActive RDP sessions detected. Aborting installation."
    exit 1
  }
}

# Adjust PowerShell Settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Stop-RDP
Install-TSPrintClient
