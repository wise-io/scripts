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
  [Switch]$Reboot
)

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

  return $MatchedApps | Sort-Object { [version]$_.BundleVersion } -Descending
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

function Get-DellCommandUpdate {
  function Get-DellXML {
    param([Parameter(Mandatory)][String]$Uri)

    $Expand = "$env:SystemRoot\System32\expand.exe"
    $TempCAB = Join-Path -Path $env:TEMP -ChildPath 'temp.cab'
    $TempXML = Join-Path -Path $env:TEMP -ChildPath 'temp.xml'

    # Remove pre-existing temp files
    Remove-Item $TempCAB, $TempXML -Force -ErrorAction Ignore
    
    # Download cab file
    Invoke-WebRequest -Uri $Uri -OutFile $TempCAB -UseBasicParsing
    if (!(Test-Path $TempCAB)) { 
      Write-Warning "Unable to download cab file from $Uri"
      exit 1
    }

    # Expand cab file and get xml content
    & $Expand "$TempCAB" "$TempXML" | Out-Null
    [xml]$Content = Get-Content $TempXML

    # Cleanup and return
    Remove-Item $TempCAB, $TempXML -Force -ErrorAction Ignore
    return $Content
  }

  # Download Dell catalog and extract xml
  $CatalogURL = 'https://downloads.dell.com/catalog/CatalogIndexPC.cab'
  $CatalogXMLContent = Get-DellXML -Uri $CatalogURL

  # Get system xml from Dell catalog
  $SystemSKU = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
  $SupportedModels = $CatalogXMLContent.ManifestIndex.GroupManifest
  foreach ($SupportedModel in $SupportedModels) {
    if ($SystemSKU -match $SupportedModel.SupportedSystems.Brand.Model.systemID) {
      $ModelXMLContent = Get-DellXML -Uri "https://downloads.dell.com/$($SupportedModel.ManifestInformation.path)"
      break
    }
  }

  # Abort if no matching model was found
  if ($null -eq $ModelXMLContent) {
    Write-Output 'This Dell system is incompatible with Dell Command Update - aborting...'
    exit 0
  }
  
  # Get latest dell command update
  $Apps = $ModelXMLContent.Manifest.SoftwareComponent | Where-Object {
    $_.ComponentType.value -eq 'APAC' -and
    $_.path -match 'command-update' -and
    $_.path -match 'universal' -and
    $_.SupportedOperatingSystems.OperatingSystem.osArch -match $Arch
  }
  
  $Latest = $Apps | Where-Object { $_.SupportedOperatingSystems.OperatingSystem.osArch -match $Arch } | Sort-Object -Property 'vendorVersion' | Select-Object -Last 1
  if ($Latest) {
    return @{
      Version     = $Latest.vendorVersion
      Date        = $Latest.releaseDate
      Criticality = $Latest.Criticality.Display.'#cdata-section'
      Hash        = ($Latest.Cryptography.Hash | Where-Object { $_.Algorithm -eq 'SHA256' }).'#text'
      URL         = "https://downloads.dell.com/$($Latest.path)"
    }
  }
  else { return $null }
}

function Install-DellCommandUpdate {
  
  # Get latest Dell Command Update
  $LatestDellCommandUpdate = Get-DellCommandUpdate
  if ($null -eq $LatestDellCommandUpdate) {
    Write-Warning 'Unable to retrieve latest Dell Command Update from Dell.'
    exit 1
  }

  $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDellCommandUpdate.URL -Leaf)
  $InstallerLog = Join-Path $env:TEMP -ChildPath ((Split-Path $LatestDellCommandUpdate.URL -Leaf) + '.log')
  $CurrentVersion = Get-InstalledApps -DisplayNames 'Dell Command | Update'
  $CurrentVersionString = ("$($CurrentVersion.DisplayName) $($CurrentVersion.DisplayVersion)").Trim()
  Write-Output "`nDell Command Update Version Info`n-----"
  Write-Output "Installed: $CurrentVersionString"
  Write-Output "Latest: $($LatestDellCommandUpdate.Version)"

  if ($CurrentVersion.DisplayVersion -lt $LatestDellCommandUpdate.Version) {

    # Download installer
    Write-Output "`nDell Command Update installation needed"
    Write-Output 'Downloading...'
    Invoke-WebRequest -Uri $LatestDellCommandUpdate.URL -OutFile $Installer -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)

    # Verify SHA256 Hash
    if ($null -ne $LatestDellCommandUpdate.Hash) {
      Write-Output 'Verifying SHA256 Hash...'
      $InstallerHash = (Get-FileHash -Path $Installer -Algorithm SHA256).Hash
      if ($InstallerHash -ne $LatestDellCommandUpdate.Hash) {
        Write-Warning 'SHA256 Hash verification failed - aborting...'
        Remove-Item $Installer -Force -ErrorAction Ignore
        exit 1
      }
    }
    else { Write-Warning 'Unable to retrieve hash from Dell for validation - skipping...' }

    # Remove existing version to avoid Classic / Universal incompatibilities 
    if ($CurrentVersion) { Remove-DellUpdateApps -DisplayNames 'Dell Command | Update' }

    # Install Dell Command Update
    Write-Output 'Installing latest...'
    $InstallerProcess = Start-Process -Wait -NoNewWindow -PassThru -FilePath $Installer -ArgumentList "/s /l=`"$InstallerLog`""
    Remove-Item $Installer -Force -ErrorAction Ignore 

    # Confirm installation
    if ($InstallerProcess.ExitCode -ne 0 -and $InstallerProcess.ExitCode -ne 2) {
      Write-Warning "Dell Command Update installer exited with exit code $($InstallerProcess.ExitCode). The log file at $InstallerLog may provide more information."
      exit 1
    }
    
    Write-Output 'Installation successful.'
  }
  else { Write-Output "`nDell Command Update installation / upgrade not needed`n" }
}

function Install-DotNetDesktopRuntime {
  function Get-LatestDotNetDesktopRuntime {
    try {
      $BaseURL = 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop'
      $Version = (Invoke-WebRequest -Uri "$BaseURL/8.0/latest.version" -UseBasicParsing).Content
      $URL = "$BaseURL/$Version/windowsdesktop-runtime-$Version-win-$Arch.exe"
      $HashURL = "https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-desktop-$Version-windows-$Arch-installer"

      # Retrieve SHA-512 Hash
      $DownloadPage = Invoke-WebRequest -UseBasicParsing -Uri $HashURL -ErrorAction Ignore
      if ($DownloadPage -match 'id="checksum".*?([a-fA-F0-9]{128})') { $Hash = ($Matches[1]).ToUpper() }

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
      Hash    = $Hash
      URL     = $URL
      Version = $Version
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
    Write-Output 'Downloading...'
    $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDotNet.URL -Leaf)
    Invoke-WebRequest -Uri $LatestDotNet.URL -OutFile $Installer

    # Verify SHA512 Hash
    if ($null -ne $LatestDotNet.Hash) {
      Write-Output 'Verifying SHA512 Hash...'
      $InstallerHash = (Get-FileHash -Path $Installer -Algorithm SHA512).Hash
      if ($InstallerHash -ne $LatestDotNet.Hash) {
        Write-Warning 'SHA512 Hash verification failed - aborting...'
        Remove-Item $Installer -Force -ErrorAction Ignore
        exit 1
      }
    }
    else { Write-Warning 'Unable to retrieve Hash from Microsoft for validation - skipping...' }
    
    # Install .NET
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/install /quiet /norestart'

    # Confirm installation
    $CurrentVersion = (Get-InstalledApps -DisplayNames "Microsoft Windows Desktop Runtime*($Arch)").BundleVersion | Where-Object { $_ -like '8.*' }
    if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
    if ($CurrentVersion -match $LatestDotNet.Version) {
      Write-Output "Successfully installed .NET 8.0 Desktop Runtime $CurrentVersion"
      Remove-Item $Installer -Force -ErrorAction Ignore 
    }
    else {
      Write-Warning ".NET 8.0 Desktop Runtime $($LatestDotNet.Version) not detected after installation attempt"
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
if ((Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer -notmatch 'Dell') {
  Write-Output "`nNot a Dell system. Aborting..."
  exit 0
}

# Handle Prerequisites / Dependencies
$Arch = Get-Architecture
Remove-DellUpdateApps -DisplayNames 'Dell Update'
Install-DotNetDesktopRuntime

# Install DCU and available updates
Install-DellCommandUpdate
Invoke-DellCommandUpdate

# Reboot if specified
if ($Reboot) {
  Write-Warning 'Reboot specified - rebooting in 60 seconds...'
  Start-Process -Wait -NoNewWindow -FilePath 'shutdown.exe' -ArgumentList '/r /f /t 60 /c "This system will restart in 60 seconds to install driver and firmware updates. Please save and close your work." /d p:4:1'
}
else { Write-Output "`nA reboot may be needed to complete the installation of driver and firmware updates." }
