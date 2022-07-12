
$Modules = @()
Write-Output "`nChecking for necessary PowerShell modules..."
try {
  # Use TLS 1.2 (https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
  foreach($Module in $Modules){
    if (!(Get-Module -ListAvailable -Name $Module -ErrorAction Ignore)) {
      Write-Output "Installing $Module module..."
      Install-Module -Name $Module -Force
      Import-Module $Module
    }
  }

  Write-Output 'Modules installed.'
}
catch { 
  throw $Error
  exit
}
