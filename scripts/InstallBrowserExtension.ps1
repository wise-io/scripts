<#
  .SYNOPSIS
    Installs a browser extension by ID
  .DESCRIPTION
    Silently installs a Google Chrome or Microsoft Edge extension by extension ID
  .PARAMETER ID
    String parameter for the browser extension ID
  .PARAMETER Chrome
    Switch parameter to install a Chrome Extension
  .PARAMETER Edge
    Switch parameter to install an Edge Extension 
  .PARAMETER Force
    Switch parameter to force install the browser extension
  .EXAMPLE
    ./InstallBrowserExtension.ps1 -ID 'ghbmnnjooekpmoecnnnilnnbdlolhkhi' -Chrome
  .NOTES
    Author: Aaron Stevenson
#>

param(
  [ValidatePattern('^[a-z]{32}$')]
  [Parameter(Mandatory = $true)]
  [String]$ID,

  [Parameter(ParameterSetName = 'Chrome')]
  [Switch]$Chrome,

  [Parameter(ParameterSetName = 'Edge')]
  [Switch]$Edge,

  [Switch]$Force
)

function Find-Policies {
  # Check for extension policies
  try {
    $BlockPolicy = "HKLM:\Software\Policies\$($Ext.Reg)\ExtensionInstallBlocklist"
    if ((Test-Path $BlockPolicy) -and ($null -ne (Get-ItemProperty -Path $BlockPolicy))) {
      Write-Warning ('Detected possible Group Policy settings for browser extensions - manually check for conflicts.') 
    }
  }
  catch {
    Write-Warning 'Unable to detect browser extension policies.'
    Write-Warning $_
  }
}

function Get-ExtName {
  $ProgressPreference = 'SilentlyContinue'

  # Fetch extension webpage
  try { $Data = Invoke-WebRequest -Uri $Ext.StoreURL -UseBasicParsing } catch { }

  # Find title and format
  [Regex]$Regex = $Ext.Regex
  $ExtName = $Regex.Match($Data.Content).Value -replace "- $($Ext.Store)", ''
  if (($ExtName -eq '') -or ($ExtName -eq $Ext.Store)) { $ExtName = "Unknown $($Ext.Browser) Extension" }
  else {
    Add-Type -AssemblyName System.Web
    $ExtName = [System.Web.HttpUtility]::HtmlDecode($ExtName)
  }

  return $ExtName
}

function Install-Extension {
  Write-Output "`nInstalling $($Ext.Browser) extension..."
  Write-Output "`n$($Ext.Name)"
  Write-Output "ID: $($Ext.ID)"
  Write-Output "Link: $($Ext.StoreURL)"

  try {
    # Set registry path
    $ArchType = if ([System.Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    if ($ArchType -eq 'x64') { $InstallKey = "HKLM:\Software\Wow6432Node\$($Ext.Reg)\Extensions\$($Ext.ID)" }
    else { $InstallKey = "HKLM:\Software\$($Ext.Reg)\Extensions\$($Ext.ID)" }

    # Create extension registry key and necessary properties
    Write-Output "`nAdding $($Ext.Browser) extension registry key..."
    New-Item -Path $InstallKey -Force | Out-Null
    New-ItemProperty -Path $InstallKey -Name 'update_url' -PropertyType 'String' -Value $Ext.UpdateURL -Force | Out-Null

    # Force install extension
    if ($Force) {
      Write-Output "Adding to force installed $($Ext.Browser) extensions list..."
      $ForceInstallKey = "HKLM:\Software\Policies\$($Ext.Reg)\ExtensionInstallForcelist"
      $PropertyValue = $Ext.ID + ';' + $Ext.UpdateURL
      $Forced = $false 
      $Max = 1
      
      # Check if force install extension policies exist
      if (!(Test-Path $ForceInstallKey)) { New-Item -Path $ForceInstallKey -Force | Out-Null }
      else {
        # Check if extension has already been added to force install list
        $ForcePolicy = Get-Item -Path $ForceInstallKey
        $Max = ($ForcePolicy | Select-Object -ExpandProperty property | Sort-Object -Descending)[0]
        if ((Get-ItemPropertyValue -Path $ForceInstallKey -Name $ForcePolicy.property) -match $PropertyValue) { $Forced = $true }
      }
    
      # Add extension to force install list 
      if (!$Forced) { New-ItemProperty -Path $ForceInstallKey -Name ($Max + 100) -PropertyType 'String' -Value $PropertyValue | Out-Null }
    }

    Write-Output "`nComplete - relaunch browser to finish installation."
  }
  catch {
    Write-Warning "Unable to install $($Ext.Browser) extension [$($Ext.ID)]"
    throw $_
  }
}

# Build Extension Object
if ($Chrome) {
  $Ext = [PSCustomObject]@{
    Browser   = 'Chrome'
    Reg       = 'Google\Chrome'
    Regex     = '(?<=og:title" content=")([\S\s]*?)(?=">)'
    Store     = 'Chrome Web Store'
    StoreURL  = 'https://chromewebstore.google.com/detail/'
    UpdateURL = 'https://clients2.google.com/service/update2/crx'
  }
}
elseif ($Edge) {
  $Ext = [PSCustomObject]@{
    Browser   = 'Edge'
    Reg       = 'Microsoft\Edge'
    Regex     = '(?<=<title>)([\S\s]*?)(?=<\/title>)'
    Store     = 'Microsoft Edge Addons'
    StoreURL  = 'https://microsoftedge.microsoft.com/addons/detail/'
    UpdateURL = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
  }
}

$Ext.StoreURL = $Ext.StoreURL + $ID
$Ext | Add-Member -Name 'ID' -Type NoteProperty -Value $ID
$Ext | Add-Member -Name 'Name' -Type NoteProperty -Value (Get-ExtName)

Find-Policies
Install-Extension
