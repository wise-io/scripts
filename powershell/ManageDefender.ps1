# Manage Windows Defender & Windows Firewall via Local Group Policy
$ComputerPolicyFile = ($env:SystemRoot + '\System32\GroupPolicy\Machine\registry.pol')
$DefenderKey = 'Software\Policies\Microsoft\Windows Defender'
$FirewallKey = 'Software\Policies\Microsoft\WindowsFirewall'
$ExploitGuardKey = 'Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard'

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

$Policies = @(
  # SmartScreen Policies
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\System'; ValueName = 'EnableSmartScreen'; Data = '1'; Type = 'Dword' } # Enable SmartScreen in Explorer
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\System'; ValueName = 'ShellSmartScreenLevel'; Data = 'Warn'; Type = 'String' } # Set SmartScreen level in Explorer to Warn
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter'; ValueName = 'EnabledV9'; Data = '1'; Type = 'Dword' } # Enable SmartScreen in Microsoft Edge (Old)
  [PSCustomObject]@{Key = 'Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter'; ValueName = 'PreventOverride'; Data = '1'; Type = 'Dword' } # Prevent SmartScreen bypass in Microsoft Edge (Old)

  # Windows Defender Firewall Policies
  [PSCustomObject]@{Key = "$FirewallKey\DomainProfile"; ValueName = 'EnableFirewall'; Data = '1'; Type = 'Dword' } # Enable Domain profile
  [PSCustomObject]@{Key = "$FirewallKey\DomainProfile\Logging"; ValueName = 'LogDroppedPackets'; Data = '1'; Type = 'Dword' } # Enable Domain profile dropped packet logging
  [PSCustomObject]@{Key = "$FirewallKey\PrivateProfile"; ValueName = 'EnableFirewall'; Data = '1'; Type = 'Dword' } # Enable Private profile
  [PSCustomObject]@{Key = "$FirewallKey\PrivateProfile\Logging"; ValueName = 'LogDroppedPackets'; Data = '1'; Type = 'Dword' } # Enable Private profile dropped packet logging
  [PSCustomObject]@{Key = "$FirewallKey\PublicProfile"; ValueName = 'EnableFirewall'; Data = '1'; Type = 'Dword' } # Enable Public profile
  [PSCustomObject]@{Key = "$FirewallKey\PublicProfile\Logging"; ValueName = 'LogDroppedPackets'; Data = '1'; Type = 'Dword' } # Enable Public profile dropped packet logging

  # Windows Defender Policies
  [PSCustomObject]@{Key = "$DefenderKey\UX Configuration"; ValueName = 'UILockdown'; Data = '0'; Type = 'Dword' } # Enable Defender AV UI
  [PSCustomObject]@{Key = "$DefenderKey"; ValueName = 'PUAProtection'; Data = '1'; Type = 'Dword' } # Block potentially unwanted programs/apps
  [PSCustomObject]@{Key = "$DefenderKey"; ValueName = 'DisableRoutinelyTakingAction'; Data = '0'; Type = 'Dword' } # Enable automated remediation
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableRealtimeMonitoring'; Data = '0'; Type = 'Dword' } # Enable real-time protection
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableBehaviorMonitoring'; Data = '0'; Type = 'Dword' } # Enable behavior monitoring
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableInformationProtectionControl'; Data = '0'; Type = 'Dword' } # Enable information protection control
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableIntrusionPreventionSystem'; Data = '0'; Type = 'Dword' } # Enable intrusion prevention system
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableScanOnRealtimeEnable'; Data = '0'; Type = 'Dword' } # Scan when Defender is enabled
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableOnAccessProtection'; Data = '0'; Type = 'Dword' } # Monitor file/program activity
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableIOAVProtection'; Data = '0'; Type = 'Dword' } # Scan downloaded files/attachments
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'RealtimeScanDirection'; Data = '0'; Type = 'Dword' } # Monitor incoming/outgoing file activity
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'DisableScriptScanning'; Data = '0'; Type = 'Dword' } # Scan scripts
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'LocalSettingOverrideDisableOnAccessProtection'; Data = '0'; Type = 'Dword' } # Prevent disabling on access protection
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'LocalSettingOverrideRealtimeScanDirection'; Data = '0'; Type = 'Dword' } # Prevent disabling monitoring incoming/outgoing file activity
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'LocalSettingOverrideDisableIOAVProtection'; Data = '0'; Type = 'Dword' } # Prevent disabling scanning downloaded files
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'LocalSettingOverrideDisableBehaviorMonitoring'; Data = '0'; Type = 'Dword' } # Prevent disabling behavior monitoring
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'LocalSettingOverrideDisableIntrusionPreventionSystem'; Data = '0'; Type = 'Dword' } # Prevent disabling intrusion prevention system
  [PSCustomObject]@{Key = "$DefenderKey\Real-Time Protection"; ValueName = 'LocalSettingOverrideDisableRealtimeMonitoring'; Data = '0'; Type = 'Dword' } # Prevent disabling real-time protection
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'CheckForSignaturesBeforeRunningScan'; Data = '1'; Type = 'Dword' } # Check for signature updates before scanning
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'LowCpuPriority'; Data = '1'; Type = 'Dword' } # Enable low CPU priority for scanning
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableRestorePoint'; Data = '0'; Type = 'Dword' } # Create a restore point prior to cleaning
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableArchiveScanning'; Data = '0'; Type = 'Dword' } # Scan archive files
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableScanningNetworkFiles'; Data = '0'; Type = 'Dword' } # Scan network files
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisablePackedExeScanning'; Data = '0'; Type = 'Dword' } # Scan packed executables
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableRemovableDriveScanning'; Data = '0'; Type = 'Dword' } # Scan removable drives
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'QuickScanInterval'; Data = '24'; Type = 'Dword' } # Enable daily quick scans
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'ScheduleDay'; Data = '1'; Type = 'Dword' } # Schedule scans on Sundays
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'ScanParameters'; Data = '2'; Type = 'Dword' } # Set scheduled scan type to full
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableCatchupFullScan'; Data = '0'; Type = 'Dword' } # Enable catch-up full scans
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableCatchupQuickScan'; Data = '0'; Type = 'Dword' } # Enable catch-up quick scans
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableEmailScanning'; Data = '0'; Type = 'Dword' } # Scan emails
  [PSCustomObject]@{Key = "$DefenderKey\Scan"; ValueName = 'DisableHeuristics'; Data = '0'; Type = 'Dword' } # Enable heuristics
  [PSCustomObject]@{Key = "$DefenderKey\Signature Updates"; ValueName = 'ForceUpdateFromMU'; Data = '1'; Type = 'Dword' } # Download updates from Microsoft Update
  [PSCustomObject]@{Key = "$DefenderKey\Signature Updates"; ValueName = 'UpdateOnStartUp'; Data = '1'; Type = 'Dword' } # Update on startup
  [PSCustomObject]@{Key = "$DefenderKey\Signature Updates"; ValueName = 'RealtimeSignatureDelivery'; Data = '1'; Type = 'Dword' } # Enable realtime signature update
  [PSCustomObject]@{Key = "$DefenderKey\Spynet"; ValueName = 'SpynetReporting'; Data = '2'; Type = 'Dword' } # Join Microsoft MAPS
  [PSCustomObject]@{Key = "$DefenderKey\Spynet"; ValueName = 'SubmitSamplesConsent'; Data = '1'; Type = 'Dword' } # Send safe file samples to MAPS
  [PSCustomObject]@{Key = "$ExploitGuardKey\Controlled Folder Access"; ValueName = 'EnableControlledFolderAccess'; Data = '2'; Type = 'Dword' } # Enable Controlled Folder Access (audit)
  [PSCustomObject]@{Key = "$ExploitGuardKey\Network Protection"; ValueName = 'EnableNetworkProtection'; Data = '1'; Type = 'Dword' } # Block dangerous websites

  # Windows Defender ASR
  # ASR Rules - 0 (Off), 1 (Block), or 2 (Audit)
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR"; ValueName = 'ExploitGuard_ASR_Rules'; Data = '0'; Type = 'Dword' } # Enable ASR
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c'; Data = '0'; Type = 'String' } # Block Adobe Reader from creating child processes
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = 'D4F940AB-401B-4EFC-AADC-AD5F3C50688A'; Data = '0'; Type = 'String' } # Block all Office applications from creating child processes
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2'; Data = '0'; Type = 'String' } # Block credential stealing from the Windows local security authority subsystem (lsass.exe)
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = 'BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550'; Data = '0'; Type = 'String' } # Block executable content from email client and webmail
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '01443614-cd74-433a-b99e-2ecdc07bfc25'; Data = '0'; Type = 'String' } # Block executable files from running unless they meet a prevalence, age, or trusted list criterion
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '5BEB7EFE-FD9A-4556-801D-275E5FFC04CC'; Data = '0'; Type = 'String' } # Block execution of potentially obfuscated scripts
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = 'D3E037E1-3EB8-44C8-A917-57927947596D'; Data = '0'; Type = 'String' } # Block JavaScript or VBScript from launching downloaded executable content
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '3B576869-A4EC-4529-8536-B80A7769E899'; Data = '0'; Type = 'String' } # Block Office applications from creating executable content
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84'; Data = '0'; Type = 'String' } # Block Office applications from injecting code into other processes
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '26190899-1602-49e8-8b27-eb1d0a1ce869'; Data = '0'; Type = 'String' } # Block Office communication application from creating child processes
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = 'e6db77e5-3df2-4cf1-b95a-636979351e5b'; Data = '0'; Type = 'String' } # Block persistence through WMI event subscription
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = 'd1e49aac-8f56-4280-b9ba-993a6d77406c'; Data = '0'; Type = 'String' } # Block process creations originating from PSExec and WMI commands
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = 'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4'; Data = '0'; Type = 'String' } # Block untrusted and unsigned processes that run from USB
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = '92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B'; Data = '0'; Type = 'String' } # Block Win32 API calls from Office macros
  # [PSCustomObject]@{Key = "$ExploitGuardKey\ASR\Rules"; ValueName = 'c1db55ab-c21a-4637-bb3f-a12568109d35'; Data = '0'; Type = 'String' } # Use advanced protection against ransomware
)

try {
  Write-Output "`nSetting security policies..."
  $Policies | Set-PolicyFileEntry -Path $ComputerPolicyFile -ErrorAction Stop
  Write-Output "Security policies set.`n"

  # Set Auditing Policies
  Write-Output 'Setting auditing policies...'
  Auditpol /set /category:"Logon/Logoff" /Success:enable /Failure:enable | Out-Null
  Auditpol /set /category:"Account Logon" /Success:enable /Failure:enable | Out-Null
  Auditpol /set /category:"Account Management" /Success:enable /Failure:enable | Out-Null
  Auditpol /set /category:"DS Access" /Failure:enable | Out-Null
  Auditpol /set /category:"System" /Failure:enable | Out-Null
  Write-Output "Auditing policies set.`n"

  # Update Policies
  gpupdate /force /wait:0
}
catch { throw $Error }
