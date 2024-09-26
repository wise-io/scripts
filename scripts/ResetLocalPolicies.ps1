<#
  .SYNOPSIS
    Clears (resets) local group policies.
  .DESCRIPTION
    Clears (resets) local group policies by deleting registry.pol and associated files after creating a backup.
  .EXAMPLE
    ./ResetLocalPolicies.ps1
#>

# Local group policy files
$PolicyFiles = "$env:SystemRoot\System32\GroupPolicy"
$PolicyUserFiles = "$env:SystemRoot\System32\GroupPolicyUsers"

function Backup-Policies {
  # Define variables for policy backups
  $Timestamp = Get-Date -Format 'yyyy-MM-dd HH.mm.ss'
  $BackupDir = "$env:SystemDrive\Backups\Group Policy\$Timestamp"

  Write-Output "`nCreating backups of local group policy files..."
  try {
    if ((Test-Path $PolicyFiles) -or (Test-Path $PolicyUserFiles)) {
      if (Test-Path $PolicyFiles) { Copy-Item -Path $PolicyFiles -Destination $BackupDir -Recurse }
      if (Test-Path $PolicyUserFiles) { Copy-Item -Path $PolicyUserFiles -Destination $BackupDir -Recurse }
      Write-Output "Complete - backups stored at $BackupDir."
    }
    else { Write-Warning 'No existing local group policy files found - backup aborted.' }
  }
  catch {
    Write-Warning 'Error creating backup.'
    Write-Warning $_
  }
}

function Reset-Policies {
  # Clear existing local policies
  Write-Output "`nResetting local policies..."

  try {
    # Clears policy files
    Remove-Item -Path $PolicyFiles -Recurse -Force -ErrorAction Ignore
    Remove-Item -Path $PolicyUserFiles -Recurse -Force -ErrorAction Ignore

    # Apply new policies
    gpupdate /force /wait:0
  }
  catch {
    Write-Warning 'Error resetting local group policies.'
    Write-Warning $_
  }
}

$ErrorActionPreference = 'Stop'
Backup-Policies
Reset-Policies
