function Get-ChromeExtName {
  <#
  .SYNOPSIS
    Gets the name of a Chrome extension using the extension ID
  .EXAMPLE
    Get-ChromeExtName -ID 'ghbmnnjooekpmoecnnnilnnbdlolhkhi'
  #>
  param(
    [ValidatePattern('^[a-z]{32}$')]
    [Parameter(Mandatory = $true)]
    [String]$ID
  )
  
  $ProgressPreference = 'SilentlyContinue'

  # Fetch extension webpage
  $URL = "https://chromewebstore.google.com/detail/$ID"
  try { $Data = Invoke-WebRequest -Uri $URL } catch { }

  # Find title and format
  [Regex]$Regex = '(?<=og:title" content=")([\S\s]*?)(?=">)'
  $ExtName = $Regex.Match($Data.Content).Value -replace ' - Chrome Web Store', ''
  if (($ExtName -eq '') -or ($ExtName -eq 'Chrome Web Store')) { $ExtName = 'Unknown Extension' }

  return $ExtName
}
