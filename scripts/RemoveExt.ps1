<#
  .SYNOPSIS
    Removes Chrome/Edge browser extension
  .DESCRIPTION
    Silently removes Chrome/Edge browser extension by ID
  .PARAMETER ID
    String parameter for browser extension ID to remove 
  .EXAMPLE
    ./RemoveExt.ps1 -ID 'ghbmnnjooekpmoecnnnilnnbdlolhkhi'
  .NOTES
    Author: Aaron Stevenson
#>

param(
  [ValidatePattern('^[a-z]{32}$')]
  [Parameter(Mandatory = $true)]
  [String]$ID
)

Write-Output "`nRemoving browser extension [$ID]..."

# Remove force installed extension policy entries
try {
  $ForcePolicies = @(
    'HKLM:\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist',
    'HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist'
  ) | Resolve-Path -ErrorAction Ignore

  if ($ForcePolicies) {
    Write-Warning 'Force install extension policies detected'
    Write-Output "Removed extentions may be reinstalled automatically by group policy / Intune.`n"
    Write-Output 'Removing force install policies...'
    foreach ($Policy in $ForcePolicies.Path) {
      $ForceExt = (Get-ItemProperty -Path $Policy).psbase.members | Where-Object { $_.Value -like "$ID*" }
      if ($ForceExt) { Remove-ItemProperty -Path $Policy -Name $ForceExt.Name }
    }
  }
}
catch {
  Write-Warning 'Error encountered while removing force install extension policy entries.'
  Write-Warning $_
  exit 1
}

# Remove globally installed extension registry entries
try {
  $GlobalExts = @(
    "HKLM:\Software\Wow6432Node\Microsoft\Edge\Extensions\$ID",
    "HKLM:\Software\Microsoft\Edge\Extensions\$ID",
    "HKLM:\Software\Wow6432Node\Google\Chrome\Extensions\$ID",
    "HKLM:\Software\Google\Chrome\Extensions\$ID"
  ) | Resolve-Path -ErrorAction Ignore

  if ($GlobalExts) {
    foreach ($Ext in $GlobalExts.Path) {
      Write-Output 'Removing global install registry entires...'
      Remove-Item -Path $Ext -Force -Recurse
    }
  }
}
catch {
  Write-Warning 'Error encountered while removing global extension installation registry keys.'
  Write-Warning $_
  exit 1
}

# Remove associated browser profile extension directories
try {
  $UserExtDirs = @(
    "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Extensions\$ID",
    "$env:SystemDrive\Users\*\AppData\Local\Google\Chrome\User Data\*\Extensions\$ID"
  ) | Resolve-Path -ErrorAction Ignore

  if ($UserExtDirs) { 
    foreach ($Dir in $UserExtDirs.Path) {
      Write-Output "Removing [$Dir]..."
      Remove-Item -Path $Dir -Force -Recurse
    }
  }
}
catch {
  Write-Warning 'Error encountered while removing browser profile extension directories.'
  Write-Warning $_
  exit 1
}
