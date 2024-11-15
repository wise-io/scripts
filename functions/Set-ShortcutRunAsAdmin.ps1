function Set-ShortcutRunAsAdmin {
  param(
      [Parameter(Mandatory = $true)]
      [String]$Path
  )

  if (Test-Path $Path) {
      $Bytes = [System.IO.File]::ReadAllBytes($Path)
      $Bytes[0x15] = $Bytes[0x15] -bor 0x20
      [System.IO.File]::WriteAllBytes($Path, $Bytes)
  }
  else { Write-Warning "Path not found: [$Path]" }
}
