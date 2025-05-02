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
  $Installer = Join-Path -Path $env:TEMP -ChildPath 'md4ws.msi'

  # Check if package needed
  $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem
  if (($OSInfo.BuildNumber -eq 9600) -or ($OSInfo.BuildNumber -eq 14393)) { } else { return }
  
  # Install prerequisite package
  $Installed = Get-InstallStatus -DisplayName 'Microsoft Defender for Endpoint'
  if (!($Installed)) {
    $ProgressPreference = 'SilentlyContinue'
    if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
      
    Write-Output 'Prerequisite package not detected.'
    Write-Output 'Downloading...'
    Invoke-WebRequest -Uri $InstallPackageURL -OutFile $Installer

    Write-Output 'Installing...'
    Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i $Installer /quiet"
    Remove-Item $Installer -Force -ErrorAction Ignore | Out-Null

    if (Get-InstallStatus -DisplayName 'Microsoft Defender for Endpoint') { Write-Output 'Prerequisite package successfully installed.' }
    else { 
      Write-Warning 'Unable to detect prerequisite package after installation'
      exit 1
    }
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
    Write-Output 'Windows Defender ATP Service detected'
    Write-Output "Service Status: $($Service.Status)"
}
else {
    # Check for existing scheduled task
    $TaskExists = Get-ScheduledTask -TaskName $SchTaskName -ErrorAction Ignore
    if ($TaskExists -and $TaskExists.State -eq 'Running') { Write-Output 'Deployment task exists and is currently running.' }
    elseif ($TaskExists) { 
        # Write-Output 'Deployment task exists but is not currently running'
        $DeploymentNeeded = $True 
    }
    else {
        Write-Output 'Windows Defender ATP Service not detected and deployment task does not exist'
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
    if ($TaskResult -eq '0') { Write-Output 'Deployment task completed successfully.' }
    else { Write-Output 'Task result indicates an error with deployment.' }
}
