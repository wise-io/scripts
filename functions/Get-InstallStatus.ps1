function Get-InstallStatus {
  param(
    [Parameter(Mandatory = $true)]
    [String]$Name
  )

  $RegPaths = (
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )

  # Wait for registry to update
  Start-Sleep -Seconds 5

  $Program = Get-ChildItem -Path $RegPaths | Get-ItemProperty | Where-Object { $_.DisplayName -match $Name } | Select-Object
  if ($Program) { Write-Output "`nInstalled $Name [$($Program.DisplayVersion)]" }
  else { Write-Warning "`n$Name not detected." }
}
