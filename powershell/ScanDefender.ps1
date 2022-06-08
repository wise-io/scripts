# Runs a Windows Defender Scan
param(
  [ValidateSet('Full', 'Quick', 'Offline', IgnoreCase)]  
  [string]$Type = 'Quick', # Scan type (defaults to quick scan)
  [System.IO.FileInfo]$Path # Optional local path to scan
)

# Format type parameter
$Type = (Get-Culture).TextInfo.ToTitleCase($Type)

# Update definitions
Update-MpSignature

# Run scan
if ($Path) {
  Start-MpScan -ScanType 'Custom' -ScanPath $Path
}
elseif ($Type -eq 'Offline') { 
  Start-MpWDOScan 
  exit
}
else {
  Start-MpScan -ScanType $Type
}

# Remove active threats
Remove-MpThreat
