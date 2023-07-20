<#
  .SYNOPSIS
    Installs WMF 5.1 and necessary prerequisites.
  .DESCRIPTION
    Installs Windows Management framework and its necessary prerequisites to enable PowerShell 5.1 for easier device management.
    Supported OS: Windows Server 2012 R2, Windows Server 2012, Windows Server 2008 R2, Windows 8.1, Windows 7 SP1
  .NOTES
    Author: Aaron Stevenson
    Date: 7/20/23
#>
#Requires -Version 4.0

Function Install-dotNET {
  $dotNetReg = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'
  $dotNetVersion = if (Test-Path $dotNetReg) { (Get-ItemProperty -Path $dotNetReg).Version } else { '' }
  $dotNetInstaller = "$env:TEMP\dotNET48.exe"
  $dotNetUrl = 'https://download.visualstudio.microsoft.com/download/pr/2d6bb6b2-226a-4baa-bdec-798822606ff1/8494001c276a4b96804cde7829c04d7f/ndp48-x86-x64-allos-enu.exe'
  try {
    if ($dotNetVersion -lt '4.5.2') {
      Write-Output "`nUpdating .Net Framework to 4.8..."
      Invoke-WebRequest -Uri $dotNetUrl -OutFile $dotNetInstaller
      Start-Process -FilePath $dotNetInstaller -ArgumentList '/q /norestart' -Wait
      Write-Output 'Prerequisite installation complete.'
    }
  }
  catch {
    Write-Warning 'Unable to install required prerequisite.'
    Write-Warning $_
    exit 1
  }
  finally { Remove-Item -Path $dotNetInstaller -Force -ErrorAction SilentlyContinue }
}
Function Install-WMF {
  $OSName = (Get-WmiObject -Class Win32_OperatingSystem).Caption
  $OSArch = (Get-WmiObject -Class Win32_OperatingSystem).OsArchitecture
  $WUCatalogBaseUrl = 'https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/updt/2017/03/'
  $MicrosoftBaseUrl = 'https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/'

  # Check OS version to determine correct KB
  # https://www.microsoft.com/en-us/download/details.aspx?id=54616
  Switch -wildcard ($OSName) {
    '*Windows Server 2012*' {
      $KB = 'KB3191565'
      $KBUrl = $WUCatalogBaseUrl + 'windows8-rt-kb3191565-x64_b346e79d308af9105de0f5842d462d4f9dbc7f5a.msu'
    }
    '*Windows Server 2012 R2*' {
      $KB = 'KB3191564'
      $KBUrl = $WUCatalogBaseUrl + 'windowsblue-kb3191564-x64_91d95a0ca035587d4c1babe491f51e06a1529843.msu'
    }
    '*Windows Server 2008 R2*' {
      $KB = 'KB3191566'
      $Archive = "$env:TEMP\$KB.zip"
      $KBUrl = $MicrosoftBaseUrl + 'Win7AndW2K8R2-KB3191566-x64.zip'
    }
    '*Windows 8.1*' {
      $KB = 'KB3191564'
      if ($OSArch -eq '64-bit') { $KBUrl = $WUCatalogBaseUrl + 'windowsblue-kb3191564-x64_91d95a0ca035587d4c1babe491f51e06a1529843.msu' }
      else { $KBUrl = $WUCatalogBaseUrl + 'windowsblue-kb3191564-x86_821ec3c54602311f44caa4831859eac6f1dd0350.msu' }
    }
    '*Windows 7*' {
      $KB = 'KB3191566'
      $Archive = "$env:TEMP\$KB.zip"
      if ($OSArch -eq '64-bit') { $KBUrl = $MicrosoftBaseUrl + 'Win7AndW2K8R2-KB3191566-x64.zip' }
      else { $KBUrl = $MicrosoftBaseUrl + 'Win7-KB3191566-x86.zip' }
    }
    default {
      Write-Warning "`nOperating System [$OSName] not supported. Aborting..."
      exit 1
    }
  }

  try {
    Write-Output "`nOS: $OSName"
    Write-Output "Required Patch: $KB"
    Write-Output "`nStarting update installation..."

    # Download MSU
    if ($Archive) {
      Invoke-WebRequest -Uri $KBUrl -OutFile $Archive
      $UnpackedArchive = "$env:TEMP\WMF-Update"
      Add-Type -AssemblyName System.IO.Compression.FileSystem
      [System.IO.Compression.ZipFile]::ExtractToDirectory($Archive, $UnpackedArchive)
      $MSU = (Get-ChildItem -Path $UnpackedArchive | Where-Object { $_.Name -like '*.msu' }).FullName
    }
    else { 
      $MSU = "$env:TEMP\$KB.msu"
      Invoke-WebRequest -Uri $KBUrl -OutFile $MSU
    }
  
    # Install MSU
    Start-Process -FilePath 'wusa.exe' -ArgumentList "$MSU /quiet /norestart" -Wait
    Write-Output "$KB installation complete."
    Write-Output "A reboot is required but must be done manually.`n"
  }
  catch {
    Write-Warning "`nFailed to install WMF 5.1."
    Write-Warning $_
    exit 1
  }
  finally { 
    if ($Archive) { Remove-Item $Archive, $UnpackedArchive -Recurse -Force -ErrorAction SilentlyContinue }
    else { Remove-Item $MSU -Force -ErrorAction SilentlyContinue }
  }
}

# Check if PowerShell version is less than 5.1
if ($PSVersionTable.PSVersion -gt '5.1') {
  Write-Output "`nWindows Management Framework 5.1 already installed.`nAborting script..."
  exit 0
}

# Set PowerShell to TLS 1.2 (https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/)
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Install .NET Framework & WMF
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
Install-dotNET
Install-WMF
