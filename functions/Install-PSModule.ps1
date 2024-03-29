function Install-PSModule {
  <#
  .SYNOPSIS
    Installs and imports the provided PowerShell Modules
  .EXAMPLE
    Install-PSModule -Modules @('ExchangeOnlineManagement')
  #>
  
  param(
    [Parameter(Position = 0, Mandatory = $true)]
    [String[]]$Modules
  )

  Write-Output "`nChecking for necessary PowerShell modules..."
  try {
    # Adjust PowerShell settings
    $ProgressPreference = 'SilentlyContinue'
    if ([Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls12' -and [Net.ServicePointManager]::SecurityProtocol -notcontains 'Tls13') {
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    # Install NuGet package provider
    if (!(Get-PackageProvider -ListAvailable -Name 'NuGet' -ErrorAction Ignore)) {
      Write-Output 'Installing NuGet package provider...'
      Install-PackageProvider -Name 'NuGet' -MinimumVersion 2.8.5.201 -Force
    }

    # Set PSGallery to trusted repository
    Register-PSRepository -Default -InstallationPolicy 'Trusted' -ErrorAction Ignore
    if (!(Get-PSRepository -Name 'PSGallery' -ErrorAction Ignore).InstallationPolicy -eq 'Trusted') {
      Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'
    }
  
    # Install & import modules
    ForEach ($Module in $Modules) {
      if (!(Get-Module -ListAvailable -Name $Module -ErrorAction Ignore)) {
        Write-Output "`nInstalling $Module module..."
        Install-Module -Name $Module -Force
        Import-Module $Module
      }
    }

    Write-Output 'Necessary modules installed.'
  }
  catch { 
    Write-Warning 'Unable to install modules.'
    Write-Warning $_
    exit 1
  }
}
