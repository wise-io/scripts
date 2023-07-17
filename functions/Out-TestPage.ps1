function Out-TestPage {
  <#
  .SYNOPSIS
    Sends a test page to the designated printer.
  .EXAMPLE
    Out-TestPage -Printer 'Reception Printer'
  #>
  param(
    [Parameter(Position = 0, Mandatory = $true)]
    [String]$Printer
  )

  try {
    $PrinterObject = Get-WmiObject Win32_Printer | Where-Object { $_.Name -eq $Printer }
    if ($PrinterObject.PrintTestPage().ReturnValue -eq 0) { Write-Output "Test page sent to: [$Printer]" }
    else { throw }
  }
  catch {
    Write-Warning "Unable to send test page to: [$Printer]"
    Write-Warning $_
  }
}
