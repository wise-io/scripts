# Downloads Splashtop SOS & creates desktop shortcut
$Executable = "$env:SystemDrive\Utilities\SplashtopSOS.exe"
$DownloadURL = 'https://download.splashtop.com/sos/SplashtopSOS.exe'
    
try {
  # Create Directory
  if (!(Test-Path (Split-Path $Executable))) { New-Item -ItemType Directory -Force -Path (Split-Path $Executable) }

  # Download Splashtop SOS 
  Write-Output 'Downloading Splashtop SOS...'
  Invoke-WebRequest -Uri $DownloadURL -OutFile $Executable

  # Create Public Desktop Shortcut
  Write-Output 'Creating desktop shortcut...'
  $ShortcutFile = "$env:Public\Desktop\Splashtop SOS.lnk"
  $WScriptShell = New-Object -ComObject WScript.Shell
  $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
  $Shortcut.TargetPath = $Executable
  $Shortcut.Save()
}
catch { throw $Error }
