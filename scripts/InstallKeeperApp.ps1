<#
  .SYNOPSIS
    Installs Keeper Password Manager
  .DESCRIPTION
    Silently installs the latest Keeper Password Manager desktop application for the logged in user
  .LINK
    https://docs.keeper.io/en/enterprise-guide/deploying-keeper-to-end-users/desktop-application
  .NOTES
    Author: Aaron Stevenson
#>

# Adjust Powershell Settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
  # Check for existing install
  $Installed = Get-AppxPackage -Name 'KeeperSecurityInc.KeeperPasswordManager'
  if ($Installed) {
    Write-Output "`nKeeper Password Manager [$($Installed.Version)] already installed for user $env:USERNAME"
    exit 0
  }
  
  # Patterns to omit in winget output
  $Spinner = ('\', '/', '|', '-' | ForEach-Object { "^\s*\$_\s*$" }) -join '|'
  $ProgressBars = ('█', '▒' | ForEach-Object { "^.+\$_.+`$" }) -join '|'
  $BlankLine = '^\s*$'
  $Skip = "$Spinner|$ProgressBars|$BlankLine"

  # Install via winget
  Write-Output "`nInstalling Keeper Password Manager..."
  (winget install 9N040SRQ0S8C --source msstore --accept-package-agreements --accept-source-agreements) -split '(\r?\n)' | Where-Object { $_ -notmatch $Skip } | Out-String
  
  # Confirm Installation
  $Installed = Get-AppxPackage -Name 'KeeperSecurityInc.KeeperPasswordManager'
  if ($Installed) { Write-Output "Successfully installed Keeper Password Manager [$($Installed.Version)]" }
  else { throw }
}
catch { 
  Write-Warning "Error installing Keeper Password Manager`n$_"
  exit 1
}
