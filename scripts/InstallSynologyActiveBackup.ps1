<#
  .SYNOPSIS
    Installs Synology Active Backup
  .DESCRIPTION
    Installs and configures the latest Synology Active Backup for Business agent.
  .PARAMETER Address
    The Synology server ip or hostname.
  .PARAMETER Username
    Synology username with permission to use Active Backup.
  .PARAMETER Pass
    Synology user password for username.
  .NOTES
    Author: Aaron Stevenson
  .LINK
    https://www.synology.com/en-global/dsm/feature/active-backup-business/pc
#>

param(
  [Parameter(Mandatory = $true)]
  [Alias('Host', 'Hostname', 'IP')][String]$Address,

  [Parameter(Mandatory = $true)]
  [Alias('User')][String]$Username,

  [Parameter(Mandatory = $true)]
  [Alias('Password')][String]$Pass
)

$Installer = "$env:TEMP\ActiveBackupForBusiness.msi"
$Arguments = (
  '/i',
  $Installer,
  '/qn', 
  '/norestart',
  "ADDRESS=`"$Address`"",
  "USERNAME=`"$Username`"",
  "PASSWORD=`"$Pass`""
)

function Get-DownloadURL {
  $ArchiveURL = 'https://archive.synology.com/download/Utility/ActiveBackupBusinessAgent'
  $ArchivePage = Invoke-WebRequest -Uri $ArchiveURL -UseBasicParsing
  $DownloadPageURL = 'https://archive.synology.com' + (($ArchivePage.Links | Where-Object { $_.href -like '*ActiveBackupBusinessAgent*' })[0]).href
  $DownloadPage = Invoke-WebRequest -Uri $DownloadPageURL -UseBasicParsing
  
  if ([Environment]::Is64BitOperatingSystem) { $OSType = 'x64' }
  else { $OSType = 'x86' }

  return ($DownloadPage.Links | Where-Object { $_.href -like "*$($OStype).msi" }).href
}

# Verify required values
if (!$Address -or !$Username -or !$Pass) {
  Write-Warning 'Unable to retrieve Synology Active Backup configuration information. Aborting...'
  exit 1
}

# Adjust PowerShell Settings
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
  # Download ActiveBackup Agent
  $DownloadURL = Get-DownloadURL
  Write-Output $DownloadURL
  Write-Output 'Downloading Synology ActiveBackup agent...'
  Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer

  # Install ActiveBackup Agent
  Write-Output 'Installing...'
  Start-Process -Wait -FilePath msiexec -ArgumentList $Arguments

  # Check for ActiveBackup Agent
  $Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  $SynologyAgentInstall = Get-ChildItem -Path $Path | Get-ItemProperty | Where-Object { $_.DisplayName -like '*Synology Active Backup*' }
  if ($SynologyAgentInstall) { Write-Output 'Installation complete.' }
  else { throw 'Unable to detect Synology Active Backup agent.' }
}
catch {
  Write-Warning 'Failed to install Synology Active Backup.'
  Write-Warning $_
}
finally {
  Remove-Item $Installer -Force -ErrorAction SilentlyContinue | Out-Null
}
