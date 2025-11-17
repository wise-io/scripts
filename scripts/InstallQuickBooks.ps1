<#
  .SYNOPSIS
    Installs QuickBooks Desktop
  .DESCRIPTION
    Installs the specified version of QuickBooks Desktop
  .EXAMPLE
    InstallQuickBooks.ps1 -Cache "\\SERVER\QuickBooks\Installers" -ProductNumbers 757-611,334-562 -ToolHub
  .PARAMETER Cache
    Optional - Directory path to QuickBooks installers. If not provided, installers will be downloaded from Intuit.
  .PARAMETER LicenseNumber
    Optional - License number to use for QuickBooks installations. If not provided, '0000-0000-0000-000' will be used.
  .PARAMETER ProductNumbers
    Required - Array parameter that accepts product numbers for the versions of QuickBooks you want to install.
  .PARAMETER ToolHub
    Optional - Switch parameter to install QuickBooks ToolHub.
  .NOTES
    Author: Aaron J. Stevenson
#>

param(
  [String]$Cache,
 
  [ValidatePattern('^(?:\d{4}-){3}\d{3}$|^\d{15}$')]
  [Alias('License')]
  [String]$LicenseNumber = '0000-0000-0000-000',

  [Parameter(Mandatory = $true)]
  [Alias('ID', 'Product', 'Products', 'ProductNumber')]
  [String[]]$ProductNumbers,

  [Switch]$ToolHub
)

Function Confirm-SystemCheck {
  $CurrentUserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
  if ($CurrentUserSID -eq 'S-1-5-18') {
    Write-Warning 'This script cannot run as SYSTEM. Please run as admin.'
    exit 1
  }
}

Function Install-XPSDocumentWriter {
  $XPSFeature = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq 'Printing-XPSServices-Features' }
  if ($XPSFeature.State -eq 'Disabled') {
    try {
      Write-Output "`nInstalling required PDF components (Microsoft XPS Document Writer)..."
      Enable-WindowsOptionalFeature -Online -FeatureName 'Printing-XPSServices-Features' -All -NoRestart | Out-Null
      Write-Output 'Installation complete.'
    }
    catch {
      Write-Warning 'Unable to install Microsoft XPS Document Writer feature.'
      Write-Warning '$_'
    }
  }
}

Function Install-QuickBooks {
  param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [PSObject]$QuickBooks
  )

  $Exe = ($QuickBooks.URL -Split '/')[-1]
  $Installer = Join-Path -Path $env:TEMP -ChildPath $Exe
  if (Test-Path ("$Cache\$Exe")) { $CacheInstaller = Join-Path -Path $Cache -ChildPath $Exe }

  try {
    if ($CacheInstaller) { 
      Write-Output "`nCopying $($QuickBooks.Name) installer from cache..."
      Copy-Item -Path $CacheInstaller -Destination $Installer
    }
    else { 
      Write-Output "`nDownloading $($QuickBooks.Name) installer..."
      Invoke-WebRequest -Uri $QuickBooks.URL -OutFile $Installer
    }
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList "-s -a QBMIGRATOR=1 MSICOMMAND=/s QB_PRODUCTNUM=$($QuickBooks.ProductNumber) QB_LICENSENUM=$LicenseNumber"
    Write-Output 'Installation complete.'
  }
  catch { 
    Write-Warning "Error installing $($QuickBooks.Name):"
    Write-Warning $_
  }
  finally { Remove-Item $Installer -Force -ErrorAction Ignore }
}

Function Install-ToolHub {
  $ToolHubURL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/QBFDT/QuickBooksToolHub.exe'
  $Exe = ($ToolHubURL -Split '/')[-1]
  $Installer = Join-Path -Path $env:TEMP -ChildPath $Exe
  if (Test-Path ("$Cache\$Exe")) { $CacheInstaller = Join-Path -Path $Cache -ChildPath $Exe }

  try {
    if ($CacheInstaller) {
      Write-Output "`nCopying ToolHub installer from cache..."
      Copy-Item -Path $CacheInstaller -Destination $Installer
    }
    else {
      Write-Output "`nDownloading ToolHub installer..."
      Invoke-WebRequest -Uri $ToolHubURL -OutFile $Installer
    }
    Write-Output 'Installing...'
    Start-Process -Wait -NoNewWindow -FilePath $Installer -ArgumentList '/S /v/qn'
    Write-Output 'Installation complete.'
  }
  catch {
    Write-Warning 'Error installing ToolHub:'
    Write-Warning $_
  }
  finally { Remove-Item $Installer -Force -ErrorAction Ignore }

}

# Abort if running as SYSTEM
Confirm-SystemCheck

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Format parameters
if ($Cache) { $Cache = $Cache.TrimEnd('\') }
$ProductNumbers = ($ProductNumbers -replace '-', '' -replace ' ', '').Split(',')

$QBVersions = @(
  
  # Add additional versions
  # Get download url from https://downloads.quickbooks.com/app/qbdt/products
  # [PSCustomObject]@{Name = 'QuickBooks [Flavor] [Year]'; ProductNumber = '[Product Number]'; URL = '[Download URL]'; }

  # QuickBooks Pro
  [PSCustomObject]@{Name = 'QuickBooks Pro 2023'; ProductNumber = '401228'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2023/Latest/QuickBooksProSub2023.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Pro 2022'; ProductNumber = '917681'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2022/Latest/QuickBooksProSub2022.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Pro 2021'; ProductNumber = '222750'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2021/Latest/QuickBooksPro2021.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Pro 2020'; ProductNumber = '748990'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2020/Latest/QuickBooksPro2020.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Pro 2019'; ProductNumber = '102058'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2019/Latest/QuickBooksPro2019.exe'; }

  # QuickBooks Pro Accountant
  [PSCustomObject]@{Name = 'QuickBooks Pro 2019 - Accountant'; ProductNumber = '589041'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2019/Latest/QuickBooksPro2019.exe'; }

  # QuickBooks Premier Accountant
  [PSCustomObject]@{Name = 'QuickBooks Premier 2024'; ProductNumber = '626040'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2024/LatestAcc/QuickBooksPremier2024.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Premier 2023'; ProductNumber = '757611'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2023/Latest/QuickBooksPremierSub2023.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Premier 2022'; ProductNumber = '747060'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2022/Latest/QuickBooksPremier2022.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Premier 2021'; ProductNumber = '622091'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2021/Latest/QuickBooksPremier2021.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Premier 2020'; ProductNumber = '247211'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2020/Latest/QuickBooksPremier2020.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Premier 2019'; ProductNumber = '355957'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2019/Latest/QuickBooksPremier2019.exe'; }
  
  # QuickBooks Enterprise
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 24'; ProductNumber = '045169'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2024/Latest/QuickBooksEnterprise24.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 23'; ProductNumber = '916783'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2023/Latest/QuickBooksEnterprise23.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 22'; ProductNumber = '029966'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2022/Latest/QuickBooksEnterprise22.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 21'; ProductNumber = '176962'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2021/Latest/QuickBooksEnterprise21.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 20'; ProductNumber = '194238'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2020/Latest/QuickBooksEnterprise20.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 19'; ProductNumber = '490580'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2019/Latest/QuickBooksEnterprise19.exe'; }
  
  # QuickBooks Enterprise Accountant
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 23 - Accountant'; ProductNumber = '334562'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2023/Latest/QuickBooksEnterprise23.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 22 - Accountant'; ProductNumber = '884649'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2022/Latest/QuickBooksEnterprise22.exe'; }
  #[PSCustomObject]@{Name = 'QuickBooks Enterprise 21 - Accountant'; ProductNumber = ''; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2021/Latest/QuickBooksEnterprise21.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 20 - Accountant'; ProductNumber = '239629'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2020/Latest/QuickBooksEnterprise20.exe'; }
  [PSCustomObject]@{Name = 'QuickBooks Enterprise 19 - Accountant'; ProductNumber = '454852'; URL = 'https://dlm2.download.intuit.com/akdlm/SBD/QuickBooks/2019/Latest/QuickBooksEnterprise19.exe'; }
)

# Install necessary PDF components
Install-XPSDocumentWriter

# Find Product Number & Install
foreach ($ProductNumber in $ProductNumbers) {
  $QBVersion = $QBVersions | Where-Object { $_.ProductNumber -match $ProductNumber }
  if (!$QBVersion) { Write-Warning "Product number [$ProductNumber] is not currently supported by this script." }
  else { $QBVersion | Install-QuickBooks }
}

# Install ToolHub
if ($ToolHub) { Install-ToolHub }
