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
$RegPaths = (
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

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

function Install-TSPrintClient {
  try {
    Write-Output "`nDownloading TSPrint Client..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer
  
    Write-Output 'Installing...'
    Start-Process -Wait $Installer -ArgumentList '/VERYSILENT /NORESTART'
  
    # Check for TSPrint Client
    $TSPrintClient = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like 'TSPrint Client' } | Select-Object
    if ($TSPrintClient) { Write-Output "TSPrint Client [$($TSPrintClient.DisplayVersion)] successfully installed." }
    else { Write-Warning 'TSPrint Client not detected after install.' }
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

# Adjust PowerShell Settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Stop-RDP
Install-TSPrintClient
