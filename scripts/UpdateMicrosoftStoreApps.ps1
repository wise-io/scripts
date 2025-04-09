<#
  .SYNOPSIS
    Triggers a Microsoft Store update scan.
  .PARAMETER AutoUpdate
    Enables automatic Microsoft Store updates.
  .EXAMPLE
    UpdateMicrosoftStoreApps.ps1 -AutoUpdate
#>

param ([switch]$AutoUpdate)

if ($AutoUpdate) {
  try {
    $RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore'
    if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    New-ItemProperty -Path $RegPath -Name 'AutoDownload' -Value 4 -PropertyType DWORD -Force | Out-Null
    Write-Output "`nAutomatic Microsoft Store updates enabled."
  }
  catch { Write-Warning 'Automatic updates were not enabled.' }
}

try {
  $AppUpdateResult = Get-CimInstance -Namespace 'Root\cimv2\mdm\dmmap' -ClassName 'MDM_EnterpriseModernAppManagement_AppManagement01' | Invoke-CimMethod -MethodName UpdateScanMethod
  if ($AppUpdateResult.ReturnValue -ne 0) { $AppUpdateResult }
  else { Write-Output 'Starting Microsoft Store update scan...' }
}
catch { 
  Write-Warning 'Unable to start Microsoft Store update scan.'
  Write-Warning $_
  exit 1
}
