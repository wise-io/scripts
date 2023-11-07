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

function Enable-SystemProtection {
  try {
    Enable-ComputerRestore -Drive $env:SystemDrive
    Write-Output "`nSystem Protection enabled for [$env:SystemDrive]"
  }
  catch { 
    Write-Warning "Unable to enable System Protection for [$env:SystemDrive]"
    Write-Warning $_
    exit 1
  }
}

function Start-SystemCheckpoint {
  $RegKey = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore'
  $RegProperty = 'SystemRestorePointCreationFrequency'

  try {
    $RegValue = (Get-ItemProperty -Path $RegKey -Name $RegProperty -ErrorAction SilentlyContinue).$RegProperty
    Set-ItemProperty -Path $RegKey -Name $RegProperty -Value 0
    Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS
    if ($RegValue) { Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue }
    else { Remove-ItemProperty -Path $RegKey -Name $RegProperty }
    Write-Output "Checkpoint created."
  }
  catch { 
    Write-Warning 'Unable to create checkpoint.'
    Write-Warning $_
    exit 1
  }
}

Enable-SystemProtection
Start-SystemCheckpoint
