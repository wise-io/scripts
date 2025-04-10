<#
  .SYNOPSIS
    Installs Microsoft Teams
  .DESCRIPTION
    Installs the new Microsoft Teams client machine wide
  .PARAMETER Force
    Switch parameter - attempts install even if existing installation is detected
  .LINK
    https://learn.microsoft.com/en-us/microsoftteams/new-teams-bulk-install-client
  .NOTES
    Author: Aaron J. Stevenson
#>

param([Switch]$Force)

function Install-NewTeams {
  function Set-MsixURL {
    # Define urls
    $x86Url = 'https://go.microsoft.com/fwlink/?linkid=2196060'
    $x64Url = 'https://go.microsoft.com/fwlink/?linkid=2196106'
    $Arm64Url = 'https://go.microsoft.com/fwlink/?linkid=2196207'
  
    # Get machine architecture
    if ($null -ne $ENV:PROCESSOR_ARCHITEW6432) { $Architecture = $ENV:PROCESSOR_ARCHITEW6432 }
    else {     
      if ((Get-CimInstance -ClassName CIM_OperatingSystem -ErrorAction Ignore).OSArchitecture -like 'ARM*') {
        if ( [Environment]::Is64BitOperatingSystem ) { $Architecture = 'arm64' }  
        else { $Architecture = 'arm' }
      }
      if ($null -eq $Architecture) { $Architecture = $ENV:PROCESSOR_ARCHITECTURE }
    }
  
    # Return correct url
    switch ($Architecture.ToLowerInvariant()) {
      { ($_ -eq 'amd64') -or ($_ -eq 'x64') } { return $x64Url }
      { $_ -eq 'x86' } { return $x86Url }
      { $_ -eq 'arm64' } { return $Arm64Url }
      default { throw "Architecture '$Architecture' not supported." }
    }
  }
  
  # Set bootstrapper url / msix download urls
  $BootstrapperURL = 'https://go.microsoft.com/fwlink/?linkid=2243204'
  $MsixURL = Set-MsixURL

  # Set file paths
  $Bootstrapper = Join-Path -Path $env:TEMP -ChildPath 'teamsbootstrapper.exe'
  $TeamsMsix = Join-Path -Path $env:TEMP -ChildPath 'MSTeams.msix'

  # Check for existing installation
  $Installed = Get-AppxPackage 'MSTeams' -AllUsers
  if ($Installed -and -not $Force) {
    Write-Output "`nMicrosoft Teams [$($Installed.Version)] detected"
    Write-Output 'Download / Installation not needed'
  }
  else {
    try {
      # Download files
      Write-Output "`nDownloading Teams Bootstrapper and MSIX files..."
      Invoke-WebRequest -Uri $BootstrapperURL -OutFile $Bootstrapper
      Invoke-WebRequest -Uri $MsixURL -OutFile $TeamsMsix

      # Install Teams
      Write-Output 'Installing...'
      Start-Process -NoNewWindow -Wait -FilePath $Bootstrapper -ArgumentList "-p -o $TeamsMsix"
      
      # Output installed version
      $Installed = Get-AppxPackage 'MSTeams' -AllUsers
      if ($Installed) { Write-Output "Microsoft Teams [$($Installed.Version)] installed" }
    }
    catch {
      Write-Warning 'Unable to install Microsoft Teams.'
      Write-Warning $_
    }
    finally { Remove-Item $Bootstrapper, $TeamsMsix -Force -ErrorAction Ignore }
  }
}

# Set PowerShell preferences
Set-Location -Path $env:SystemRoot
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Install Teams
Install-NewTeams

# Remove Teams Classic Machine-Wide installer
$TeamsMachineWide = Get-Package -Name 'Teams Machine-Wide Installer' -ErrorAction Ignore
if ($TeamsMachineWide) { 
  Write-Output "`nTeams (Classic) machine-wide installer detected"
  Write-Output 'Attempting removal...'
  $TeamsMachineWide | Uninstall-Package | Out-Null
  $Installed = Get-Package -Name 'Teams Machine-Wide Installer' -ErrorAction Ignore
  if ($Installed) { Write-Warning 'Removal failed' }
  else { Write-Output 'Success' }
}
