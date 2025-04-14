<#
  .SYNOPSIS
    Installs .NET Desktop Runtime
  .DESCRIPTION
    Downloads and installs the latest LTS release of the Microsoft .NET Desktop Runtime
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
  
  $App = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" -and $null -ne $_.BundleVersion }
  return $App | Sort-Object { [version]$_.BundleVersion } -Descending
}

function Install-DotNetDesktopRuntime {
  function Get-LatestDotNetDesktopRuntime {
    $BaseURL = 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop'
    $Version = (Invoke-WebRequest -Uri "$BaseURL/LTS/latest.version" -UseBasicParsing).Content
    $Arch = Get-Architecture
    $URL = "$BaseURL/$Version/windowsdesktop-runtime-$Version-win-$Arch.exe"
  
    return @{
      URL     = $URL
      Version = $Version
    }
  }
  
  $LatestDotNet = Get-LatestDotNetDesktopRuntime
  $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path $LatestDotNet.URL -Leaf)
  $CurrentVersion = (Get-InstalledApps -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion
  if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
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
    $CurrentVersion = (Get-InstalledApps -DisplayName 'Microsoft Windows Desktop Runtime').BundleVersion
    if ($CurrentVersion -is [system.array]) { $CurrentVersion = $CurrentVersion[0] }
    if ($CurrentVersion -match $LatestDotNet.Version) {
      Write-Output "Successfully installed .NET Desktop Runtime [$CurrentVersion]"
    }
    else {
      Write-Warning ".NET Desktop Runtime [$($LatestDotNet.Version)] not detected after installation attempt"
      exit 1
    }
  }
  else { Write-Output "`n.NET Desktop Runtime installation / upgrade not needed" }
}

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Install-DotNetDesktopRuntime
