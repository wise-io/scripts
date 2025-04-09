<#
  .SYNOPSIS
    Installs Dell updates via Dell Command Update
  .DESCRIPTION
    Installs the latest version of Dell Command Update and applies all Dell updates silently.
  .LINK
    https://www.dell.com/support/product-details/en-us/product/command-update/resources/manuals
  .NOTES
    Author: Aaron J. Stevenson
#>

function Get-Architecture {
  # On PS x86, PROCESSOR_ARCHITECTURE reports x86 even on x64 systems.
  # To get the correct architecture, we need to use PROCESSOR_ARCHITEW6432.
  # PS x64 doesn't define this, so we fall back to PROCESSOR_ARCHITECTURE.
  # Possible values: amd64, x64, x86, arm64, arm
  if ($null -ne $ENV:PROCESSOR_ARCHITEW6432) { $Architecture = $ENV:PROCESSOR_ARCHITEW6432 }
  else {     
    if ((Get-CimInstance -ClassName CIM_OperatingSystem -ErrorAction Ignore).OSArchitecture -like 'ARM*') {
      if ( [Environment]::Is64BitOperatingSystem ) { $Architecture = 'arm64' }  
      else { $Architecture = 'arm' }
    }

    if ($null -eq $Architecture) { $Architecture = $ENV:PROCESSOR_ARCHITECTURE }
  }

  switch ($Architecture.ToLowerInvariant()) {
    { ($_ -eq 'amd64') -or ($_ -eq 'x64') } { return 'x64' }
    { $_ -eq 'x86' } { return 'x86' }
    { $_ -eq 'arm' } { return 'arm' }
    { $_ -eq 'arm64' } { return 'arm64' }
    default { throw "Architecture '$Architecture' not supported." }
  }
}

function Get-InstalledApp {
  param([Parameter(Mandatory)][String]$DisplayName)
  $RegPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )
  
  # Check for bundled version property
  $App = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" -and $null -ne $_.BundleVersion }
  if ($App) { return $App }
  else {
    return Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
  }
}

function Remove-DellUpdate {
  # Check for incompatible products (Dell Update)
  $IncompatibleApps = Get-InstalledApp -DisplayName 'Dell Update'
  foreach ($IncompatibleApp in $IncompatibleApps) {
    Write-Output "Attempting to remove program: [$($IncompatibleApp.DisplayName)]"
    try {
      Start-Process -NoNewWindow -Wait -FilePath $IncompatibleApp.UninstallString -ArgumentList '/quiet'
      Write-Output "Successfully removed $($IncompatibleApp.DisplayName)"
    }
    catch { 
      Write-Warning "Failed to remove $($IncompatibleApp.DisplayName)"
      Write-Warning $_
      exit 1
    }
  }
}

function Install-DellCommandUpdate {
  function Get-LatestDellCommandUpdate {
    # Set KB URL
    $DellKBURL = 'https://www.dell.com/support/kbdoc/en-us/000177325/dell-command-update'
  
    # Set fallback URL based on architecture
    $Arch = Get-Architecture
    if ($Arch -like 'arm*') { $FallbackDownloadURL = 'https://dl.dell.com/FOLDER11914141M/1/Dell-Command-Update-Windows-Universal-Application_6MK0D_WINARM64_5.4.0_A00.EXE' }
    else { $FallbackDownloadURL = 'https://dl.dell.com/FOLDER12925773M/1/Dell-Command-Update-Windows-Universal-Application_P4DJW_WIN64_5.5.0_A00.EXE' }
  
    # Set headers for Dell website
    $Headers = @{
      'accept'          = 'text/html'
      'accept-encoding' = 'gzip'
      'accept-language' = '*'
    }
  
    # Attempt to parse Dell website for download page links of latest DCU
    [String]$DellKB = Invoke-WebRequest -UseBasicParsing -Uri $DellKBURL -Headers $Headers -ErrorAction Ignore
    $LinkMatches = @($DellKB | Select-String '(https://www\.dell\.com.+driverid=[a-z0-9]+).+>Dell Command \| Update Windows Universal Application<\/a>' -AllMatches).Matches
    $KBLinks = foreach ($Match in $LinkMatches) { $Match.Groups[1].Value }
  
    # Attempt to parse Dell website for download URLs for latest DCU
    $DownloadURLs = foreach ($Link in $KBLinks) {
      $DownloadPage = Invoke-WebRequest -UseBasicParsing -Uri $Link -Headers $Headers
      if ($DownloadPage -match '(https://dl\.dell\.com.+Dell-Command-Update.+\.EXE)') { $Matches[1] }
    }
  
    # Set download URL based on architecture
    if ($Arch -like 'arm*') { $DownloadURL = $DownloadURLs | Where-Object { $_ -like '*winarm*' } }else { $DownloadURL = $DownloadURLs | Where-Object { $_ -notlike '*winarm*' } }
  
    # Revert to fallback URL if unable to retrieve URL from Dell website
    if ($null -eq $DownloadURL) { $DownloadURL = $FallbackDownloadURL }
  
    # Get version from DownloadURL
    $Version = $DownloadURL | Select-String '[0-9]*\.[0-9]*\.[0-9]*' | ForEach-Object { $_.Matches.Value }
  
    return @{
      URL     = $DownloadURL
      Version = $Version
    }
  }
  
  $LatestDellCommandUpdate = Get-LatestDellCommandUpdate
  $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDellCommandUpdate.URL -Leaf)
  $CurrentVersion = (Get-InstalledApp -DisplayName 'Dell Command | Update for Windows Universal').DisplayVersion
  Write-Output "`nInstalled Dell Command Update: $CurrentVersion"
  Write-Output "Latest Dell Command Update: $($LatestDellCommandUpdate.Version)"

  if ($CurrentVersion -lt $LatestDellCommandUpdate.Version) {

    # Download installer
    Write-Output "`nDell Command Update installation needed"
    Write-Output 'Downloading...'
    Invoke-WebRequest -Uri $LatestDellCommandUpdate.URL -OutFile $Installer -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)

    # Install .NET
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/s'

    # Confirm installation
    $CurrentVersion = (Get-InstalledApp -DisplayName 'Dell Command | Update for Windows Universal').DisplayVersion
    if ($CurrentVersion -match $LatestDellCommandUpdate.Version) {
      Write-Output "Successfully installed Dell Command Update [$CurrentVersion]"
    }
    else {
      Write-Warning "Dell Command Update [$($LatestDellCommandUpdate.Version)] not detected after installation attempt"
      exit 1
    }
  }
  else { 
    Write-Output "`nDell Command Update installation / upgrade not needed"
  }
}

function Install-DotNetDesktopRuntime {
  function Get-LatestDotNetDesktopRuntime {
    $BaseURL = 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop'
    $Version = (Invoke-WebRequest -Uri "$BaseURL/LTS/latest.version" -UseBasicParsing).Content
    $Arch = Get-Architecture
    $URL = "$BaseURL/$Version/windowsdesktop-runtime-$Version-win-$Arch.exe"
  
    $Latest = @{
      URL     = $URL
      Version = $Version
    }
  
    return $Latest
  }
  
  $LatestDotNet = Get-LatestDotNetDesktopRuntime
  $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDotNet.URL -Leaf)
  $CurrentVersion = (Get-InstalledApp -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion
  Write-Output "`nInstalled .NET Desktop Runtime: $CurrentVersion"
  Write-Output "Latest .NET Desktop Runtime: $($LatestDotNet.Version)"
  
  if ($CurrentVersion -lt $LatestDotNet.Version) {
    
    # Download installer
    Write-Output "`n.NET Desktop Runtime installation needed"
    Write-Output 'Downloading...'
    Invoke-WebRequest -Uri $LatestDotNet.URL -OutFile $Installer

    # Install .NET
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/install /quiet /norestart'

    # Confirm installation
    $CurrentVersion = (Get-InstalledApp -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion
    if ($CurrentVersion -match $LatestDotNet.Version) {
      Write-Output "Successfully installed .NET Desktop Runtime [$CurrentVersion]"
    }
    else {
      Write-Warning ".NET Desktop Runtime [$($LatestDotNet.Version)] not detected after installation attempt"
      exit 1
    }
  }
  else { 
    Write-Output "`n.NET Desktop Runtime installation / upgrade not needed"
  }
}

function Invoke-DellCommandUpdate {
  # Check for DCU CLI
  $DCU = (Resolve-Path "$env:SystemDrive\Program Files*\Dell\CommandUpdate\dcu-cli.exe").Path
  if (!$DCU) {
    Write-Warning 'Dell Command Update CLI was not detected.'
    exit 1
  }
  
  try {
    # Configure DCU automatic updates
    Start-Process -NoNewWindow -Wait -FilePath $DCU -ArgumentList '/configure -scheduleAction=DownloadInstallAndNotify -updatesNotification=disable -forceRestart=disable -scheduleAuto -silent'
    
    # Scan for / apply updates
    Start-Process -NoNewWindow -Wait -FilePath $DCU -ArgumentList '/scan -silent'
    Start-Process -NoNewWindow -Wait -FilePath $DCU -ArgumentList '/applyUpdates -autoSuspendBitLocker=enable -reboot=disable'
  }
  catch {
    Write-Warning 'Unable to apply updates using the dcu-cli.'
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

# Check device manufacturer
if ((Get-WmiObject win32_bios).Manufacturer -notlike '*Dell*') {
  Write-Output "`nNot a Dell system. Aborting..."
  exit 0
}

# Handle Prerequisites / Dependencies
Remove-DellUpdate
Install-DotNetDesktopRuntime

# Install DCU and available updates
Install-DellCommandUpdate
Invoke-DellCommandUpdate
