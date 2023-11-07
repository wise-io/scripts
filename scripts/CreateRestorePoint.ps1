<#
  .SYNOPSIS
    Creates a System Restore Point
  .DESCRIPTION
    Enables System Protection on all local drives and creates a System Restore Point.
  .EXAMPLE
    ./CreateRestorePoint.ps1 -Description 'Installed Quickbooks'
  .NOTES
    Author: Aaron Stevenson
#>

param (
  [string]$Description = 'Scripted Checkpoint'
) 

$ErrorActionPreference = 'Stop'

$RegKey = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore'
$RegProperty = 'SystemRestorePointCreationFrequency'
$RegValue = (Get-ItemProperty -Path $RegKey -Name $RegProperty -ErrorAction SilentlyContinue).$RegProperty

try {
  # Enable System Protection
  $LocalDrives = Get-CimInstance -Class 'Win32_LogicalDisk' | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
  Enable-ComputerRestore -Drive $LocalDrives

  # Create Checkpoint
  Set-ItemProperty -Path $RegKey -Name $RegProperty -Value 0
  Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS
  if ($RegValue) { Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue }
  else { Remove-ItemProperty -Path $RegKey -Name $RegProperty }
  Write-Output 'Checkpoint created.'
}
catch { 
  Write-Warning $_
  Write-Warning 'Unable to create checkpoint.'
  exit 1
}
