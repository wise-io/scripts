<#
  .SYNOPSIS
    Install OBS Studio & Plugins
  .DESCRIPTION
    Silently installs the latest OBS Studio and Advanced Scene Switcher OBS plugin from GitHub.
  .EXAMPLE
    ./InstallOBS.ps1
  .NOTES
    Author: Aaron Stevenson
#>

function Get-DownloadURL {
  param(
    [Parameter(Mandatory = $true)][String]$Repo,
    [Parameter(Mandatory = $true)][String]$Extension
  )
  
  $RepoURL = "https://api.github.com/repos/$Repo/releases/latest"
  $DownloadURL = (Invoke-RestMethod -Uri $RepoURL -UseBasicParsing).assets.browser_download_url | Where-Object { $_.EndsWith("$Extension") }
  return $DownloadURL
}

function Install-OBS {
  # Install latest OBS Studio from GitHub
  try {
    $ProgramURL = Get-DownloadURL -Repo 'obsproject/obs-studio' -Extension '.exe'
    $ProgramInstaller = "$env:TEMP\obs-studio-installer.exe"

    Write-Output "`nDownloading OBS Studio..."
    Write-Output $ProgramURL
    Invoke-WebRequest -Uri $ProgramURL -OutFile $ProgramInstaller

    Write-Output 'Installing...'
    Start-Process -Wait -FilePath $ProgramInstaller -ArgumentList '/S'
  }
  catch {
    Write-Warning 'Unable to install OBS Studio.'
    Write-Warning $_
  }
  finally { Remove-Item -Path $ProgramInstaller -Force -ErrorAction SilentlyContinue }
}

function Install-Plugin {
  # Install latest Advanced Scene Switcher plugin from GitHub
  try {
    $PluginURL = Get-DownloadURL -Repo 'WarmUpTill/SceneSwitcher' -Extension '.exe'
    $PluginInstaller = "$env:TEMP\advanced-scene-switcher-installer.exe"

    Write-Output "`nDownloading Advanced Scene Switcher plugin for OBS Studio..."
    Write-Output $PluginURL
    Invoke-WebRequest -Uri $PluginURL -OutFile $PluginInstaller

    Write-Output 'Installing...'
    Start-Process -Wait -FilePath $PluginInstaller -ArgumentList '/verysilent /norestart'

    # Remove Start Menu Folder
    $StartMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\advanced-scene-switcher"
    Remove-Item -Path $StartMenuFolder -Recurse -Force -ErrorAction SilentlyContinue
  }
  catch {
    Write-Warning 'Unable to install Advanced Scene Switcher plugin for OBS Studio.'
    Write-Warning $_
  }
  finally { Remove-Item -Path $PluginInstaller -Force -ErrorAction SilentlyContinue }
}

# Adjust PowerShell Settings
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Install-OBS
Install-Plugin
