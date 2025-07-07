<#
  .SYNOPSIS
    Installs Dell updates via Dell Command Update
  .DESCRIPTION
    Installs the latest version of Dell Command Update and applies all Dell updates silently.
  .LINK
    https://www.dell.com/support/product-details/en-us/product/command-update/resources/manuals
    https://github.com/wise-io/scripts/blob/main/scripts/DellCommandUpdate.ps1
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

function Get-InstalledApps {
  param(
    [Parameter(Mandatory)][String[]]$DisplayNames,
    [String[]]$Exclude
  )
  
  $RegPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )
  
  # Get applications matching criteria
  $BroadMatch = @()
  foreach ($DisplayName in $DisplayNames) {
    $AppsWithBundledVersion = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" -and $null -ne $_.BundleVersion }
    if ($AppsWithBundledVersion) { $BroadMatch += $AppsWithBundledVersion }
    else { $BroadMatch += Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" } }
  }
  
  # Remove excluded apps
  $MatchedApps = @()
  foreach ($App in $BroadMatch) {
    if ($Exclude -notcontains $App.DisplayName) { $MatchedApps += $App }
  }

  return $MatchedApps | Sort-Object { [version]$_.BundleVersion } -Descending
}

function Remove-DellUpdateApps {
  param([String[]]$DisplayNames = @('Dell Update'))

  # Check for specified products
  $Apps = Get-InstalledApps -DisplayNames $DisplayNames -Exclude 'Dell SupportAssist OS Recovery Plugin for Dell Update'
  foreach ($App in $Apps) {
    Write-Output "Attempting to remove $($App.DisplayName)..."
    try {
      if ($App.UninstallString -match 'msiexec') {
        $Guid = [regex]::Match($App.UninstallString, '\{[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\}').Value
        Start-Process -NoNewWindow -Wait -FilePath 'msiexec.exe' -ArgumentList "/x $Guid /quiet /qn"
      }
      else { Start-Process -NoNewWindow -Wait -FilePath $App.UninstallString -ArgumentList '/quiet' }
      Write-Output "Successfully removed $($App.DisplayName) [$($App.DisplayVersion)]"
    }
    catch { 
      Write-Warning "Failed to remove $($App.DisplayName) [$($App.DisplayVersion)]"
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
    if ($Arch -like 'arm*') { 
      $FallbackDownloadURL = 'https://dl.dell.com/FOLDER11914141M/1/Dell-Command-Update-Windows-Universal-Application_6MK0D_WINARM64_5.4.0_A00.EXE'
      $FallbackMD5 = 'c6ed3bc35d7d6d726821a2c25fbbb44d'
      $FallbackVersion = '5.4.0'
    }
    else { 
      $FallbackDownloadURL = 'https://dl.dell.com/FOLDER11914128M/1/Dell-Command-Update-Windows-Universal-Application_9M35M_WIN_5.4.0_A00.EXE'
      $FallbackMD5 = '20650f194900e205848a04f0d2d4d947'
      $FallbackVersion = '5.4.0'
    }
  
    # Set headers for Dell website
    $Headers = @{
      'accept'          = 'text/html'
      'accept-encoding' = 'gzip'
      'accept-language' = '*'
    }
  
    try {
      # Attempt to parse Dell website for download page links of latest DCU
      [String]$DellKB = Invoke-WebRequest -UseBasicParsing -Uri $DellKBURL -Headers $Headers -ErrorAction Ignore
      $LinkMatches = @($DellKB | Select-String '(https://www\.dell\.com.+driverid=[a-z0-9]+).+>Dell Command \| Update Windows Universal Application<\/a>' -AllMatches).Matches
      $KBLinks = foreach ($Match in $LinkMatches) { $Match.Groups[1].Value }
  
      # Attempt to parse Dell website for download URLs for latest DCU
      $DownloadObjects = foreach ($Link in $KBLinks) {
        $DownloadPage = Invoke-WebRequest -UseBasicParsing -Uri $Link -Headers $Headers -ErrorAction Ignore
        if ($DownloadPage -match '(https://dl\.dell\.com.+Dell-Command-Update.+\.EXE)') { 
          $Url = $Matches[1]
          if ($DownloadPage -match 'MD5:.*?([a-fA-F0-9]{32})') { $MD5 = $Matches[1] }
          [PSCustomObject]@{
            URL = $Url
            MD5 = $MD5
          }
        }
      }
  
      # Set download URL / MD5 based on architecture
      if ($Arch -like 'arm*') { $DownloadObject = $DownloadObjects | Where-Object { $_.URL -like '*winarm*' } }
      else { $DownloadObject = $DownloadObjects | Where-Object { $_.URL -notlike '*winarm*' } }
      $DownloadURL = $DownloadObject.URL
      $MD5 = $DownloadObject.MD5
      $Version = $DownloadURL | Select-String '[0-9]*\.[0-9]*\.[0-9]*' | ForEach-Object { $_.Matches.Value }
    }
    catch {}
    finally {
      # Revert to fallback URL / MD5 if unable to retrieve from Dell
      if ($null -eq $DownloadObject.URL -or $null -eq $DownloadObject.MD5) { 
        $DownloadURL = $FallbackDownloadURL
        $MD5 = $FallbackMD5
        $Version = $FallbackVersion
      }
    }

    return @{
      MD5     = $MD5.ToUpper()
      URL     = $DownloadURL
      Version = $Version
    }
  }
  
  $LatestDellCommandUpdate = Get-LatestDellCommandUpdate
  $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDellCommandUpdate.URL -Leaf)
  $CurrentVersion = (Get-InstalledApps -DisplayName 'Dell Command | Update').DisplayVersion
  Write-Output "`nInstalled Dell Command Update: $CurrentVersion"
  Write-Output "Latest Dell Command Update: $($LatestDellCommandUpdate.Version)"

  if ($CurrentVersion -lt $LatestDellCommandUpdate.Version) {

    # Download installer
    Write-Output "`nDell Command Update installation needed"
    Write-Output 'Downloading...'
    Invoke-WebRequest -Uri $LatestDellCommandUpdate.URL -OutFile $Installer -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)

    # Verify MD5 checksum
    Write-Output 'Verifying MD5 checksum...'
    $InstallerMD5 = (Get-FileHash -Path $Installer -Algorithm MD5).Hash
    if ($InstallerMD5 -ne $LatestDellCommandUpdate.MD5) {
      Write-Warning 'MD5 verification failed - aborting...'
      Remove-Item $Installer -Force -ErrorAction Ignore
      exit 1
    }

    # Remove existing version to avoid Classic / Universal incompatibilities 
    if ($CurrentVersion) { Remove-DellUpdateApps -DisplayNames 'Dell Command | Update' }

    # Install Dell Command Update
    Write-Output 'Installing latest...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/s'

    # Confirm installation
    $CurrentVersion = (Get-InstalledApps -DisplayName 'Dell Command | Update').DisplayVersion
    if ($CurrentVersion -match $LatestDellCommandUpdate.Version) {
      Write-Output "Successfully installed Dell Command Update [$CurrentVersion]`n"
      Remove-Item $Installer -Force -ErrorAction Ignore 
    }
    else {
      Write-Warning "Dell Command Update [$($LatestDellCommandUpdate.Version)] not detected after installation attempt"
      Remove-Item $Installer -Force -ErrorAction Ignore 
      exit 1
    }
  }
  else { Write-Output "`nDell Command Update installation / upgrade not needed`n" }
}

function Install-DotNetDesktopRuntime {
  function Get-LatestDotNetDesktopRuntime {
    try {
      $BaseURL = 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop'
      $Version = (Invoke-WebRequest -Uri "$BaseURL/LTS/latest.version" -UseBasicParsing).Content
      $Arch = Get-Architecture
      $URL = "$BaseURL/$Version/windowsdesktop-runtime-$Version-win-$Arch.exe"
    }
    catch {}
    finally {
      # Confirm version number format
      if ($Version -notmatch '^\d+(\.\d+)+$') { 
        $URL = $null
        $Version = $null
      }
    }
  
    return @{
      URL     = $URL
      Version = $Version
    }
  }
  
  $LatestDotNet = Get-LatestDotNetDesktopRuntime
  $CurrentVersion = (Get-InstalledApps -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion
  if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
  Write-Output "`nInstalled .NET Desktop Runtime: $CurrentVersion"
  Write-Output "Latest .NET Desktop Runtime: $($LatestDotNet.Version)"

  if ($CurrentVersion -lt $LatestDotNet.Version) {
    
    # Download installer
    Write-Output "`n.NET Desktop Runtime installation needed"
    Write-Output 'Downloading...'
    $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDotNet.URL -Leaf)
    Invoke-WebRequest -Uri $LatestDotNet.URL -OutFile $Installer

    # Install .NET
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/install /quiet /norestart'

    # Confirm installation
    $CurrentVersion = (Get-InstalledApps -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion
    if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
    if ($CurrentVersion -match $LatestDotNet.Version) {
      Write-Output "Successfully installed .NET Desktop Runtime [$CurrentVersion]"
      Remove-Item $Installer -Force -ErrorAction Ignore 
    }
    else {
      Write-Warning ".NET Desktop Runtime [$($LatestDotNet.Version)] not detected after installation attempt"
      Remove-Item $Installer -Force -ErrorAction Ignore 
      exit 1
    }
  }
  elseif ($null -eq $LatestDotNet.Version) { 
    Write-Output "`nUnable to retrieve latest .NET Desktop Runtime version - skipping installation / upgrade"
  }
  else { Write-Output "`n.NET Desktop Runtime installation / upgrade not needed" }
}

function Invoke-DellCommandUpdate {
  # Check for DCU CLI
  $DCU = (Resolve-Path "$env:SystemDrive\Program Files*\Dell\CommandUpdate\dcu-cli.exe").Path
  if ($null -eq $DCU) {
    Write-Warning 'Dell Command Update CLI was not detected.'
    exit 1
  }
  
  try {
    # Configure DCU automatic updates
    Start-Process -NoNewWindow -Wait -FilePath $DCU -ArgumentList '/configure -scheduleAction=DownloadInstallAndNotify -updatesNotification=disable -forceRestart=disable -scheduleAuto -silent'
    
    # Install updates
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
if ((Get-CimInstance -ClassName Win32_BIOS).Manufacturer -notlike '*Dell*') {
  Write-Output "`nNot a Dell system. Aborting..."
  exit 0
}

# Handle Prerequisites / Dependencies
Remove-DellUpdateApps
Install-DotNetDesktopRuntime

# Install DCU and available updates
Install-DellCommandUpdate
Invoke-DellCommandUpdate
