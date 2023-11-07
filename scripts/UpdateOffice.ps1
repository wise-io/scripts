<#
  .SYNOPSIS
    Initiates Microsoft Office update scan
  .DESCRIPTION
    Initiates a scan for Microsoft Office updates using the ClickToRun client.
  .NOTES
    Author: Aaron J. Stevenson
#>

function Get-C2RPath {
  $C2Rx86 = "${env:ProgramFiles(x86)}\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
  $C2Rx64 = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
  
  if (Test-Path $C2Rx86) { return $C2Rx86 }
  elseif (Test-Path $C2Rx64) { return $C2Rx64 }
  else {
    Write-Output "`nNo ClickToRun installations of Microsoft Office detected."
    exit 0
  }
}

$Path = Get-C2RPath
Write-Output "`nStarting Microsoft Office update process..."
Start-Process -FilePath $Path -ArgumentList '/update user displaylevel=false' -Wait
