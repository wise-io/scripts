#Requires -Version 5.1
#Requires -RunAsAdministrator

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

[CmdletBinding()]
param (
  [Switch]$Reboot,
  [Switch]$ApplySettingAndUpdate
)

#region functions
function Get-Architecture {
  # On PS x86, PROCESSOR_ARCHITECTURE reports x86 even on x64 systems.
  # To get the correct architecture, we need to use PROCESSOR_ARCHITEW6432.
  # PS x64 doesn't define this, so we fall back to PROCESSOR_ARCHITECTURE.
  # Possible values: amd64, x64, arm64
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
    # { $_ -eq 'x86' } { return 'x86' } - DCU 5.X doesn't support 32-bit
    # { $_ -eq 'arm' } { return 'arm' } - DCU 5.X doesn't support 32-bit ARM
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

  return $MatchedApps | Sort-Object { 
    if ($_.BundleVersion) { [version]$_.BundleVersion } else { [version]'0.0' }
  } -Descending

}

function Remove-DellUpdateApps {
  param([String[]]$DisplayNames)

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
    if ($Arch -like 'arm*') { 
      $FallbackDownloadURL = 'https://dl.dell.com/FOLDER13922742M/1/Dell-Command-Update-Windows-Universal-Application_TYXTK_WINARM64_5.6.0_A00.EXE'
      $FallbackChecksum = '1D0A86DE060379B6324B1BE35487D9891FFDBF90969B662332A294369A45D656' # SHA256
      $FallbackVersion = '5.6.0'
    }
    else { 
      $FallbackDownloadURL = 'https://dl.dell.com/FOLDER13922692M/1/Dell-Command-Update-Windows-Universal-Application_2WT0J_WIN64_5.6.0_A00.EXE'
      $FallbackChecksum = 'E09B7FDF8BA5A19A837A95E1183E5A79C006BE2F433909E177E24FD704C26AA1' # SHA256
      $FallbackVersion = '5.6.0'
    }
  
    # Set headers for Dell website
    $Headers = @{
      'upgrade-insecure-requests' = '1'
      'user-agent'                = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0'
      'accept'                    = 'text/html'
      'sec-fetch-site'            = 'same-origin'
      'sec-fetch-mode'            = 'navigate'
      'sec-fetch-user'            = '?1'
      'sec-fetch-dest'            = 'document'
      'referer'                   = "$DellKBURL"
      'accept-encoding'           = 'gzip'
      'accept-language'           = '*'
      'cache-control'             = 'max-age=0'
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
          if ($DownloadPage -match 'SHA-256:.*?([a-fA-F0-9]{64})') { $Checksum = $Matches[1] }
          [PSCustomObject]@{
            URL      = $Url
            Checksum = $Checksum
          }
        }
      }
  
      # Select correct download object based on architecture
      if ($Arch -like 'arm*') { $DownloadObject = $DownloadObjects | Where-Object { $_.URL -like '*winarm*' } }
      else { $DownloadObject = $DownloadObjects | Where-Object { $_.URL -notlike '*winarm*' } }
    }
    catch {}
    finally {
      # Revert to fallback URL / SHA256 checksum if unable to retrieve from Dell
      if ($null -eq $DownloadObject.URL -or $null -eq $DownloadObject.Checksum) { 
        Write-Warning 'Unable to retrieve latest version info from Dell - reverting to fallback...'
        $DownloadURL = $FallbackDownloadURL
        $Checksum = $FallbackChecksum.ToUpper()
        $Version = $FallbackVersion
      }
      else {
        $DownloadURL = $DownloadObject.URL
        $Checksum = ($DownloadObject.Checksum).ToUpper()
        $Version = $DownloadURL | Select-String '[0-9]*\.[0-9]*\.[0-9]*' | ForEach-Object { $_.Matches.Value }
      }
    }

    return @{
      Checksum = $Checksum
      URL      = $DownloadURL
      Version  = $Version
    }
  }
  
  $LatestDellCommandUpdate = Get-LatestDellCommandUpdate
  $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDellCommandUpdate.URL -Leaf)
  $CurrentVersion = Get-InstalledApps -DisplayNames 'Dell Command | Update'
  $CurrentVersionString = ("$($CurrentVersion.DisplayName) [$($CurrentVersion.DisplayVersion)]").Trim()
  Write-Output "`nDell Command Update Version Info`n-----"
  Write-Output "Installed: $CurrentVersionString"
  Write-Output "Latest / Fallback: $($LatestDellCommandUpdate.Version)"

  if ([version]$CurrentVersion.DisplayVersion -lt [version]$LatestDellCommandUpdate.Version) {

    # Download installer
    Write-Output "`nDell Command Update installation needed"
    Write-Output "Downloading $Arch version of DELL Command Update..."
    Invoke-WebRequest -Uri $LatestDellCommandUpdate.URL -OutFile $Installer -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)

    # check if file is downloaded
    if (-not (Test-Path -Path $Installer)) {
    Write-Warning 'Download failed - installer file not found.'
    exit 1
    }

    # Verify SHA256 checksum
    if ($null -ne $LatestDellCommandUpdate.Checksum) {
      Write-Output 'Verifying SHA256 checksum...'
      $InstallerChecksum = (Get-FileHash -Path $Installer -Algorithm SHA256).Hash
      if ($InstallerChecksum -ne $LatestDellCommandUpdate.Checksum) {
        Write-Warning 'SHA256 checksum verification failed - aborting...'
        Remove-Item $Installer -Force -ErrorAction Ignore
        exit 1
      }
    }
    else { Write-Warning 'Unable to retrieve checksum from Dell for validation - skipping...' }

    # Remove existing version to avoid Classic / Universal incompatibilities 
    if ($CurrentVersion) { Remove-DellUpdateApps -DisplayNames 'Dell Command | Update' }

    # Install Dell Command Update
    Write-Output 'Installing latest...'
    $installerProcess = Start-Process -Wait -NoNewWindow -PassThru -FilePath $Installer -ArgumentList '/s'
    switch ($installerProcess.ExitCode) {
      0       { Write-Output "Dell Command Update installer returend $($installerProcess.ExitCode) success." }
      2       { Write-Output "Dell Command Update installer returend $($installerProcess.ExitCode) a restart is required." }
      Default { Write-Warning "Dell Command Update installer returend an unknown error $($installerProcess.ExitCode)." }
    }

    # Confirm installation
    $CurrentVersion = Get-InstalledApps -DisplayNames 'Dell Command | Update'
    if ($CurrentVersion.DisplayVersion -eq $LatestDellCommandUpdate.Version) {
      Write-Output "Successfully installed $($CurrentVersion.DisplayName) [$($CurrentVersion.DisplayVersion)]`n"
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
      $Version = (Invoke-WebRequest -Uri "$BaseURL/8.0/latest.version" -UseBasicParsing).Content
      $URL = "$BaseURL/$Version/windowsdesktop-runtime-$Version-win-$Arch.exe"
      $ChecksumURL = "https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-desktop-$Version-windows-$Arch-installer"

      # Retrieve SHA-512 checksum
      $DownloadPage = Invoke-WebRequest -UseBasicParsing -Uri $ChecksumURL -ErrorAction Ignore
      if ($DownloadPage -match 'id="checksum".*?([a-fA-F0-9]{128})') { $Checksum = $Matches[1] }

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
      Checksum = if ($Checksum) { $Checksum.ToUpper() } else { $null }
      URL      = $URL
      Version  = $Version
    }
  }
  
  $LatestDotNet = Get-LatestDotNetDesktopRuntime
  $CurrentVersion = (Get-InstalledApps -DisplayNames "Microsoft Windows Desktop Runtime*($Arch)").BundleVersion | Where-Object { $_ -like '8.*' }
  Write-Output "`n.NET 8.0 Desktop Runtime Info`n-----"
  Write-Output "Installed: $CurrentVersion"
  Write-Output "Latest: $($LatestDotNet.Version)"

  if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
  if ($CurrentVersion -lt $LatestDotNet.Version) {
    
    # Download installer
    Write-Output "`n.NET 8.0 Desktop Runtime installation needed"
    Write-Output "Downloading $Arch version of NET 8.0 Desktop Runtime..."
    $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDotNet.URL -Leaf)
    Invoke-WebRequest -Uri $LatestDotNet.URL -OutFile $Installer

    # check if file is downloaded
    if (-not (Test-Path -Path $Installer)) {
    Write-Warning 'Download failed - installer file not found.'
    exit 1
    }

    # Verify SHA512 checksum
    if ($null -ne $LatestDotNet.Checksum) {
      Write-Output 'Verifying SHA512 checksum...'
      $InstallerChecksum = (Get-FileHash -Path $Installer -Algorithm SHA512).Hash
      if ($InstallerChecksum -ne $LatestDotNet.Checksum) {
        Write-Warning 'SHA512 checksum verification failed - aborting...'
        Remove-Item $Installer -Force -ErrorAction Ignore
        exit 1
      }
    }
    else { Write-Warning 'Unable to retrieve checksum from Microsoft for validation - skipping...' }
    
    # Install .NET
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/install /quiet /norestart'

    # Confirm installation
    $CurrentVersion = (Get-InstalledApps -DisplayName "Microsoft Windows Desktop Runtime*($Arch)").BundleVersion | Where-Object { $_ -like '8.*' }
    if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
    if ($CurrentVersion -match $LatestDotNet.Version) {
      Write-Output "Successfully installed .NET 8.0 Desktop Runtime [$CurrentVersion]"
      Remove-Item $Installer -Force -ErrorAction Ignore 
    }
    else {
      Write-Warning ".NET 8.0 Desktop Runtime [$($LatestDotNet.Version)] not detected after installation attempt"
      Remove-Item $Installer -Force -ErrorAction Ignore 
      exit 1
    }
  }
  elseif ($null -eq $LatestDotNet.Version) { 
    Write-Output "`nUnable to retrieve latest .NET 8.0 Desktop Runtime version - skipping installation / upgrade"
  }
  else { Write-Output "`n.NET 8.0 Desktop Runtime installation / upgrade not needed" }
}

function Invoke-DellCommandUpdate {
  # Check for DCU CLI
  $DCU = (Resolve-Path "$env:SystemDrive\Program Files*\Dell\CommandUpdate\dcu-cli.exe" | Select-Object -First 1).Path
  if ([string]::IsNullOrEmpty($DCU)) {
    Write-Warning 'Dell Command Update CLI was not detected.'
    exit 1
  }
  
  try {
    # Configure DCU automatic updates
    $processConfigure = Start-Process -NoNewWindow -Wait -PassThru -FilePath $DCU -ArgumentList '/configure -scheduleAction=DownloadInstallAndNotify -updatesNotification=disable -forceRestart=disable -scheduleAuto -silent'
    if ($processConfigure.ExitCode -ne 0) { Write-Warning "dcu-cli configure exited with code $($processConfigure.ExitCode)" }


    # Install updates
    $processApplyUpdates = Start-Process -NoNewWindow -Wait -PassThru -FilePath $DCU -ArgumentList '/applyUpdates -autoSuspendBitLocker=enable -reboot=disable'
    if ($processApplyUpdates.ExitCode -ne 0) { Write-Warning "dcu-cli applyUpdates exited with code $($processApplyUpdates.ExitCode)" }
  }
  catch {
    Write-Warning 'Unable to apply updates using the dcu-cli.'
    Write-Warning $_
    exit 1
  }
}

function Test-PendingReboot {
  $PendingReboot = $false

  # Check Component Based Servicing
  if (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction SilentlyContinue) {
    $PendingReboot = $true
  }

  # Check Windows Update
  if (Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue) {
    $PendingReboot = $true
  }

  # Check PendingFileRenameOperations
  if (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) {
    $PendingReboot = $true
  }

  # Check SCCM Client
  try {
    $SCCMReboot = Invoke-CimMethod -Namespace 'root\ccm\ClientSDK' -ClassName CCM_ClientUtilities -MethodName DetermineIfRebootPending -ErrorAction SilentlyContinue
    if ($SCCMReboot.RebootPending -or $SCCMReboot.IsHardRebootPending) {
      $PendingReboot = $true
    }
  }
  catch {}

  # Output result
  if ($PendingReboot) {
    Write-Warning 'A pending reboot has been detected. A restart is required to complete previous installations.'
  }
  else {
    Write-Output 'No pending reboot detected.'
  }
}
#endregion functions

# Set PowerShell preferences
Set-Location -Path $env:SystemRoot
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

#region checks
# Check device manufacturer
if ((Get-CimInstance -ClassName Win32_BIOS).Manufacturer -notlike '*Dell*') {
  Write-Output "`nNot a Dell system. Aborting..."
  exit 0
}

# Check if we have pending reboot in case of troubleshooting
Test-PendingReboot
#endregion checks

# Handle Prerequisites / Dependencies
$Arch = Get-Architecture
Remove-DellUpdateApps -DisplayNames 'Dell Update'
Install-DotNetDesktopRuntime

# Install DCU and available updates
Install-DellCommandUpdate

# Apply settings and updates
if($ApplySettingAndUpdate){
  Invoke-DellCommandUpdate
}

# Reboot if specified
if ($Reboot) {
  Write-Warning 'Reboot specified - rebooting in 60 seconds...'
  Start-Process -Wait -NoNewWindow -FilePath 'shutdown.exe' -ArgumentList '/r /f /t 60 /c "This system will restart in 60 seconds to install driver and firmware updates. Please save and close your work." /d p:4:1'
}
else { Write-Output "`nA reboot may be needed to complete the installation of driver and firmware updates." }
