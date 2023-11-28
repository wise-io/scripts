<#
  .SYNOPSIS
    Installs Dell updates via Dell Command Update
  .DESCRIPTION
    Installs the latest version of Dell Command Update and runs/applies all Dell updates silently.
  .LINK
    https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg
  .NOTES
    Author: Aaron J. Stevenson
#>

function Invoke-PreinstallChecks {
  # Check PC manufacturer
  if ((Get-WmiObject win32_bios).Manufacturer -notlike '*Dell*') {
    Write-Output 'Not a Dell system. Aborting...'
    exit 0
  }
  
  # Check for incompatible products
  $RegPaths = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
  $IncompatibleApps = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like 'Dell Update*' } | Select-Object
  foreach ($IncompatibleApp in $IncompatibleApps) {
    Write-Output "Attempting to remove program: [$($IncompatibleApp.DisplayName)]"
    try {
      $Null = cmd /c $IncompatibleApp.UninstallString /quiet
      Write-Output "Successfully removed package: [$($IncompatibleApp.DisplayName)]"
    }
    catch { 
      Write-Warning "Failed to remove provisioned package: [$($IncompatibleApp.DisplayName)]"
      Write-Warning $_
      exit 1
    }
  }
}

function Get-DownloadURL {
  $DellURL = 'https://www.dell.com/support/kbdoc/en-us/000177325/dell-command-update'
  $Headers = @{ 'accept' = 'text/html' }
  [String]$DellWebPage = Invoke-RestMethod -UseBasicParsing -Uri $DellURL -Headers $Headers
  if ($DellWebPage -match '(https://www\.dell\.com.*driverId=[a-zA-Z0-9]*)') { 
    $DownloadPage = Invoke-RestMethod -UseBasicParsing -Uri $Matches[1] -Headers $Headers
    if ($DownloadPage -match '(https://dl\.dell\.com.*Dell-Command-Update.*\.EXE)') { $Matches[1] }
  }
}

function Install-DCU {
  $DownloadURL = Get-DownloadURL
  $Installer = "$env:temp\dcu-setup.exe"
  $Version = $DownloadURL | Select-String '[0-9]*\.[0-9]*\.[0-9]*' | ForEach-Object { $_.Matches.Value }
  $AppName = 'Dell Command | Update for Windows Universal'
  $App = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like $AppName } | Select-Object
  if ($App.DisplayVersion -ne $Version) {
    Write-Output "Installing Dell Command Update: [$Version]"
    try {
      Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
      cmd /c $Installer /s
    }
    catch { 
      Write-Warning 'Unable to install Dell Command Update.'
      Write-Warning $_
      exit 1
    }

    # Check for DCU CLI
    if (Test-Path $DCU) { Write-Output "Dell Command Update [$Version] installed." }
    else {
      Write-Warning 'Dell Command Update CLI was not detected.'
      exit 1
    }
  }
}

function Invoke-DCU {
  try {
    cmd /c "$DCU" /configure -updatesNotification=disable -userConsent=disable -scheduleAuto -silent
    cmd /c "$DCU" /scan -silent
    cmd /c "$DCU" /applyUpdates -autoSuspendBitLocker=enable -reboot=disable
  }
  catch {
    Write-Warning 'Unable to apply updates using the dcu-cli.'
    Write-Warning $_
    exit 1
  }
}

$DCU = (Resolve-Path "$env:SystemDrive\Program Files*\Dell\CommandUpdate\dcu-cli.exe").Path

# Set PowerShell preferences
Set-Location -Path $env:SystemRoot
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Invoke-PreinstallChecks
Install-DCU
Invoke-DCU
