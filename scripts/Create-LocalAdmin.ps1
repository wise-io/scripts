<#
  .SYNOPSIS
    Create a local admin account.
  .DESCRIPTION
    Creates a local admin account with a password file or user entered password.
  .PARAMETER User
    Required parameter - Username for the new local admin account.
  .PARAMETER Path
    Optional parameter - Path to .txt file containing the password for the new account in plaintext.
  .NOTES
    Author: Aaron J. Stevenson
#>

param(
  [Parameter(Mandatory = $true)]
  [Alias('Username')]
  [String]$User,
    
  [ValidateScript({
      if (-Not ($_ | Test-Path) ) { throw 'File does not exist' }
      if (-Not ($_ | Test-Path -PathType Leaf) ) { throw 'The path argument must be a file. Folder paths are not allowed.' }
      if ($_ -notmatch '\.txt$') { throw 'The file specified in the path argument must be type txt' }
      return $true
    })]
  [Alias('PathToPasswordFile')]
  [System.IO.FileInfo]$Path
)
try {
  if ($Path) { $Pass = ConvertTo-SecureString -String (Get-Content $Path) -AsPlainText -Force }
  else { $Pass = Read-Host 'Enter a password' -AsSecureString }

  # Get current administrator group members
  $AdminGroup = Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue

  # Check if user already exists
  $UserExists = (Get-LocalUser).Name -Contains $User
  if ($UserExists) {
    Write-Output "$user account exists. Resetting password and setting group membership..."
    Set-LocalUser -Name $user -Password $Pass
    if ($AdminGroup.Name -NotContains $User) {
      Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $User -ErrorAction SilentlyContinue
    }
  }
  else {
    Write-Output "Creating $user account and setting password..."
    New-LocalUser -Name $User -Password $Pass 
    Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $User
  }
}
catch {
  Write-Warning 'Unable to complete script.'
  Write-Warning $_
}   
finally {
  if ($Path) { 
    Write-Output 'Removing password file.'
    Remove-Item $Path -Force -ErrorAction Ignore 
  }
}
