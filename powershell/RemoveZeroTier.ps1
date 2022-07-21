# Removes ZeroTier One
$Paths = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
$ZeroTierOne = Get-ChildItem -Path $Paths | Get-ItemProperty | Where-Object { $_.DisplayName -like 'ZeroTier One' } | Select-Object
$VirtualNetworkPort = Get-ChildItem -Path $Paths | Get-ItemProperty | Where-Object { $_.DisplayName -like 'ZeroTier One Virtual Network Port' } | Select-Object

if ($ZeroTierOne) {
  Write-Output 'Uninstalling ZeroTier One...'
  foreach ($Ver in $ZeroTierOne) {
    $Uninst = $Ver.UninstallString
    cmd /c $Uninst /qn
  }
}

if ($VirtualNetworkPort) {
  Write-Output 'Uninstalling ZeroTier Virtual Network Port...'
  foreach ($Ver in $VirtualNetworkPort) {
    $Uninst = $Ver.UninstallString
    cmd /c $Uninst /qn
  }
}

Write-Output 'Uninstall complete. Restart recommended before reinstall.'
