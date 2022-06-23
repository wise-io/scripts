<#
  .SYNOPSIS
    Manages browser settings through local group policy objects (LGPO).
  .PARAMETER Audit
    Outputs a table of the current browser management policies (LGPO). No new polices will be set.
  .PARAMETER Reset
    Resets all existing browser management policies (LGPO). No new policies will be set.
  .PARAMETER SearchEngine
    Specify the default search engine. Supported values are 'Google' or 'Bing'.
#>

param (
  [Alias('Report')][switch]$Audit,        # Audit extension management policies (LGPO)
  [Alias('Clear')][switch]$Reset,         # Reset browser management policies
  [Alias('Search')][string]$SearchEngine  # Default search engine
)

$ComputerPolicyFile = ($env:SystemRoot + '\System32\GroupPolicy\Machine\registry.pol')
$ChromeKey = 'Software\Policies\Google\Chrome'
$ChromeUpdateKey = 'Software\Policies\Google\Update'
$EdgeKey = 'Software\Policies\Microsoft\Edge'
$EdgeUpdateKey = 'Software\Policies\Microsoft\EdgeUpdate'

# Default Search Engine for browser policies
if ($SearchEngine) {
  switch ($SearchEngine.ToLower()) {
    'google' {
      $SearchURL = '{google:baseURL}search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}ie={inputEncoding}'
      $SuggestURL = '{google:baseURL}complete/search?output=chrome&q={searchTerms}'
    }
    'bing' {
      $SearchURL = '{bing:baseURL}search?q={searchTerms}'
      $SuggestURL = '{bing:baseURL}qbox?query={searchTerms}'
    }
    default { throw "$SearchEngine is not supported." }
  }
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

$Policies = @()
$Keys = @($ChromeKey, $ChromeUpdateKey, $EdgeKey, $EdgeUpdateKey)
Write-Output "`nResetting existing browser management policies..."
foreach ($Key in $Keys) { $Policies += Get-PolicyFileEntry -Path $ComputerPolicyFile -All | Where-Object { $_.Key -eq $Key } }
$Policies | Remove-PolicyFileEntry -Path $ComputerPolicyFile -ErrorAction Stop
Write-Output 'Browser management policies reset.'

if (!$Audit -and !$Reset) {
  $Policies = @()
  $Keys = @($ChromeKey, $EdgeKey)

  # Shared Policies
  foreach ($Key in $Keys) {
    $Policies += @(
      [PSCustomObject]@{ Key = $Key; ValueName = 'AutoplayAllowed'; Data = '0'; Type = 'Dword' }              # Disable media autoplay
      [PSCustomObject]@{ Key = $Key; ValueName = 'BackgroundModeEnabled'; Data = '0'; Type = 'Dword' }        # Disable background mode
      [PSCustomObject]@{ Key = $Key; ValueName = 'ConfigureDoNotTrack'; Data = '1'; Type = 'Dword' }          # Enable Do Not Track
      [PSCustomObject]@{ Key = $Key; ValueName = 'DefaultNotificationsSetting'; Data = '2'; Type = 'Dword' }  # Disable desktop notifications
      [PSCustomObject]@{ Key = $Key; ValueName = 'ForceGoogleSafeSearch'; Data = '1'; Type = 'Dword' }        # Enable Google SafeSearch
    )

    if ($SearchEngine) {
      $Policies += @(
        [PSCustomObject]@{ Key = $Key; ValueName = 'DefaultSearchProviderEnabled'; Data = '1'; Type = 'Dword' }             # Enable default search provider
        [PSCustomObject]@{ Key = $Key; ValueName = 'DefaultSearchProviderName'; Data = $SearchEngine; Type = 'String' }     # Set default search provider name
        [PSCustomObject]@{ Key = $Key; ValueName = 'DefaultSearchProviderSearchURL'; Data = $SearchURL; Type = 'String' }   # Set default search provider
        [PSCustomObject]@{ Key = $Key; ValueName = 'DefaultSearchProviderSuggestURL'; Data = $SuggestURL; Type = 'String' } # Set default suggestion provider
      )
    }
  }

  $Policies += @(
    # Chrome Policies
    [PSCustomObject]@{ Key = $ChromeKey; ValueName = 'AbusiveExperienceInterventionEnforce'; Data = '1'; Type = 'Dword' }         # Prevents sites with abusive experiences from opening new windows/tabs
    [PSCustomObject]@{ Key = $ChromeKey; ValueName = 'AdsSettingForIntrusiveAdsSites'; Data = '2'; Type = 'Dword' }               # Block intrusive Ads
    [PSCustomObject]@{ Key = $ChromeKey; ValueName = 'DisableSafeBrowsingProceedAnyway'; Data = '1'; Type = 'Dword' }             # Prevent SafeBrowsing bypass
    [PSCustomObject]@{ Key = $ChromeKey; ValueName = 'RemoteAccessHostAllowRemoteAccessConnections'; Data = '0'; Type = 'Dword' } # Disable Chrome Remote Access
    [PSCustomObject]@{ Key = $ChromeKey; ValueName = 'SafeSitesFilterBehavior'; Data = '1'; Type = 'Dword' }                      # Filter adult content
    
    # Google Software Updates
    [PSCustomObject]@{ Key = $ChromeUpdateKey; ValueName = 'InstallDefault'; Data = '4'; Type = 'Dword' }   # Allow machine-wide installs only
    [PSCustomObject]@{ Key = $ChromeUpdateKey; ValueName = 'UpdateDefault'; Data = '1'; Type = 'Dword' }    # Always allow updates (all channels)
  
    # Microsoft Edge Policies
    [PSCustomObject]@{ Key = $EdgeKey; ValueName = 'ForceBingSafeSearch'; Data = '1'; Type = 'Dword' }                # Enable Bing Safe Search (Moderate)
    [PSCustomObject]@{ Key = $EdgeKey; ValueName = 'PreventSmartScreenPromptOverride'; Data = '1'; Type = 'Dword' }   # Prevent SmartScreen bypass
    [PSCustomObject]@{ Key = $EdgeKey; ValueName = 'SmartScreenEnabled'; Data = '1'; Type = 'Dword' }                 # Enable SmartScreen
    [PSCustomObject]@{ Key = $EdgeKey; ValueName = 'SmartScreenPuaEnabled'; Data = '1'; Type = 'Dword' }              # Block PUAs/PUPs
    [PSCustomObject]@{ Key = $EdgeKey; ValueName = 'TyposquattingCheckerEnabled'; Data = '1'; Type = 'Dword' }        # Warn user on typosquatting sites
    [PSCustomObject]@{ Key = $EdgeUpdateKey; ValueName = 'UpdateDefault'; Data = '1'; Type = 'Dword' }                # Always allow updates (all channels)
  )
  
  Write-Output "`nSetting browser management policies..."
  $Policies | Set-PolicyFileEntry -Path $ComputerPolicyFile -ErrorAction Stop
  Write-Output "Browser management policies set.`n"
  gpupdate /force /wait:0
}

$Policies = @()
$Keys = @($ChromeKey, $ChromeUpdateKey, $EdgeKey, $EdgeUpdateKey)
foreach ($Key in $Keys) { $Policies += Get-PolicyFileEntry -Path $ComputerPolicyFile -All -ErrorAction Stop | Where-Object { $_.Key -eq $Key } } 
$TableProperties = @(@{Label = 'Policy'; Expression = { $_.ValueName } }, @{Label = 'Value'; Expression = { $_.Data } })
$GroupBy = @{Label = 'Browser'; Expression = { 
    switch -Wildcard ($_.Key) {
      '*Google*' { 'Google Chrome' }
      '*Microsoft*' { 'Microsoft Edge' }
    }
  }
}

Write-Output "`nBrowser Management Policies (LGPO)"
$Policies | Format-Table -Property $TableProperties -GroupBy $GroupBy
