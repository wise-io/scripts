<#
  .SYNOPSIS
    Installs a Chrome Extension by ID
  .DESCRIPTION
    Silently installs a Google Chrome extension from the Chrome Web Store.
  .PARAMETER ID
    Google Chrome Extension ID 
  .EXAMPLE
    ./InstallChromeExt.ps1 -ID 'ghbmnnjooekpmoecnnnilnnbdlolhkhi'
  .NOTES
    Author: Aaron Stevenson
#>

param(
  [Parameter(Mandatory = $true)]
  [String]$ID
)

$UpdateURL = 'https://clients2.google.com/service/update2/crx'
$ErrorActionPreference = 'Stop'

Write-Output "`nInstalling Google Chrome Extension from Chrome Web Store"
Write-Output "ID: $ID"
Write-Output "Link: https://chromewebstore.google.com/detail/$ID"

try {
  # Set registry path
  $ArchType = if ([System.Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
  if ($ArchType -eq 'x64') { $RegPath = 'HKLM:\Software\Wow6432Node\Google\Chrome\Extensions' }
  else { $RegPath = 'HKLM:\Software\Google\Chrome\Extensions' }

  # Create extension registry key and necessary properties
  Write-Output "`nAdding extension registry key..."
  $ExtRegKey = Join-Path -Path $RegPath -ChildPath $ID
  New-Item -Path $ExtRegKey -Force | Out-Null
  New-ItemProperty -Path $ExtRegKey -Name 'update_url' -PropertyType 'String' -Value $UpdateURL -Force | Out-Null

  Write-Output 'Complete - relaunch Chrome to finish installation.'
}
catch {
  Write-Warning "Unable to install Chrome Extension [$ID]"
  Write-Warning $_
  exit 1
}
