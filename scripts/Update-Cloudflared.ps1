<#
    .SYNOPSIS
        Updates Cloudflared Agent to latest version
    .DESCRIPTION
        Uninstalls an existing cloudflared agent, then installs the latest agent version.
        An alternative option to 'cloudflared update', which doesn't update the DisplayVersion in the Registry.
    .LINK
        https://github.com/cloudflare/cloudflared
    .NOTES
        Author: Aaron J Stevenson
#>

Function Get-InstalledApp {
    param([Parameter(Mandatory)][String]$DisplayName)

    $RegPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    
    return Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
}

Function Get-LatestGitHubRelease {
    param(
        [Parameter(Mandatory)][String]$Repo,
        [Parameter(Mandatory)][String]$FileType
    )
    
    # Format FileType
    if ($FileType -notmatch '^\.') { $FileType = ".$FileType" }

    # Get architecture
    switch ($env:PROCESSOR_ARCHITECTURE) {
        'AMD64' { $Architecture = 'amd64' }
        'x86' { $Architecture = '386' }
    }

    # Set filename ending
    $FilenameEnding = $Architecture + $FileType

    # Get release information
    $ReleaseInfo = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
    $Release = [PSCustomObject]@{
        Version     = $ReleaseInfo.Name
        DownloadURL = $ReleaseInfo.assets.browser_download_url | Where-Object { $_ -match "${FilenameEnding}$" }
        Checksum    = ($ReleaseInfo.body -split "`n" | Where-Object { $_ -match "${FilenameEnding}:\s+([a-f0-9]+)$" }) -replace ".*${FilenameEnding}:\s+", ''
    }
    
    return $Release
}

# Adjust PowerShell Settings
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Check for existing Cloudflared Agent
$Installed = Get-InstalledApp -DisplayName 'cloudflared'
if (!($Installed)) {
    Write-Warning 'Cloudflared agent not detected. Aborting...'
    exit 1
}

# Get latest version information
$Latest = Get-LatestGitHubRelease -Repo 'cloudflare/cloudflared' -FileType '.msi'
if ($Installed.DisplayVersion -eq $Latest.Version) { 
    Write-Host "Cloudflared agent version [$($Installed.DisplayVersion)] matches latest version [$($Latest.Version)]"        
}
else { 
    Write-Host "`nCloudflared agent version [$($Installed.DisplayVersion)] does not match latest version [$($Latest.Version)]"

    # Download latest version
    Write-Host "`nDownloading latest version..."
    $Installer = Join-Path -Path $env:TEMP -ChildPath (Split-Path -Leaf $Latest.DownloadURL)
    Invoke-WebRequest -Uri $Latest.DownloadURL -OutFile $Installer

    # Verify Checksum
    $InstallerChecksum = (Get-FileHash -Path $Installer -Algorithm SHA256).Hash
    if ($Latest.Checksum -ne $InstallerChecksum) {
        Write-Host 'Checksum Verification Failed'
        Write-Host "GitHub Checksum          : $($Latest.Checksum)"
        Write-Host "Downloaded File Checksum : $InstallerChecksum"
        exit 1
    }

    # Uninstall existing version
    Write-Host "Uninstalling Cloudflared [$($Installed.DisplayVersion)]..."
    Get-Service -Name 'Cloudflared' | Stop-Service
    Start-Process -Wait -FilePath msiexec.exe -ArgumentList ($Installed.UninstallString).replace('MsiExec.exe /I', '/quiet /x ')

    # Install latest version
    Write-Host "Installing Cloudflared [$($Latest.Version)]..."
    Start-Process -Wait -FilePath $Installer -ArgumentList '/quiet'
    Start-Sleep -Seconds '10'
    Get-Service -Name 'Cloudflared' | Start-Service

    # Confirm successful update
    $NewInstall = Get-InstalledApp -DisplayName 'cloudflared'
    if ($NewInstall.DisplayVersion -eq $Latest.Version) {
        Write-Host "Installed Cloudflared agent [$($Latest.Version)] over [$($Installed.DisplayVersion)]" 
    }
}
