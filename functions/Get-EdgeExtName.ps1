function Get-EdgeExtName {
  <#
  .SYNOPSIS
    Gets the name of an Edge extension using the extension ID
  .EXAMPLE
    Get-EdgeExtName -ID 'hokifickgkhplphjiodbggjmoafhignh'
  #>
  param(
    [ValidatePattern('^[a-z]{32}$')]
    [Parameter(Mandatory = $true)]
    [String]$ID
  )
  
  $ProgressPreference = 'SilentlyContinue'

  # Fetch extension webpage
  $URL = "https://microsoftedge.microsoft.com/addons/detail/$ID"
  try { $Data = Invoke-WebRequest -Uri $URL -Method Head } catch { }

  # Find title and format
  $ExtName = $Data.ParsedHtml.Title -replace ' - Microsoft Edge Addons', ''
  if (($ExtName -eq '') -or ($ExtName -eq 'Microsoft Edge Addons')) { $ExtName = 'Unknown Extension' }

  return $ExtName
}
