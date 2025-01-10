function Invoke-SystemTask {
  <#
    .SYNOPSIS
      Creates and runs a scheduled task as SYSTEM.
    .DESCRIPTION
      This function allows running a bundled PowerShell script as a scheduled task under the SYSTEM user.
    .PARAMETER Name
      The name of the created scheduled task.
    .PARAMETER Description
      The description of the created scheduled task.
    .PARAMETER ScriptBlock
      The PowerShell script to run as the scheduled task.
    .PARAMETER Limit
      The execution timeout (limit) of the scheduled task.
    .EXAMPLE
      Invoke-SystemTask -Name 'Repair System Files' -Description 'Run sfc /scannow.' -ScriptBlock {sfc /scannow} -Limit '03:00:00'
  #>

  param(
    [Parameter(Mandatory = $true)][String]$Name,
    [Parameter(Mandatory = $true)][String]$Description,
    [Parameter(Mandatory = $true)][String]$ScriptBlock,
    [Parameter(Mandatory = $true)][String]$Limit
  )

  $TaskServicePrincipal = New-ScheduledTaskPrincipal -UserId 'S-1-5-18' -RunLevel Highest -LogonType ServiceAccount
  $TaskPath = '\Microsoft\Windows\PowerShell\ScheduledJobs\'
  $TaskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -StartWhenAvailable -ExecutionTimeLimit $Limit

  # Encode command
  $Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptBlock)
  $EncodedCommand = [Convert]::ToBase64String($Bytes)
  $TaskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -NonInteractive -EncodedCommand $EncodedCommand"

  # Remove duplicate tasks
  $DuplicateTask = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
  if ($DuplicateTask) { $DuplicateTask | Unregister-ScheduledTask -Confirm:$false }
  
  # Create scheduled task
  Register-ScheduledTask -TaskName $Name -TaskPath $TaskPath -Description $Description -Principal $TaskServicePrincipal -Action $TaskAction -Settings $TaskSettings -AsJob | Out-Null

  # Start scheduled task
  Get-ScheduledTask -TaskName $Name | Start-ScheduledTask
  Write-Output "`nScheduled task [$Name] started successfully with the following command:`n$ScriptBlock"
}
