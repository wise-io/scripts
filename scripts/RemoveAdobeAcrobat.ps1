<#
  .SYNOPSIS
    Removes Adobe Acrobat / Adobe Acrobat Reader
  .DESCRIPTION
    Uninstalls all detected versions of Adobe Acrobat and Adobe Acrobat Reader.
  .NOTES
    Author: Aaron J. Stevenson
#>

$AppNames = @(
  'Adobe Acrobat',
  'Adobe Reader'
)

function Get-Apps {
  $Paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )

  return Get-ChildItem -Path $Paths | Get-ItemProperty | Where-Object { $_.DisplayName -match ($AppNames -join '|') }
}
 
function Remove-Apps {
  try {
    foreach ($App in $Apps) {
      if ($App.UninstallString) {
        $DisplayName = $App.DisplayName
        $Uninst = $App.UninstallString -replace 'MsiExec.exe /I', ''
        Write-Output "Uninstalling $DisplayName..."
        Start-Process -Wait msiexec -ArgumentList "/x $Uninst /qn"
        Write-Output 'Application removed.'
      }
    }
  }
  catch {
    Write-Warning 'Unable to remove application.'
    Write-Warning $_
  }
}

$ErrorActionPreference = 'Stop'

$Apps = Get-Apps
if ($Apps) { Remove-Apps }
else { Write-Output 'No matching applications were detected.' }
