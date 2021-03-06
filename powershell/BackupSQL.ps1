<#
  .SYNOPSIS
    Backup all SQL databases
  .DESCRIPTION
    Performs a backup of all SQL databases on all SQL instances of localhost
  .NOTES
    Backups are stored in the default backup location of the server under the name databasename.bak
    Previous backup files named databasename.bak will be overwritten
    Backups are not performed when the -History switch is used
  .EXAMPLE
    ./BackupSQL.ps1
    ./BackupSQL.ps1 -History
#>

param (
  [switch]$History # Output backup history
) 

Write-Output 'Checking for necessary PowerShell modules...'

try {
  # Set PowerShell to TLS 1.2 (See here: https://docs.microsoft.com/en-us/powershell/module/powershellget/install-module?view=powershell-7.2#notes)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  # Install NuGet package provider
  if (!(Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction Ignore)) {
    Write-Output 'Installing NuGet package provider...'
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
  }

  # Set PSGallery to trusted repository
  Register-PSRepository -Default -InstallationPolicy 'Trusted' -ErrorAction Ignore
  if (!(Get-PSRepository -Name 'PSGallery' -ErrorAction Ignore).InstallationPolicy -eq 'Trusted') {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
  }

  # Install & Import SqlServer module
  if (!(Get-Module -ListAvailable -Name SqlServer -ErrorAction Ignore)) {
    Write-Output 'Installing SqlServer module...'
    Install-Module -Name SqlServer -AllowClobber
    Import-Module SqlServer
  }
}
catch { 
  throw $Error 
  exit
}

Write-Output 'Necessary modules installed.'

# Backup SQL databases in all instances on localhost
$Instances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
foreach ($Instance in $Instances) {
  if ($History) {
    Write-Output "`nBackup history for localhost\$Instance (past month):"
    Get-SqlBackupHistory -ServerInstance "localhost\$Instance" -Since LastMonth | Format-Table -Property 'DatabaseName', 'BackupSetType', 'BackupStartDate', 'BackupFinishDate', 'CompressedBackupSize'
  }
  else {
    $Databases = Get-SqlDatabase -ServerInstance "localhost\$Instance" | Where-Object { $_.Name -ne 'tempdb' }
    Write-Output "`nDatabases in localhost\$Instance`:"
    Write-Output $Databases | Format-Table -Property 'Name', 'Status', 'Size', 'Owner'
    Write-Output '' # For output formatting

    foreach ($Database in $Databases) {
      Write-Output "Performing backup of $Database..."
      Backup-SqlDatabase -ServerInstance "localhost\$Instance" -Database $Database.name -Initialize
    }
  }
}

if ($History) { Write-Output 'Backups were not performed.' } else { Write-Output 'Backup jobs complete.' }
