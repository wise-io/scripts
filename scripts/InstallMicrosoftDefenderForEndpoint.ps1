<#
    .SYNOPSIS
        Runs a scheduled task to deploy MDE via the provided onboarding package
    .DESCRIPTION
        This script is for onboarding machines to the Microsoft Defender for Endpoint services, including security and compliance products.
        Once completed, the machine should light up in the portal within 5-30 minutes, depending on this machine's Internet connectivity availability and machine power state (plugged in vs. battery powered).
    .PARAMETER OnboardingPackage
        Retrieved from https://security.microsoft.com > Settings > Endpoints > Onboarding > [Set OS] > Download Onboarding Package
    .NOTES
        Author: Aaron J Stevenson
#>

param(
    [Parameter(Position = 0, Mandatory = $True)]
    [String]$OnboardingPackage
)

function Get-InstallStatus {
    param(
        [Parameter(Mandatory)]
        [String]$DisplayName
    )

    $RegPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    Start-Sleep -Seconds 5
    
    $Installed = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
    if ($Installed) { return $true }
    else { return $false }
}

function Install-Prerequisites {
    # Set download URL for installation package (needed for WS12R2 / WS2016)
    $InstallPackageURL = 'https://definitionupdates.microsoft.com/packages/content/md4ws.msi?packageType=ProductInstallerMsi&packageVersion=4.18.25020.1009&arch=x64'

    # Get OS Information
    $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Host "OS Name: $($OSInfo.Caption)"
    Write-Host "Version: $($OSInfo.Version)"
    Write-Host "Build:   $($OSInfo.BuildNumber)"

    # Set variables
    if (($OSInfo.BuildNumber -eq 9600) -or ($OSInfo.BuildNumber -eq 14393)) { $PackageNeeded = $true }
    $Installed = Get-InstallStatus -DisplayName 'Microsoft Defender for Endpoint'

    # Install prerequisite package
    if ($PackageNeeded -and !($Installed)) {
        $ProgressPreference = 'SilentlyContinue'
        if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
        
        Write-Host 'Prerequisite package not detected.'
        Write-Host 'Downloading package from:'
        Write-Host $InstallPackageURL

        $Installer = Join-Path -Path $env:TEMP -ChildPath 'md4ws.msi'
        Invoke-WebRequest -Uri $InstallPackageURL -OutFile $Installer

        Write-Host 'Installing package...'
        Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i $Installer /quiet"
    }

    # Confirm installation
    $Installed = Get-InstallStatus -DisplayName 'Microsoft Defender for Endpoint'
    if ($Installed) { Write-Host 'Prerequisite package installed.' }
    else {
        Write-Warning 'Prerequisite package not detected after execution.'
        Write-Host 'Install pending Windows Updates for Defender and try again.'
        exit 1
    }
}

function Set-OnboardingScript {
    # Test onboarding package path
    $PathExists = Test-Path $OnboardingPackage -PathType Leaf -Filter '*.zip'
    if (!$PathExists) { 
        Write-Warning "Invalid path provided to onboarding package: $OnboardingPackage"
        exit 1
    }

    # Copy and extract onboarding package
    $LocalPackage = Join-Path -Path $env:TEMP -ChildPath 'OnboardingPackage.zip'
    $OnboardingPackageFolder = Join-Path -Path $env:TEMP -ChildPath 'OnboardingPackage'
    Copy-Item -Path $OnboardingPackage -Destination $LocalPackage
    Expand-Archive -Path $LocalPackage -DestinationPath $OnboardingPackageFolder -Force

    # Return onboarding script path
    return ($OnboardingPackageFolder | Get-ChildItem -Filter '*.cmd').FullName
}

$SchTaskName = 'Deploy - Microsoft Defender for Endpoint'

# Test if deployment is needed
$Service = Get-Service -Name 'Sense' -ErrorAction Ignore | Where-Object { $_.DisplayName -eq 'Windows Defender Advanced Threat Protection Service' }
if ($Service) { 
    Write-Host 'Windows Defender ATP Service detected'
    Write-Host "Service Status: $($Service.Status)"
}
else {
    # Check for existing scheduled task
    $TaskExists = Get-ScheduledTask -TaskName $SchTaskName -ErrorAction Ignore
    if ($TaskExists -and $TaskExists.State -eq 'Running') { Write-Host 'Deployment task exists and is currently running.' }
    elseif ($TaskExists) { 
        # Write-Host 'Deployment task exists but is not currently running'
        $DeploymentNeeded = $True 
    }
    else {
        Write-Host 'Windows Defender ATP Service not detected and deployment task does not exist'
        $DeploymentNeeded = $True
    }
}

# Deploy and run scheduled task
if ($DeploymentNeeded) {
    # Get prerequisites
    Install-Prerequisites

    # Set onboarding script
    $OnboardingScript = Set-OnboardingScript

    # Define scheduled task configuration
    $Task = [PSCustomObject]@{
        Name        = $SchTaskName
        Description = 'Installs MDE by running the onboarding package script as a scheduled task.'
        Principal   = New-ScheduledTaskPrincipal -UserId 'S-1-5-18' -RunLevel Highest -LogonType ServiceAccount
        Action      = New-ScheduledTaskAction -Execute $OnboardingScript
        Settings    = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    }

    # Create scheduled task object
    $SchTask = New-ScheduledTask -Action $Task.Action -Description $Task.Description -Principal $Task.Principal -Settings $Task.Settings

    # Unregister duplicate task
    Get-ScheduledTask -TaskName $Task.Name -ErrorAction Ignore | Unregister-ScheduledTask -Confirm:$false
        
    # Register scheduled task
    $SchTask | Register-ScheduledTask -TaskName $Task.Name

    # Set scheduled task creation date
    $RegTask = Get-ScheduledTask -TaskName $Task.Name
    $RegTask.Date = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    $RegTask | Set-ScheduledTask

    # Start scheduled task
    $RegTask | Start-ScheduledTask

    # Wait for scheduled task to finish
    while ((Get-ScheduledTask -TaskName $Task.Name).State -eq 'Running') { Start-Sleep -Seconds 5 }

    # Get scheduled task result
    $TaskResult = (Get-ScheduledTaskInfo -TaskName $Task.Name).LastTaskResult
    if ($TaskResult -eq '0') { Write-Host 'Deployment task completed successfully.' }
    else { Write-Host 'Task result indicates an error with deployment.' }
}
