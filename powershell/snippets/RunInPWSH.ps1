# Check for required PowerShell version (7+)
if (!($PSVersionTable.PSVersion.Major -ge 7)) {
  try {
    
    # Install PowerShell 7 if missing
    if (!(Test-Path "$env:SystemDrive\Program Files\PowerShell\7")) {
      Write-Output 'Installing PowerShell version 7...'
      Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
    
    # Restart script in PowerShell 7
    pwsh -File "`"$PSCommandPath`"" @PSBoundParameters
    
  }
  catch {
    Write-Output 'PowerShell 7 was not installed. Update PowerShell and try again.'
    throw $Error
  }
  finally { exit $LASTEXITCODE }
}