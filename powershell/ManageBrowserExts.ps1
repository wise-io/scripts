<#
  .SYNOPSIS
    Manages browser extensions through local group policy objects (LGPO).
  .DESCRIPTION
    This script sets up browser extension allow-listing (whitelisting) though LGPO.
    Extensions can be added to the allow list by passing their extension ID via the -ChromeExtIDs or -EdgeExtIDs parameters.
  .LINK
    Chrome Extension lookup URL:          https://chrome.google.com/webstore/detail/[ID]
    Edge Extension lookup URL:            https://microsoftedge.microsoft.com/addons/detail/[ID]
    PolicyFileEditor PowerShell Module:   https://github.com/dlwyatt/PolicyFileEditor
  .PARAMETER Audit
    Outputs a table of the current browser extension management policies (LGPO).
  .PARAMETER ChromeExtIDs
    Comma separated list of extension IDs from the Chrome Web Store. Chrome extensions will be added to both Chrome & Edge extension management policies.
    Can be passed as a single string with comma separated IDs, or as multiple comma separated strings.
  .PARAMETER EdgeExtIDs
    Comma separated list of extension IDs from the Microsoft Edge Addon Store.
    Can be passed as a single string with comma separated IDs, or as multiple comma separated strings.
  .PARAMETER ForceInstall
    Adds specified extensions to the force install policy. Can only be used with ChromeExtIDs/EdgeExtIDs parameters
  .PARAMETER Remove
    Removes policies for the specified extension IDs when used with ChromeExtIDs/EdgeExtIDs parameters. When used alone, removes all extension policies (reset)
  .PARAMETER Reset
    Resets all existing browser extension policies (LGPO). Can be used with the ChromeExtIDs/EdgeExtIDs parameters to add new policies after reset.
#>

param (
  [Alias('Report')][switch]$Audit,                  # Audit extension management policies (LGPO)
  [Alias('Chrome')][string[]]$ChromeExtIDs,         # Comma separated list of Chrome extension IDs to allow
  [Alias('Edge')][string[]]$EdgeExtIDs,             # Comma separated list of Edge extension IDs to allow
  [Alias('Force', 'Install')][switch]$ForceInstall, # Force install extensions
  [switch]$Remove,                                  # Removes the specified extensions from management policies (LGPO)
  [Alias('Clear')][switch]$Reset                    # Reset extension management policies (LGPO)
)

$ComputerPolicyFile = ($env:SystemRoot + '\System32\GroupPolicy\Machine\registry.pol')
$ChromeAllowKey = 'Software\Policies\Google\Chrome\ExtensionInstallAllowlist'
$ChromeBlockKey = 'Software\Policies\Google\Chrome\ExtensionInstallBlocklist'
$ChromeForceKey = 'Software\Policies\Google\Chrome\ExtensionInstallForcelist'
$EdgeAllowKey = 'Software\Policies\Microsoft\Edge\ExtensionInstallAllowlist'
$EdgeBlockKey = 'Software\Policies\Microsoft\Edge\ExtensionInstallBlocklist'
$EdgeForceKey = 'Software\Policies\Microsoft\Edge\ExtensionInstallForcelist'
$StartValue = 200 # Helps prevent ADGPO conflicts

# For RMM compatibility
if ($ChromeExtIDs -and $ChromeExtIDs[0] -like '*,*') { $ChromeExtIDs = ($ChromeExtIDs[0] -replace "'", '') -split ',' }
if ($EdgeExtIDs -and $EdgeExtIDs[0] -like '*,*') { $EdgeExtIDs = ($EdgeExtIDs[0] -replace "'", '') -split ',' }

function Get-ExtensionPolicy {
  param ([Parameter(Mandatory = $true)][string[]]$Keys)

  $Policies = @()
  foreach ($Key in $Keys) {
    $Policies += Get-PolicyFileEntry -Path $ComputerPolicyFile -All | Where-Object { $_.Key -eq $Key }
  }

  $GroupBy = @{
    Label = 'Browser';
    Expression = { 
      switch -Wildcard ($_.Key) {
        '*Chrome*' { 'Google Chrome' }
        '*Edge*' { 'Microsoft Edge' }
      }
    }
  }

  $TableProperties = @(
    @{Label = 'Value'; Expression = { $_.ValueName } },
    @{Label = 'Extension ID'; Expression = { $_.Data } },
    @{
      Label = 'Type';
      Expression = {
        switch -Wildcard ( $_.Key ) {
          '*Allow*' { 'Allow' }
          '*Block*' { 'Block' }
          '*Force*' { 'Force' }
        }
      }
    }
  )

  return $Policies | Format-Table -Property $TableProperties -GroupBy $GroupBy
}

function Set-ExtensionPolicy {
  param (
    [Parameter(Mandatory = $true)][string[]]$Keys,
    [Parameter(Mandatory = $true)][string[]]$Exts
  )

  $Policies = @()
  foreach ($Key in $Keys) {
    $CurrentPolicies = Get-PolicyFileEntry -Path $ComputerPolicyFile -All | Where-Object { $_.Key -eq $Key }
    $ValueName = [int]($CurrentPolicies.Name | Measure-Object -Maximum | Select-Object Maximum).Maximum + 1
    if ($ValueName -lt $StartValue) { $ValueName = $StartValue }
    foreach ($Ext in $Exts) {
      if (!$CurrentPolicies -or !$CurrentPolicies.Data.Contains($Ext)) {
        $Policies += New-Object psobject -Property @{Key = $Key; ValueName = $ValueName; Data = $Ext }
        $ValueName += 1
      }
    }
  }

  # Set Policies
  $Policies | Set-PolicyFileEntry -Path $ComputerPolicyFile
}

function Remove-ExtensionPolicy {
  param (
    [Parameter(Mandatory = $true)]
    [string[]]$Keys,
    [string[]]$Values
  )

  $Policies = @()
  foreach ($Key in $Keys) {
    if ($Values) {
      $Policies += Get-PolicyFileEntry -Path $ComputerPolicyFile -All | Where-Object { $_.Key -eq $Key -and $Values -contains $_.Data }
    }
    else {
      $Policies += Get-PolicyFileEntry -Path $ComputerPolicyFile -All | Where-Object { $_.Key -eq $Key }
    }
  }
  # Clear policies
  $Policies | Remove-PolicyFileEntry -Path $ComputerPolicyFile
}

if ($ForceInstall -and $PSBoundParameters.Count -eq 1) {
  Write-Output "`nThe Force parameter must be accompanied by extension IDs from one or both of the Chrome/Edge parameters.`n"
  exit
}

Write-Output "`nChecking for necessary PowerShell modules..."
try {
  # Set PowerShell to TLS 1.2 (https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  # Install NuGet package provider
  if (!(Get-PackageProvider -ListAvailable -Name 'NuGet' -ErrorAction Ignore)) {
    Write-Output 'Installing NuGet package provider...'
    Install-PackageProvider -Name 'NuGet' -MinimumVersion 2.8.5.201 -Force
  }

  # Set PSGallery to trusted repository
  Register-PSRepository -Default -InstallationPolicy 'Trusted' -ErrorAction Ignore
  if (!(Get-PSRepository -Name 'PSGallery' -ErrorAction Ignore).InstallationPolicy -eq 'Trusted') {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'
  }
  
  # Install & Import PolicyFileEditor module
  if (!(Get-Module -ListAvailable -Name 'PolicyFileEditor' -ErrorAction Ignore)) {
    Write-Output 'Installing PolicyFileEditor module...'
    Install-Module -Name 'PolicyFileEditor' -Force
    Import-Module 'PolicyFileEditor'
  }

  Write-Output 'Modules installed.'
}
catch { 
  throw $Error
  exit
}

if ($Remove -or $Reset) {
  $Keys = @($ChromeBlockKey, $ChromeAllowKey, $ChromeForceKey, $EdgeBlockKey, $EdgeAllowKey, $EdgeForceKey)
  if ($Remove -and ($ChromeExtIDs -or $EdgeExtIDs)) {
    Write-Output "`nRemoving specified extensions from management policies..."
    $Values = $ChromeExtIDs + $EdgeExtIDs
    Remove-ExtensionPolicy -Keys $Keys -Values $Values
    Write-Output 'Extensions removed.'
  }
  else {
    Write-Output "`nResetting browser extension policies..."
    Remove-ExtensionPolicy -Keys $Keys
    Write-Output 'Policies reset.'
  }
}

# Add extensions to Chrome
if ($ChromeExtIDs -and !$Remove) {
  Write-Output "`nAdding extensions to Chrome..."
  
  $Keys = @($ChromeAllowKey)
  if ($ForceInstall) { $Keys += @($ChromeForceKey) }
  
  Set-ExtensionPolicy -Keys $Keys -Exts $ChromeExtIDs
  Write-Output 'Extensions added.'
}

# Add extensions to Edge
if (($ChromeExtIDs -or $EdgeExtIDs) -and !$Remove) {
  Write-Output "`nAdding extensions to Edge..."

  $Exts = $ChromeExtIDs + $EdgeExtIDs
  $Keys = @($EdgeAllowKey)
  if ($ForceInstall) { $Keys += @($EdgeForceKey) }
  
  Set-ExtensionPolicy -Keys $Keys -Exts $Exts
  Write-Output 'Extensions added.'
}

# Block extensions not explicitly allowed (Chrome & Edge)
if (!$Remove -and ($ChromeExtIDs -or $EdgeExtIDs)) { Set-ExtensionPolicy -Keys @($ChromeBlockKey, $EdgeBlockKey) -Exts @('*') }

# Update group policy
if ($ChromeExtIDs -or $EdgeExtIDs -or $Remove -or $Reset) {
  Write-Output ''
  gpupdate /force /wait:0
}

if ($Audit -or $PSBoundParameters.Count -eq 0) {
  $Keys = @($ChromeBlockKey, $ChromeAllowKey, $ChromeForceKey, $EdgeBlockKey, $EdgeAllowKey, $EdgeForceKey)
  Get-ExtensionPolicy -Keys $Keys
}
