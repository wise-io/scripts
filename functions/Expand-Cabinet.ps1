function Expand-Cabinet {
  param(
    [Parameter(Mandatory)][String]$Path,
    [String]$DestinationPath
  )

  $ErrorActionPreference = 'Stop'

  # Validate Path
  if (!(Test-Path -Path $Path -PathType Leaf)) { Write-Error "The file at '$Path' does not exist." }
  else { $Path = (Resolve-Path $Path).Path }

  # Set / create destination path
  if (!$DestinationPath) { $DestinationPath = (Split-Path -Parent (Resolve-Path $Path).Path) }
  elseif (!(Test-Path -Path $DestinationPath -PathType Container)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
  }

  # Extract cab file
  $Expand = "$env:SystemRoot\System32\expand.exe"
  & $Expand -r "$Path" -f:* "$DestinationPath" | Out-Null

  # Catch errors
  if ($LASTEXITCODE -ne 0) { Write-Error "Failed to extract $Path to $DestinationPath" }
}
