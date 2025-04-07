<#
  .SYNOPSIS
    Initiates Microsoft Office update scan
  .DESCRIPTION
    Initiates a scan for Microsoft Office updates using the ClickToRun client.
  .NOTES
    Author: Aaron J. Stevenson
#>

# Get path to ClickToRun executable
$Path = Resolve-Path "$env:SystemDrive\*\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe" -ErrorAction Ignore

if ($Path) {
  Write-Host "`nStarting Microsoft Office update process..."
  Start-Process -FilePath $Path -ArgumentList '/update user displaylevel=false' -Wait
}
else {
  Write-Host "`nNo ClickToRun installations of Microsoft Office detected."
}
