function Get-ChromeExtName {
  <#
  .SYNOPSIS
    Gets the name of a Chrome extension using the extension ID
  .EXAMPLE
    Get-ChromeExtName -ExtID 'ghbmnnjooekpmoecnnnilnnbdlolhkhi'
  #>
  param(
    [ValidatePattern('^[a-z]{32}$')]
    [Parameter(Mandatory = $true)]
    [String]$ExtID
  )
  
  $ProgressPreference = 'SilentlyContinue'

  # Fetch extension webpage
  $URL = "https://chromewebstore.google.com/detail/$ExtID"
  try { $Data = Invoke-WebRequest -Uri $URL -UseBasicParsing } catch { }

  # Find title and format
  [Regex]$Regex = '(?<=og:title" content=")([\S\s]*?)(?=">)'
  $ExtName = $Regex.Match($Data.Content).Value -replace ' - Chrome Web Store', ''
  if (($ExtName -eq '') -or ($ExtName -eq 'Chrome Web Store')) { $ExtName = 'Unknown Extension' }
  else {
    Add-Type -AssemblyName System.Web
    $ExtName = [System.Web.HttpUtility]::HtmlDecode($ExtName)
  }

  return $ExtName
}
