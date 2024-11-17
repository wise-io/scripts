<#
  .SYNOPSIS
    Installs YAPI Workstation
  .DESCRIPTION
    Installs the latest version of YAPI Workstation from Yapi Inc. and adjusts firewall / launch settings
  .LINK
    https://help.yapicentral.com/hc/en-us/articles/115011978827-Installing-YAPI-on-a-New-Computer-Workstation
  .NOTES
    Author: Aaron J. Stevenson
#>

$DownloadURL = 'https://customer-onboarding-resources.s3.us-west-1.amazonaws.com/dashboardinstallers/yapi_dashboard_setup.exe'

function Get-Version {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )
  
    $RegPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
  
    # Wait for registry to update
    Start-Sleep -Seconds 5
  
    $Program = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like $Name } | Select-Object
    if ($Program) { return $Program.DisplayVersion }
    else { return $null }
}

function Set-ShortcutRunAsAdmin {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    if (Test-Path $Path) {
        $Bytes = [System.IO.File]::ReadAllBytes($Path)
        $Bytes[0x15] = $Bytes[0x15] -bor 0x20
        [System.IO.File]::WriteAllBytes($Path, $Bytes)
    }
    else { Write-Warning "Path not found: [$Path]" }
}

function Install-YAPI {
    $InstallFiles = Join-Path -Path $env:temp -ChildPath 'YAPI'
    $InstallPackage = Join-Path -Path $InstallFiles -ChildPath 'yapi_dashboard_setup.exe'
    $Installer = Join-Path -Path $InstallFiles -ChildPath 'setup.exe'
    
    # Create temp directory for install files
    New-Item -Path $InstallFiles -ItemType 'directory' -Force | Out-Null
    
    # Download installer
    Write-Output "`nDownloading YAPI workstation installer..."
    Invoke-WebRequest -Uri $DownloadURL -OutFile $InstallPackage
    
    # Install .Net 3.5
    $Feature = Get-WindowsCapability -Online -Name 'NetFx3'
    if ($Feature.State -eq 'NotPresent') {
        Write-Output 'Installing prerequisite .Net 3.5 Framework...'
        Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' | Out-Null
    }

    # Run installer
    Write-Output 'Installing YAPI...'
    Start-Process -Wait -FilePath $InstallPackage -ArgumentList "/Q /T:$InstallFiles /C"
    Start-Process -Wait -FilePath $Installer -ArgumentList '/Q'
    
    # Cleanup install files
    Remove-Item -Path $InstallFiles -Force -ErrorAction SilentlyContinue
    
    # Check for completed installation
    $Version = Get-Version -Name 'YAPI'
    if ($Version) { Write-Output "Installed YAPI [$Version]" }
    else { 
        Write-Warning 'YAPI not detected after installation. Aborting...'
        exit 1
    }

    Write-Output "`nRunning post-installation configuration steps..."
    $Program = 'C:\ProgramData\YAPI\YAPIRuntime.exe'
    
    # Add Firewall exclusions after removing duplicates
    Get-NetFirewallApplicationFilter -Program $Program -ErrorAction Ignore | Remove-NetFirewallRule | Out-Null
    New-NetFirewallRule -DisplayName 'YAPI Runtime (TCP-In)' -Group 'YAPI' -Direction 'Inbound' -Program $Program -Protocol 'TCP' -Action 'Allow' -Profile 'Domain,Private' | Out-Null
    New-NetFirewallRule -DisplayName 'YAPI Runtime (UDP-In)' -Group 'YAPI' -Direction 'Inbound' -Program $Program -Protocol 'UDP' -Action 'Allow' -Profile 'Domain,Private' | Out-Null

    # Modify application shortcut to run as administrator
    Set-ShortcutRunAsAdmin -Path 'C:\Users\Public\Desktop\YAPI.lnk'
    Write-Output 'Script complete.'
}

# Set PowerShell preferences
Set-Location -Path $env:SystemRoot
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Install-YAPI
