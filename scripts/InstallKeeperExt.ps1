<#
  .SYNOPSIS
    Installs Keeper Password Manager Browser Extensions
  .DESCRIPTION
    Silently installs the Chrome and Edge browser extensions for Keeper Password Manager.
  .PARAMETER Force
    If enabled, Keeper will be added to the force install lists for Chrome and Edge.
  .EXAMPLE
    ./InstallKeeperExt.ps1 -Force
  .NOTES
    Author: Aaron Stevenson
  .LINK
    https://www.keepersecurity.com/
#>

param([Switch]$Force)

$Extensions = @(
  [PSCustomObject]@{ 
    Browser   = 'Chrome'
    ID        = 'bfogiafebfohielmmehodmfbbebbbpei'
    LinkBase  = 'https://chromewebstore.google.com/detail/'
    Reg       = 'Google\Chrome'
    UpdateURL = 'https://clients2.google.com/service/update2/crx'
  }
  
  [PSCustomObject]@{
    Browser   = 'Edge'
    ID        = 'lfochlioelphaglamdcakfjemolpichk'
    LinkBase  = 'https://microsoftedge.microsoft.com/addons/detail/'
    Reg       = 'Microsoft\Edge'
    UpdateURL = 'https://edge.microsoft.com/extensionwebstorebase/v1/crx'
  }
)

function Find-Policies {
  $PolicyPaths = @(
    'HKLM:\Software\Policies\Google\Chrome\ExtensionInstallBlocklist',
    'HKLM:\Software\Policies\Microsoft\Edge\ExtensionInstallBlocklist'
  )
  
  # Check for extension policies
  try {
    foreach ($RegPath in $PolicyPaths) {
      if ((Test-Path $RegPath) -and ($null -ne (Get-ItemProperty -Path $RegPath))) {
        Write-Warning ('Detected possible Group Policy settings for browser extensions - manually check for conflicts.') 
      }
    }
  }
  catch {
    Write-Warning 'Unable to detect browser extension policies.'
    Write-Warning $_
  }
}

function Install-Extensions {
  $ArchType = if ([System.Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
  
  foreach ($Ext in $Extensions) {
    Write-Output "`nKeeper Password Manager $($Ext.Browser) Extension"
    Write-Output "ID: $($Ext.ID)"
    Write-Output "Link: $($Ext.LinkBase)$($Ext.ID)"

    try {
      Write-Output "`nAdding to globally installed $($Ext.Browser) extensions..."

      # Set registry path
      if ($ArchType -eq 'x64') { $RegPath = "HKLM:\Software\Wow6432Node\$($Ext.Reg)\Extensions" }
      else { $RegPath = "HKLM:\Software\$($Ext.Reg)\Extensions" }
      
      # Create extension registry key and necessary properties
      $ExtRegKey = Join-Path -Path $RegPath -ChildPath $Ext.ID
      New-Item -Path $ExtRegKey -Force | Out-Null
      New-ItemProperty -Path $ExtRegKey -Name 'update_url' -PropertyType 'String' -Value $Ext.UpdateURL -Force | Out-Null

      # Force install extension
      if ($Force) {
        Write-Output "Adding to force installed $($Ext.Browser) extensions..."
        
        $ForcePolicyPath = "HKLM:\Software\Policies\$($Ext.Reg)\ExtensionInstallForcelist"
        $Forced = $false 
        $Max = 1
        [String]$PropertyValue = "$($Ext.ID);$($Ext.UpdateURL)"
        
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
    }
    catch {
      Write-Warning "Issue encountered installing Keeper $($Ext.Browser) Extension [$($Ext.ID)]"
      throw $_
    }
  }
}

Find-Policies
Install-Extensions
