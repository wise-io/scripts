<#
  .SYNOPSIS
    Backup all SQL databases
  .DESCRIPTION
    Performs a backup of all SQL databases on all SQL instances of localhost.
    Backups are stored in the default backup location of the server under the name databasename.bak
  .PARAMETER AuditOnly
    Switch parameter: when used, recent sql backup history will be displayed. No new backups will be performed.
  .EXAMPLE
    .\BackupSQL.ps1
  .NOTES
    Author: Aaron Stevenson
#>

param (
  [switch]$AuditOnly # Audit recent SQL backups
) 

function Install-PSModule {
  <#
  .SYNOPSIS
    Installs and imports the provided PowerShell Modules
  .EXAMPLE
    Install-PSModule -Modules @('ExchangeOnlineManagement')
  #>
  
  param(
    [Parameter(Position = 0, Mandatory = $true)]
    [String[]]$Modules
  )

  Write-Output "`nChecking for necessary PowerShell modules..."
  try {
    # Set PowerShell to TLS 1.2 (https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/)
    if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

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
  
    # Install & import modules
    ForEach ($Module in $Modules) {
      if (!(Get-Module -ListAvailable -Name $Module -ErrorAction Ignore)) {
        Write-Output "`nInstalling $Module module..."
        Install-Module -Name $Module -Force
        Import-Module $Module
      }
    }

    Write-Output 'Modules installed successfully.'
  }
  catch { 
    Write-Warning 'Unable to install modules.'
    Write-Warning $_
    exit 1
  }
}

function Get-SqlBackupAudit {
  foreach ($Instance in $Instances) {
    Write-Output "`nBackup history for localhost\$Instance (past month):"
    Get-SqlBackupHistory -ServerInstance "localhost\$Instance" -Since LastMonth | Format-Table -Property 'DatabaseName', 'BackupSetType', 'BackupStartDate', 'BackupFinishDate', 'CompressedBackupSize'
  }
  Write-Output 'No new backups were performed.'
}

function Start-SqlBackups {
  foreach ($Instance in $Instances) {
    $Databases = Get-SqlDatabase -ServerInstance "localhost\$Instance" | Where-Object { $_.Name -ne 'tempdb' }
    Write-Output "`nDatabases in localhost\$Instance`:"
    Write-Output $Databases | Format-Table -Property 'Name', 'Status', 'Size', 'Owner'
    Write-Output '' # For output formatting

    foreach ($Database in $Databases) {
      Write-Output "Performing backup of $Database..."
      Backup-SqlDatabase -ServerInstance "localhost\$Instance" -Database $Database.name -Initialize
    }
  }
  Write-Output 'Backup jobs complete.' 
}

Install-PSModule -Modules @('SqlServer')

# Backup SQL databases in all instances on localhost
$Instances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
if ($AuditOnly) { Get-SqlBackupAudit }
else { Start-SqlBackups }
