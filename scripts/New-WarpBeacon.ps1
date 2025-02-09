<#
    .SYNOPSIS
        Deploy Beacon for Cloudflare Warp Managed Network
    .DESCRIPTION
        Creates an IIS site that functions as a beacon for WARP Managed Networks
    .NOTES
        Author: Aaron J Stevenson
#>

# Define variables
$Domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
if ('WORKGROUP' -eq $Domain -or '' -eq $Domain) { $Domain = 'local' }
$SiteDomain = "warp.$Domain"
$SiteDir = "$env:SystemDrive\Cloudflare\ZTNA-Beacon"
$SiteIndex = Join-Path -Path $SiteDir -ChildPath 'index.html'
$SiteName = 'Cloudflare - ZTNA Beacon'
$Port = '9277'
$Years = 10

# Check - IIS Role
if ((Get-WindowsFeature Web-Server).InstallState -ne 'Installed') {
    Write-Warning 'IIS not installed. Aborting...'
    exit 1
}

# Check Listening / Established Ports
$ActivePorts = (Get-NetTCPConnection -State Listen, Established).LocalPort
if ($ActivePorts -contains $Port) {
    Write-Warning "Port $Port already in use. Aborting..."
    exit 1
}

# Create directory for IIS site
if (!(Test-Path $SiteIndex)) { New-Item -Path $SiteIndex -Force }

# Check for / generate certificate
New-SelfSignedCertificate -DnsName $SiteDomain -FriendlyName $SiteName `
    -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm 'SHA256' `
    -CertStoreLocation 'cert:\LocalMachine\My' `
    -NotAfter (Get-Date).AddYears($Years)
$Thumbprint = (Get-ChildItem 'cert:\LocalMachine\My' | Where-Object { $_.Subject -like "CN=$SiteDomain" }).Thumbprint

# Deploy IIS site
New-IISSite -Name $SiteName -PhysicalPath $SiteDir -BindingInformation "*`:$Port`:$SiteDomain" -Protocol https -CertificateThumbprint $Thumbprint -SslFlag 0

# Create Firewall Rule
New-NetFirewallRule -DisplayName 'WARP Beacon (TCP-In)' -Group 'Cloudflare WARP' -Direction 'Inbound' -Protocol 'TCP' -LocalPort $Port -Action 'Allow' -Profile 'Domain,Private' | Out-Null

# Output thumbprint
Write-Host "Host: $SiteDomain`:$Port"
Write-Host "SHA-256 Hash: $Thumbprint"
