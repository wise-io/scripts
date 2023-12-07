<#
  .SYNOPSIS
    Installs Foxit Reader Enterprise
  .DESCRIPTION
    Downloads and installs Foxit Reader Enterprise silently.
  .PARAMETER Default
    Optional - Attempts to set Foxit Reader as the default PDF viewer.
  .NOTES
    Author: Aaron J. Stevenson
  .LINK
    Enterprise Registration: https://www.foxit.com/pdf-reader/enterprise-register.html
#>

param([Switch]$Default)

$Installer = "$env:temp\FoxitReaderSetup.msi"
$DownloadURL = 'https://www.foxit.com/downloads/latest.html?product=Foxit-Enterprise-Reader&platform=Windows&package_type=msi&language=English'

# Installer Arguments
if ($Default) { $DefaultValue = 1 } else { $DefaultValue = 0 }
$ArgumentList = @(
  '/i',
  "$Installer",
  '/quiet',
  "MAKEDEFAULT=$DefaultValue",
  'DESKTOP_SHORTCUT=0',
  "LAUNCHCHECKDEFAULT=$DefaultValue",
  'AUTO_UPDATE=2',
  'DISABLE_UNINSTALL_SURVEY=1'
)

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
  Write-Output 'Downloading Foxit Reader Enterprise...'
  Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer

  Write-Output 'Installing...'
  Start-Process -Wait msiexec -ArgumentList $ArgumentList
  Write-Output 'Installation complete.'
}
catch { 
  Write-Warning 'Unable to complete installation.'
  Write-Warning $_
}
finally { Remove-Item $Installer -Force -ErrorAction Ignore }
