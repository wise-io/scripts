<#
  .SYNOPSIS
    Installs Dell updates via Dell System Update
  .DESCRIPTION
    Installs the latest version of Dell System Update and runs/applies all Dell updates silently.
  .LINK
    https://www.dell.com/support/home/en-in/product-support/product/system-update/docs
  .NOTES
    Author: Aaron J. Stevenson
#>

function Invoke-PreinstallChecks {
  # Check PC manufacturer
  if ((Get-WmiObject win32_bios).Manufacturer -notlike '*Dell*') {
    Write-Output 'Not a Dell system. Aborting...'
    exit 0
  }
}

function Get-DownloadURL {
  $DellURL = 'https://www.dell.com/support/kbdoc/en-us/000130590/dell-emc-system-update-dsu'
  $Headers = @{
    'accept'          = 'text/html'
    'accept-encoding' = 'gzip, deflate, br, zstd'
    'accept-language' = '*'
  }
  [String]$DellWebPage = Invoke-RestMethod -UseBasicParsing -Uri $DellURL -Headers $Headers
  if ($DellWebPage -match '(https://www\.dell\.com[a-zA-Z0-9\/\-\?]*driverid=[a-zA-Z0-9]*)') { 
    $DownloadPage = Invoke-RestMethod -UseBasicParsing -Uri $Matches[1] -Headers $Headers
    if ($DownloadPage -match '(https://dl\.dell\.com.*Systems-Management_Application.*\.EXE)') { $Matches[1] }
  }
}

function Get-Version {
  param(
    [Parameter(Mandatory = $true)]
    [String]$Name
  )

  $RegPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )

  # Wait for registry to update
  Start-Sleep -Seconds 5

  $Program = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -match $Name } | Select-Object
  if ($Program) { return $Program.DisplayVersion }
  else { return $null }
}

function Install-DSU {
  $AppName = 'Dell System Update'
  $DownloadURL = Get-DownloadURL
  $Installer = "$env:temp\dsu-setup.exe"
  $Version = $DownloadURL | Select-String '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*' | ForEach-Object { $_.Matches.Value }
  
  if ((Get-Version -Name $AppName) -ne $Version) {
    try {
      Write-Output "`nDownloading $AppName..."
      Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
      Write-Output 'Installing...'
      Start-Process -Wait -FilePath $Installer -ArgumentList '/s'
      if ((Get-Version -Name $AppName) -eq $Version) { Write-Output "Installed $AppName [$Version]" }
      else { throw }
    }
    catch { 
      Write-Warning "Unable to install $AppName."
      Write-Warning $_
      exit 1
    }
  }
}

function Invoke-DSU {
  # Check for DSU
  $DSU = (Resolve-Path "$env:SystemDrive\Program Files*\Dell\DELL System Update\dsu.exe").Path
  if (!$DSU) {
    Write-Warning "`nUnable to locate DSU executable."
    exit 1
  }
  
  try { 
    Write-Output "`nLaunching Dell System Update to apply updates...`n"
    Start-Process -Wait -FilePath $DSU -ArgumentList '/q /u' -NoNewWindow -PassThru | Out-Null
  }
  catch {
    Write-Warning 'Unable to apply updates using Dell System Update.'
    Write-Warning $_
    exit 1
  }
}

# Set PowerShell preferences
Set-Location -Path $env:SystemRoot
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Invoke-PreinstallChecks
Install-DSU
Invoke-DSU
