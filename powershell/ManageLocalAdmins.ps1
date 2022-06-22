param(
  [string[]]$Admins = @()
)

$Admins += @(
  # Enter your admin users here as follows:
  # "$env:computername\AdminUser1",
  # 'DOMAIN\AdminUser2',
  # 'AzureAD\AdminUser3'
)

# Get current administrator group members
$AdminGroup = Get-LocalGroupMember -Group 'Administrators'

# Add admin users
ForEach ($User in $Admins) {
  if ($AdminGroup.Name -notcontains $User) {
    Write-Output "Adding $User to Local Administrators group..."
    Add-LocalGroupMember -Group 'Administrators' -Member $User
  }
}

# Remove non-admin users
ForEach ($Member in $AdminGroup) { 
  if ($Admins -notcontains $Member) { 
    Write-Output "Removing $Member from Administrators group..." 
    Remove-LocalGroupMember -Group 'Administrators' -Member $Member
  }
}

# Display current administrators group members
Write-Output "`nCurrent Administrators Group Members:"
Get-LocalGroupMember -Group 'Administrators'
