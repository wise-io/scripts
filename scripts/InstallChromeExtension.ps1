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
  [ValidatePattern('^[a-z]{32}$')]
  [Parameter(Mandatory = $true)]
  [String]$ID,
  [Switch]$Force
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

function Get-ChromeExtName {
  param(
    [ValidatePattern('^[a-z]{32}$')]
    [Parameter(Mandatory = $true)]
    [String]$ExtID
  )
  
  $ProgressPreference = 'SilentlyContinue'

  # Fetch extension webpage
  $URL = "https://chromewebstore.google.com/detail/$ExtID"
  try { $Data = Invoke-WebRequest -Uri $URL -UseBasicParsing } catch { }

  # Find title and format
  [Regex]$Regex = '(?<=og:title" content=")([\S\s]*?)(?=">)'
  $ExtName = $Regex.Match($Data.Content).Value -replace ' - Chrome Web Store', ''
  if (($ExtName -eq '') -or ($ExtName -eq 'Chrome Web Store')) { $ExtName = 'Unknown Extension' }
  else {
    Add-Type -AssemblyName System.Web
    $ExtName = [System.Web.HttpUtility]::HtmlDecode($ExtName)
  }

  return $ExtName
}

function Install-Extension {
  $Name = Get-ChromeExtName -ExtID $ID
  
  Write-Output "`nInstalling $Name"
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

    # Force install extension
    if ($Force) {
      Write-Output 'Adding to force installed Chrome extensions...'

      $ForcePolicyPath = 'HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist'
      $Forced = $false 
      $Max = 1
      [String]$PropertyValue = "$ID;$UpdateURL"
            
      # Check if force install extension policies exist
      if (!(Test-Path $ForcePolicyPath)) { New-Item -Path $ForcePolicyPath -Force | Out-Null }
      else {
        $ForcePolicy = Get-Item -Path $ForcePolicyPath
        $Max = ($ForcePolicy | Select-Object -ExpandProperty property | Sort-Object -Descending)[0]
              
        # Check if extension has already been added to force install list
        if ((Get-ItemPropertyValue -Path $ForcePolicyPath -Name $ForcePolicy.property) -match $PropertyValue) { $Forced = $true }
      }
    
      # Add extension to force install list 
      if (!$Forced) { New-ItemProperty -Path $ForcePolicyPath -Name ($Max + 100) -PropertyType 'String' -Value $PropertyValue | Out-Null }
    }

    Write-Output 'Complete - relaunch browser to finish installation.'
  }
  catch {
    Write-Warning "Unable to install Chrome Extension [$ID]"
    throw $_
  }
}

Find-Policies
Install-Extension
