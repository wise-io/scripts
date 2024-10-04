function Get-EdgeExtName {
  <#
  .SYNOPSIS
    Gets the name of an Edge extension using the extension ID
  .EXAMPLE
    Get-EdgeExtName -ExtID 'hokifickgkhplphjiodbggjmoafhignh'
  #>
  param(
    [ValidatePattern('^[a-z]{32}$')]
    [Parameter(Mandatory = $true)]
    [String]$ExtID
  )
  
  $ProgressPreference = 'SilentlyContinue'
  
  # Fetch extension webpage
  $URL = "https://microsoftedge.microsoft.com/addons/detail/$ExtID"
  try { $Data = Invoke-WebRequest -Uri $URL -UseBasicParsing } catch { }
  
  # Find title and format
  [Regex]$Regex = '(?<=<title>)([\S\s]*?)(?=<\/title>)'
  $ExtName = $Regex.Match($Data.Content).Value -replace ' - Microsoft Edge Addons', ''
  if (($ExtName -eq '') -or ($ExtName -eq 'Microsoft Edge Addons')) { $ExtName = 'Unknown Extension' }
  else {
    Add-Type -AssemblyName System.Web
    $ExtName = [System.Web.HttpUtility]::HtmlDecode($ExtName)
  }
  
  return $ExtName
}
