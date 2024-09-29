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
  [ValidatePattern('^[a-z]{32}$', ErrorMessage = 'Invalid ID - extension ID should be 32 character alphabetical string')]
  [Parameter(Mandatory = $true)]
  [String]$ID
)

$UpdateURL = 'https://clients2.google.com/service/update2/crx'
$ArchType = if ([System.Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }

function Find-Policies {
  $PolicyRegPath = @('HKLM:\Software\Policies\Google\Chrome\ExtensionInstallBlocklist')
  
  try {
    if ((Test-Path $PolicyRegPath) -and ($null -ne (Get-ItemProperty -Path $PolicyRegPath))) {
      Write-Warning ('Detected Group Policy settings for Google Chrome extensions - manually check for conflicts.') 
    }
  }
  catch {
    Write-Warning 'Unable to detect Google Chrome extension policies.'
    Write-Warning $_
  }
}

function Install-Extension {
  Write-Output "`nInstalling Google Chrome Extension from Chrome Web Store"
  Write-Output "ID: $ID"
  Write-Output "Link: https://chromewebstore.google.com/detail/$ID"

  try {
    # Set registry path
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
    throw $_
  }

}

Find-Policies
Install-Extension
