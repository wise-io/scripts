# Sends a test page to the designated printer
function Out-TestPage {
  param([String]$Printer)
  $PrinterObject = Get-WmiObject Win32_Printer | Where-Object { $_.Name -eq $Printer }
  if ($PrinterObject.PrintTestPage().ReturnValue -eq 0) { Write-Output "Test page sent to: [$Printer]" }
}
