Function Invoke-PWSH {
    <#
  .SYNOPSIS
    Relaunches the current script in PowerShell 7+ (pwsh)
  .DESCRIPTION
    This function will relaunch the current script with the parameters that were supplied at runtime in a pwsh session.
  #>
  if (!($PSVersionTable.PSVersion.Major -ge 7)) {
    try { pwsh -File "`"$PSCommandPath`"" @PSBoundParameters }
    catch {
      Write-Warning "`nAn error occurred launching PWSH."
      Write-Warning $_
    }
    finally { exit $LASTEXITCODE }
  }
  else { $PSStyle.OutputRendering = 'PlainText' }
}
