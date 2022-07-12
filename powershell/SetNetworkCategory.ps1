# Sets current network category (type) to Public or Private.

param (
  [Parameter (Mandatory = $true)]
  [ValidateSet('Public', 'Private', IgnoreCase)]
  [string]$Category # Desired Network Category
)

# Format parameter
$Category = (Get-Culture).TextInfo.ToTitleCase($Category)

# Get Current Network Profile
$CurrentNetwork = Get-NetConnectionProfile

# Set Network Category
try {
  if ($CurrentNetwork.NetworkCategory -ne $Category) {
    Set-NetConnectionProfile -Name $CurrentNetwork.Name -NetworkCategory $Category
    Write-Output "Network category set to $Category."
  }
  else {
    Write-Output "Network category was already set to $Category."
  }
}
catch {
  throw
}
