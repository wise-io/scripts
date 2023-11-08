<#
  .SYNOPSIS
    Installs Google Earth Pro
  .DESCRIPTION
    Installs the latest version of Google Earth Pro.
  .EXAMPLE
    .\InstallGoogleEarth.ps1
  .NOTES
    Author: Aaron J. Stevenson
#>

$Installer = "$env:temp\GoogleEarthPro.exe"
$DownloadURL = 'https://dl.google.com/dl/earth/client/advanced/current/googleearthprowin.exe'

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
  # Download Google Earth Pro
  Write-Output "`nDownloading Google Earth..."
  Invoke-WebRequest -Uri $DownloadURL -OutFile $Installer

  # Install Google Earth Pro
  Write-Output 'Installing Google Earth...'
  Start-Process -Wait -FilePath $Installer -ArgumentList 'OMAHA=1'
  Write-Output 'Installation complete.'
}
catch { 
  Write-Warning "`nUnable to install Google Earth."
  Write-Warning $_
}
finally {
  # Remove Installer
  Remove-Item $Installer -Force -ErrorAction Ignore
}
