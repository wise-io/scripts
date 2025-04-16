<#
  .SYNOPSIS
    Disables fast startup and sleep while on AC power
  .DESCRIPTION
    Disables fast startup / sleep on AC power to improve patch compliance
  .NOTES
    Author: Aaron Stevenson
#>

try {
  # Disable fast startup
  Write-Output "`nDisabling fast startup..."
  Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value '0' -Type 'DWord'

  # Disable sleep on ac / hibernate
  Write-Output 'Adjusting power settings...'
  powercfg /change standby-timeout-ac 0
  powercfg /hibernate off
  Write-Output 'Success'
}
catch {
  Write-Warning 'Unable to adjust power settings'
  Write-Output $_
  exit 1
}
