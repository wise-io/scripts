<#
    .SYNOPSIS
        Runs a scheduled task to deploy MDE via the provided onboarding package script
    .DESCRIPTION
        This script is for onboarding machines to the Microsoft Defender for Endpoint services, including security and compliance products.
        Once completed, the machine should light up in the portal within 5-30 minutes, depending on this machine's Internet connectivity availability and machine power state (plugged in vs. battery powered).
    .PARAMETER OnboardingScript
        Retrieved from https://security.microsoft.com > Settings > Endpoints > Onboarding > [Set OS] > Download Onboarding Package
        Script will need to be extracted and placed at the path provided
    .NOTES
        Author: Aaron J Stevenson
#>

param(
    [Parameter(Position = 0, Mandatory = $True)]
    [String]$OnboardingScript
)

# Define scheduled task configuration
$Task = [PSCustomObject]@{
    Name        = 'Deploy - Microsoft Defender for Endpoint'
    Description = 'Installs MDE by running the onboarding package script as a scheduled task.'
    Principal   = New-ScheduledTaskPrincipal -UserId 'S-1-5-18' -RunLevel Highest -LogonType ServiceAccount
    Action      = New-ScheduledTaskAction -Execute $OnboardingScript
    Settings    = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
}

# Test if deployment is needed
$Service = Get-Service -Name 'Sense' | Where-Object { $_.DisplayName -eq 'Windows Defender Advanced Threat Protection Service' }
if ($Service) { 
    Write-Host 'Windows Defender ATP Service detected'
    Write-Host "Service Status: $($Service.Status)"
}
else {
    # Check for existing scheduled task
    $TaskExists = Get-ScheduledTask -TaskName $Task.Name -ErrorAction Ignore
    if ($TaskExists -and $TaskExists.State -eq 'Running') { Write-Host 'Deployment task exists and is currently running.' }
    elseif ($TaskExists) { 
        Write-Host 'Deployment task exists but is not currently running'
        $DeploymentNeeded = $True 
    }
    else {
        Write-Host 'Windows Defender ATP Service not detected and deployment task does not exist'
        $DeploymentNeeded = $True
    }
}

# Deploy and run scheduled task
if ($DeploymentNeeded) {
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

    # Cleanup
    Start-Sleep -Seconds 5
    Get-ScheduledTask -TaskName $Task.Name | Unregister-ScheduledTask
}
