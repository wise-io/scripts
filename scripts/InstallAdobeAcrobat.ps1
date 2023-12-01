<#
  .SYNOPSIS
    Installs Adobe Acrobat DC
  .DESCRIPTION
    Downloads and installs Acrobat as a unified application that provides the functionality
    of Adobe Reader or Adobe Acrobat depending on the user's license.
  .PARAMETER Path
    Optional - Local path to cached zip archive containing Adobe Acrobat installation files.
  .NOTES
    Author: Aaron J. Stevenson
  .LINK
    https://helpx.adobe.com/acrobat/kb/acrobat-dc-downloads.html
#>

param (
  [ValidateScript({
      if ([System.IO.Path]::GetExtension($_) -eq '.zip') { $true }
      else { throw "`nThe Path parameter should be an accessible file path to the zip archive (.zip) containing the Adobe Acrobat installation files. Download link: https://helpx.adobe.com/acrobat/kb/acrobat-dc-downloads.html" }
    })]
  [Alias('Cache')]
  [System.IO.FileInfo]$Path
)

$Archive = "$env:temp\AdobeAcrobat.zip"
$Installer = "$env:temp\Adobe Acrobat\Setup.exe"
$DownloadURL = 'https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_WWMUI.zip'

# Adjust download url based on OS architecture
if ([Environment]::Is64BitOperatingSystem) { 
  $DownloadURL = $DownloadURL.Replace('WWMUI.zip', 'x64_WWMUI.zip')
}

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
  # Retrieve Setup Files
  if ($Path) { Copy-Item -Path $Path -Destination $Archive }
  else { Invoke-WebRequest -Uri $DownloadURL -OutFile $Archive }
  
  # Extract Installer
  Expand-Archive -Path $Archive -DestinationPath $env:temp -Force

  # Install Acrobat     
  Start-Process -Wait -FilePath $Installer -ArgumentList '/sAll /rs /msi EULA_ACCEPT=YES'
}
catch { 
  Write-Warning 'There was an issue installing Adobe Acrobat.'
  Write-Warning $_
}
finally { Remove-Item $Archive, "$env:temp\Adobe Acrobat\" -Recurse -Force -ErrorAction Ignore }
