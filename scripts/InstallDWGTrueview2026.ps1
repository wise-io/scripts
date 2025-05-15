<#
  .SYNOPSIS
    Installs DWG TrueView 2026
  .DESCRIPTION
    Downloads and installs Autodesk DWG TrueView 2026 silently
  .LINK
    https://www.autodesk.com/products/dwg-trueview/overview
  .NOTES
    Author: Aaron J. Stevenson
#>

function Get-DownloadURL {

  $TokenEndpoint = 'https://wingman.delivery.autodesk.com/tokenService/cfpFreeToken'
  $DownloadEndpoint = 'https://webinstl.delivery.autodesk.com/webinstall3/webInstallerService/installer/si/v5'

  # Get request auth token
  $Token = (Invoke-RestMethod -Method GET -Uri $TokenEndpoint).access_token

  # Set request headers
  $Headers = @{
    'authorization'   = $Token
    'accept'          = 'application/json, text/plain, */*'
    'accept-encoding' = 'gzip, deflate, br, zstd'
    'content-type'    = 'application/json'
  }  

  # Set request body
  $Body = @'
{"serverParams":{"paramsString":[{"id":"directUrl","options":[{"id":"directUrl","value":"https://efulfillment.autodesk.com/NetSWDLD/ODIS/prd/2026/PLC0000037/C4DAD0F5-FFEB-347F-A10C-AF39031457C9/SFX/DWGTrueView_2026_English_64bit_db_001_002.exe"}]},{"id":"url","options":[{"id":"url","value":"https://efulfillment.autodesk.com/NetSWDLD/ODIS/prd/2026/PLC0000037/C4DAD0F5-FFEB-347F-A10C-AF39031457C9/WI/Autodesk_DWG_TrueView_2026_en-US_setup.dat"}]},{"id":"productLang","options":[{"id":"productLang","value":"en-US"}]},{"id":"sid","options":[{"id":"sid","value":"SESSION_ID"}]},{"id":"skipEULA","options":[{"id":"skipEULA","value":true}]},{"id":"akamai","options":[{"id":"akamai","value":true}]},{"id":"product","options":[{"id":"upi2","value":"{C4DAD0F5-FFEB-347F-A10C-AF39031457C9}"},{"id":"displayName","value":"DWG TrueView"},{"id":"prodLangId","value":"EINT"}]},{"id":"PLC","options":[{"id":"plc","value":"PLC0000037"}]},{"id":"VERSION","options":[{"id":"version","value":"2026"}]}],"nonce":"898887d2-4814-4313-8621-3b998b4156c8","timestamp":"2025-04-29T07:59:37Z"},"clientParams":{"selections":[{"paramId":"skipEULA","isSet":true},{"paramId":"skipPI"},{"paramId":"skipWC"},{"paramId":"skipWCTools"},{"paramId":"akamai","isSet":true},{"paramId":"Clic"}],"params":[{"id":"platform","value":"win"}]},"state":"live"}
'@

  $DownloadURL = (Invoke-RestMethod -Method POST -Uri $DownloadEndpoint -Headers $Headers -Body $Body).webInstallServiceResponse.url.Split('?')[0]

  return $DownloadURL
}

function Get-InstalledApps {
  param(
    [Parameter(Mandatory)][String[]]$DisplayNames
  )
    
  $RegPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )
    
  # Get applications matching criteria
  $Apps = @()
  foreach ($DisplayName in $DisplayNames) {
    $Apps += Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
  }
  
  return $Apps
}

function Install-DWGTrueview {
  # Set variables
  $AppName = 'Autodesk DWG TrueView 2026'
  $DownloadURL = Get-DownloadURL
  $Installer = Join-Path -Path $env:TEMP -ChildPath 'dwgtrueview-webinstall.exe'
  $Err = 0

  try {
    # Check for existing install
    $Installed = Get-InstalledApps $AppName
    if ($Installed) {
      Write-Output "`n$($Installed.DisplayName) [$($Installed.DisplayVersion)] already installed"
      exit $Err
    }
    
    # Download package
    Write-Output "`n$AppName not detected - Downloading..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer

    # Set installer path and install
    Write-Output 'Installing...'
    cmd /c $Installer -q # Installer seems to hang when using start-process 

    # Confirm install
    $Installed = Get-InstalledApps $AppName
    if ($Installed) { Write-Output "Successfully installed $($Installed.DisplayName) [$($Installed.DisplayVersion)]" }
    else { throw }
  }
  catch {
    Write-Warning "There was an issue installing DWG Trueview.`n$_"
    $Err = 1
  }
  finally { 
    Remove-Item $Installer -Force -ErrorAction Ignore
    exit $Err
  }
}

# Set PowerShell preferences
Set-Location -Path $env:SystemRoot
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Install DWG Trueview
Install-DWGTrueview
