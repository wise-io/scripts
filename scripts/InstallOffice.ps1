<#
  .SYNOPSIS
    Installs Microsoft Office 365
  .DESCRIPTION
    Installs Microsoft Office 365 using a default configuration xml, unless a custom xml is provided.
    WARNING: This script will remove all existing office installations if used with the default configuration xml.
  .PARAMETER Config
    Parameter Set: Custom
    URL or file path to custom configuration xml for office installations.
  .PARAMETER x86
    Parameter Set: Builtin
    Switch parameter to install 32-bit Office applications with the built-in XML.
  .LINK
    XML Configuration Generator: https://config.office.com/
    Supported Product IDs: https://learn.microsoft.com/en-us/microsoft-365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run
  .NOTES
    Author: Aaron J. Stevenson
#>

[CmdletBinding(DefaultParameterSetName = 'None')]
param (
  [Parameter(ParameterSetName = 'Custom')]
  [Alias('Configure')][String]$Config,

  [Parameter(ParameterSetName = 'Builtin')]
  [Alias('32', '32bit')][Switch]$x86
)

function Test-ValidUrl {
  param([String]$Url)

  try {
    $Uri = [System.Uri]::New($Url)
    return $Uri.Scheme -in @('http', 'https')
  }
  catch {
    return $false
  }
}

function Get-ODT {
  [String]$MSWebPage = Invoke-RestMethod 'https://www.microsoft.com/en-us/download/details.aspx?id=49117'
  $Script:ODTURL = $MSWebPage | ForEach-Object {
    if ($_ -match '.*href="(https://download.microsoft.com.*officedeploymenttool.*\.exe)"') { $Matches[1] }
  }

  try {
    Write-Output "`nDownloading Office Deployment Tool (ODT)..."
    Invoke-WebRequest -Uri $Script:ODTURL -OutFile $Script:Installer
    Start-Process -Wait -NoNewWindow -FilePath $Script:Installer -ArgumentList "/extract:$Script:ODT /quiet"
  }
  catch {
    Remove-Item $Script:ODT, $Script:Installer -Recurse -Force -ErrorAction Ignore
    Write-Warning 'There was an error downloading the Office Deployment Tool.'
    Write-Warning $_
    exit 1
  }
}

function Set-ConfigXML {
  # Create path to config file
  $Path = Split-Path -Path $Script:ConfigFile -Parent
  if (!(Test-Path -Path $Path -PathType Container)) {
    New-Item -Path $Path -ItemType Directory | Out-Null
  }

  # Determine type of config provided
  switch ($Config) {
    { ($_) -and (Test-Path -Path $_ -PathType Leaf -Include '*.xml') } { $ConfigPath = $true }
    { ($_) -and (Test-ValidUrl -Url $_) } { $ConfigUrl = $true }
    default { $DefaultConfig = $true }
  }

  # If path provided, copy file to temp directory
  if ($ConfigPath) {
    Write-Output 'Configuration file path provided - copying file to temp directory for installation...'
    try { Copy-Item -Path $Config -Destination $Script:ConfigFile }
    catch {
      Write-Warning 'Unable to copy configuration file'
      Write-Warning $_
      exit 1
    }
  }

  # If url provided, download file to temp directory
  if ($ConfigUrl) {
    Write-Output 'Configuration url provided - downloading file to temp directory for installation...'
    try { Invoke-WebRequest -Uri $Config -OutFile $Script:ConfigFile }
    catch {
      Write-Warning 'Unable to download configuration file'
      Write-Warning $_
      exit 1
    }
  }

  # If no configuration provided, create default configuration file in temp directory
  if ($DefaultConfig) {
    Write-Output 'No configuration file provided - creating default configuration file for installation...'
    try {
      $XML = [XML]@'
  <Configuration ID="0fb449fc-f210-4428-9c7d-be5882ab97aa">
    <Remove All="TRUE"/>
    <Add OfficeClientEdition="64" Channel="MonthlyEnterprise" MigrateArch="TRUE">
      <Product ID="O365BusinessRetail">
        <Language ID="MatchOS" />
        <ExcludeApp ID="Groove" />
        <ExcludeApp ID="Lync" />
        <ExcludeApp ID="Bing" />
      </Product>
    </Add>
    <Property Name="SharedComputerLicensing" Value="0" />
    <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
    <Property Name="DeviceBasedLicensing" Value="0" />
    <Property Name="SCLCacheOverride" Value="0" />
    <Updates Enabled="TRUE" />
    <RemoveMSI />
    <AppSettings>
      <User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
      <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
      <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
    </AppSettings>
    <Display Level="Full" AcceptEULA="TRUE" />
  </Configuration>
'@

      if ($x86 -or !([Environment]::Is64BitOperatingSystem)) {
        $OfficeClientEdition = $XML.SelectSingleNode('//Add[@OfficeClientEdition]')
        $OfficeClientEdition.SetAttribute('OfficeClientEdition', '32')
      }
    
      $XML.Save("$Script:ConfigFile")
    }
    catch { 
      Write-Warning 'Unable to create default configuration file'
      Write-Warning $_
      exit 1
    }
  }
}

function Install-Office {
  Write-Output 'Installing Microsoft Office...'
  try { 
    Start-Process -Wait -WindowStyle Hidden -FilePath "$Script:ODT\setup.exe" -ArgumentList "/configure $Script:ConfigFile"
    Write-Output 'Installation complete.'
  }
  catch {
    Write-Warning 'Error during Office installation:'
    Write-Warning $_
  }
  finally { Remove-Item $Script:ODT, $Script:Installer -Recurse -Force -ErrorAction Ignore }
}

function Remove-OfficeHub {
  $AppName = 'Microsoft.MicrosoftOfficeHub'
  try {
    $Package = Get-AppxPackage -AllUsers | Where-Object { ($AppName -contains $_.Name) }
    $ProvisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object { ($AppName -contains $_.DisplayName) }
    if ($Package -or $ProvisionedPackage) {
      Write-Output "`nRemoving [$AppName] (Microsoft Store App)..."
      $ProvisionedPackage | Remove-AppxProvisionedPackage -AllUsers | Out-Null
      $Package | Remove-AppxPackage -AllUsers
    }
  }
  catch { 
    Write-Warning "Error during [$AppName] removal:"
    Write-Warning $_
  }
}

$Script:ODT = "$env:temp\ODT"
$Script:ConfigFile = "$Script:ODT\office-config.xml"
$Script:Installer = "$env:temp\ODTSetup.exe"

# Adjust PowerShell settings
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Get-ODT 
Set-ConfigXML
Install-Office
Remove-OfficeHub
